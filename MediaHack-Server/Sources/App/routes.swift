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
}
