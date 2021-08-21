import Vapor

private var subtitlesCache: [String: String] = [:]
private let mx = DispatchSemaphore(value: 1)

enum ServerError: Error {
    case noSubtitlesForId
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
        defer {
            mx.signal()
        }
        if case .timedOut = mxResult {
            throw ServerError.couldntLoadSubtitles
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
                    struct Entries: Decodable {
                        struct Sense: Decodable {
                            struct Trancslation: Decodable {
                                var text: String
                            }
                            var translations: [Trancslation]
                        }
                        var senses: [Sense]
                    }
                    var entries: [Entries]
                }
                var lexicalEntries: [LexicalEntries]
            }
            var results: [Result]
        }

        guard maxTransReq > 0,
            let word: String = req.query["word"] else {
            throw Abort(.badRequest)
        }
        maxTransReq -= 1
        return req.client.get("https://od-api.oxforddictionaries.com/api/v2/translations/en/ru/\(word)", headers: .init([("app_id", "ed4dc9b2"), ("app_key", "4a868ed2184b8072a76fc30db09d79d6")])).flatMapThrowing { res in
            try res.content.decode(TranslationResp.self)
        }.map({ resp in
            guard let data = try? JSONEncoder().encode(resp.results.first?.lexicalEntries.first?.entries.first?.senses.first?.translations.map(\.text) ?? []), let resp = String(data: data, encoding: .utf8) else { return "" }
            return resp
        })
    }
}
