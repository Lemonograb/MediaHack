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
    var maxTransReq = 300

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
            struct Translation: Codable {
                let text: String?
            }

            var translations: [Translation]
        }

        struct RequestModel: Encodable {
            let sourceLanguageCode = "en"
            let targetLanguageCode = "ru"
            let texts: [String]
            let folderId = "b1gpfip2u14eblsvi1ff"
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
        let token = String(utf8String: getenv("YA_TR_TOKEN"))
        return req.client.post(
            "https://translate.api.cloud.yandex.net/translate/v2/translate",
            headers: .init([("Authorization", "Api-Key \(token)")])
        ) { req in
            let model = RequestModel(texts: [lower])
            try req.content.encode(model, as: .json)
        }.flatMapThrowing { res in
            try res.content.decode(TranslationResp.self)
        }.map { resp in
            guard let data = try? JSONEncoder().encode(resp.translations.compactMap(\.text)) else {
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
