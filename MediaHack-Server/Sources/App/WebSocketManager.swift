//
//  File.swift
//
//
//  Created by Vitalii Stikhurov on 21.08.2021.
//

import Vapor

class WebSocketManager {
    var eventLoop: EventLoop
    var connectedClient: [Client.Key: Client] = [:]

    enum ClientType: String {
        case tv
        case phone
    }

    struct Client {
        struct Key: Hashable {
            var type: ClientType
            var id: String
        }

        var id: Key
        var socket: WebSocket
    }

    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func add(client: Client) {
        client.socket.onClose.whenComplete { _ in
            self.connectedClient[client.id] = nil
            if client.id.type == .tv {
                let closedKey = Client.Key(type: .phone, id: client.id.id)
                guard let data = try? JSONEncoder().encode(WSStatus.cancel),
                      let str = data.str else { return }
                self.connectedClient[closedKey]?.socket.send(str)
                _ = self.connectedClient[closedKey]?.socket.close().always({ _ in
                    self.connectedClient[closedKey] = nil
                })
            }

        }
        // прокидывает статус на телефон
        client.socket.onText { _, text in
            if
                let data = text.data(using: .utf8),
                (try? JSONDecoder().decode(WSStatus.self, from: data)) != nil
            {
                let key = Client.Key(type: client.id.type == .tv ? .phone : .tv, id: client.id.id)
                self.connectedClient[key]?.socket.send(text)
            }
        }

        connectedClient[client.id] = client
    }

    deinit {
        let futures = self.connectedClient.values.map { $0.socket.close() }
        try! self.eventLoop.flatten(futures).wait()
    }
}

public enum WSStatus: Codable {
    private enum CodingKeys: String, CodingKey {
        case stop
        case start
        case play
        case playAt
        case cancel
    }

    enum PostTypeCodingError: Error {
        case decoding(String)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if (try? values.decode(String.self, forKey: .stop)) != nil {
            self = .stop
            return
        }
        if (try? values.decode(String.self, forKey: .start)) != nil {
            self = .start
            return
        }
        if (try? values.decode(String.self, forKey: .cancel)) != nil {
            self = .cancel
            return
        }
        if let value = try? values.decode(Double.self, forKey: .play) {
            self = .play(sec: value)
            return
        }
        if let value = try? values.decode(Double.self, forKey: .playAt) {
            self = .playAt(sec: value)
            return
        }
        throw PostTypeCodingError.decoding("Error decode! \(dump(values))")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .stop:
            try container.encode("0", forKey: .stop)
        case .start:
            try container.encode("1", forKey: .start)
        case let .play(sec: sec):
            try container.encode(sec, forKey: .play)
        case let .playAt(sec: sec):
            try container.encode(sec, forKey: .playAt)
        case .cancel:
            try container.encode("2", forKey: .cancel)
        }
    }

    case stop
    case start
    case cancel
    case play(sec: Double)
    case playAt(sec: Double)
}

extension Data {
    var str: String? {
        String(data: self, encoding: .utf8)
    }
}
