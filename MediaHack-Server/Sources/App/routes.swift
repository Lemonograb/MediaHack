import Vapor

func routes(_ app: Application) throws {
    let webSocketManager = WebSocketManager(eventLoop: app.eventLoopGroup.next())

    app.get { req in
        return "It works!"
    }

    app.get("cinemaList") { req -> String in
        let data = try JSONEncoder().encode(cinimas)
        return String(data: data, encoding: .utf8) ?? ""
    }

    app.get("subtitle") { req -> String in
        struct CinimaSubtitles: Encodable {
            let ru: [SubtitleParser.Subtitle]
            let en: [SubtitleParser.Subtitle]
        }

        guard let id: String = req.query["id"], let prefix = cinimasSubtitle[id] else { return "" }

        let data = try JSONEncoder().encode(
            CinimaSubtitles(ru: SubtitleParser.getSubtitles(from: "\(prefix)_ru.srt"),
                            en: SubtitleParser.getSubtitles(from: "\(prefix)_en.srt")))

        return String(data: data, encoding: .utf8) ?? ""
    }

    app.webSocket("webSocket", "connect") { req, ws in
        guard let id: String = req.query["id"],
              let typeStr: String = req.query["type"],
              let type = WebSocketManager.ClientType.init(rawValue: typeStr) else {
            return
        }
        webSocketManager.add(client: .init(id: .init(type: type, id: id), socket: ws))
    }

    app.get("webSocket", "list") { req -> String in
        return webSocketManager.connectedClient.values.map(\.id.id).joined(separator: "\n")
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
