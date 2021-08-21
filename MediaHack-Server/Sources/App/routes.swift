import Vapor

private var subtitlesCache: [String: String] = [:]
private let mx = DispatchSemaphore(value: 1)

enum ServerError: Error {
    case noSubtitlesForId
    case couldntLoadSubtitles
}

func routes(_ app: Application) throws {
    let webSocketManager = WebSocketManager(eventLoop: app.eventLoopGroup.next())

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

        let mxResult = mx.wait(timeout: DispatchTime.now() + .milliseconds(150))
        if case .timedOut = mxResult {
            mx.signal()
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
        mx.signal()
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

//    app.get("translate") { req -> EventLoopFuture<String> in
//        guard let word: String = req.query["word"] else {
//            throw Abort(.badRequest)
//        }
//        var comp = URLComponents()
//        comp.host = "translate.yandex.net/api/v1.5/tr.json/translate"
//        comp.queryItems = [
//            .init(name: "key", value: "trnsl.1.1.20170318T084928Z.175a69db0153769f.b364b30c9ef444d8891c42c86eb035766f7e2ef7"),
//            .init(name: "text", value: word),
//            .init(name: "lang", value: "en-ru")
//        ]
//        guard let url = comp.url?.absoluteString else {
//            throw Abort(.badRequest)
//        }
//        URI(scheme: .https, host: "translate.yandex.net", port: nil, path: "/api/v1.5/tr.json/translate", query: "key=", fragment: <#T##String?#>)
//        return req.client.post(URI(scheme: "https", path: url)).map({ res in
//            return ""
//        })
//    }
}
