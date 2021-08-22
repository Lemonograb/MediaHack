import Vapor

private var subtitlesCache: [String: String] = [:]
private var definitionCache: [String: String] = [:]
private let mx = DispatchSemaphore(value: 1)

enum ServerError: Error {
    case noSubtitlesForId
    case couldntLoadSubtitlesnoTranslation
    case couldntLoadSubtitles
}

func routes(_ app: Application) throws {
    let webSocketManager = WebSocketManager(eventLoop: app.eventLoopGroup.next())
    var maxTransReq = 30

    app.get { _ in
        "It works!"
    }

    app.get("cinemaList") { _ -> String in
        let data = try JSONEncoder().encode(cinimas)
        return String(data: data, encoding: .utf8) ?? ""
    }

    app.get("subtitle") { req -> String in
        struct CinimaSubtitles: Encodable {
            let ru: [SubtitleParser.Subtitle]
            let en: [SubtitleParser.Subtitle]
        }

        guard
            let id: String = req.query["id"],
            let prefix = cinimasSubtitle[id]
        else {
            throw ServerError.noSubtitlesForId
        }

        let mxResult = mx.wait(timeout: DispatchTime.now() + .milliseconds(550))
        if case .timedOut = mxResult {
            throw ServerError.couldntLoadSubtitles
        }
        defer {
            mx.signal()
        }

        if let cached = subtitlesCache[prefix] {
            return cached
        }

        let data = try JSONEncoder().encode(
            CinimaSubtitles(
                ru: SubtitleParser.getSubtitles(from: "\(prefix)_ru.srt"),
                en: SubtitleParser.getSubtitles(from: "\(prefix)_en.srt")
            ))

        let result = String(data: data, encoding: .utf8) ?? ""
        subtitlesCache[prefix] = result
        return result
    }

    app.webSocket("webSocket", "connect") { req, ws in
        guard
            let id: String = req.query["id"],
            let typeStr: String = req.query["type"],
            let type = WebSocketManager.ClientType(rawValue: typeStr)
        else {
            return
        }
        webSocketManager.add(client: .init(id: .init(type: type, id: id), socket: ws))
    }

    app.get("webSocket", "list") { _ -> String in
        webSocketManager.connectedClient.values.map(\.id.id).joined(separator: "\n")
    }

    app.get("webSocket", "send") { req -> String in
        guard let message: String = req.query["m"] else {
            return "fail"
        }
        webSocketManager.connectedClient.values.forEach { $0.socket.send(message) }
        return "ok" + webSocketManager.connectedClient.values.map(\.id.id).joined(separator: "\n")
    }

    app.get("translate") { req -> EventLoopFuture<String> in
        struct TranslationResp: Decodable {
            struct Result: Decodable {
                struct LexicalEntries: Decodable {
                    struct Inflection: Decodable {
                        var id: String
                    }

                    struct Entries: Decodable {
                        struct Sense: Decodable {
                            struct Trancslation: Decodable {
                                var text: String
                            }

                            var translations: [Trancslation]?
                        }

                        var senses: [Sense]
                    }

                    var entries: [Entries]?
                    var inflectionOf: [Inflection]?
                }

                var lexicalEntries: [LexicalEntries]
            }

            var results: [Result]
        }

        guard
            maxTransReq > 0,
            let word: String = req.query["word"]
        else {
            throw Abort(.badRequest)
        }
        let lower = word.lowercased()
        let waitResult = mx.wait(timeout: DispatchTime.now() + .milliseconds(250))
        if case .timedOut = waitResult {
            throw Abort(.serviceUnavailable)
        }
        if let cached = definitionCache[lower] {
            mx.signal()
            let promise = req.eventLoop.makeSucceededFuture(cached)
            return promise
        } else {
            mx.signal()
        }
        
        maxTransReq -= 1
        return req.client.get("https://od-api.oxforddictionaries.com/api/v2/lemmas/en/\(lower)", headers: .init([("app_id", "d1735332"), ("app_key", "8a9c930b46824fc858db48ff23d63be6")]))
            .flatMapThrowing { res in
                try res.content.decode(TranslationResp.self)
            }
            .map {
                $0.results.first?.lexicalEntries.first?.inflectionOf?.first?.id ?? ""
            }
            .flatMap { wordId in
                req.client.get("https://od-api.oxforddictionaries.com/api/v2/translations/en/ru/\(wordId)", headers: .init([("app_id", "ed4dc9b2"), ("app_key", "4a868ed2184b8072a76fc30db09d79d6")]))
                    .flatMapThrowing { res in
                        try res.content.decode(TranslationResp.self)
                    }
                    .map { resp in
                        let allEntries: [String] = resp.results
                            .flatMap(\.lexicalEntries)
                            .compactMap(\.entries)
                            .flatMap { $0 }
                            .flatMap(\.senses)
                            .compactMap(\.translations)
                            .flatMap { $0 }
                            .map(\.text)

                        guard let data = try? JSONEncoder().encode(allEntries) else {
                            return ""
                        }
                        let waitResult = mx.wait(timeout: DispatchTime.now() + .milliseconds(250))
                        let response = String(data: data, encoding: .utf8).unsafelyUnwrapped
                        
                        if case .timedOut = waitResult {
                            return response
                        } else {
                            definitionCache[lower] = response
                            mx.signal()
                            return response
                        }
                    }
            }
    }
}
