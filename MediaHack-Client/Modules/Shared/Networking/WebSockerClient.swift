//
//  WebSockerClient.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 21.08.2021.
//

import Foundation
import UIKit

public class WSManager {
    public enum ClientType: String {
        case tv
        case phone
    }

    public static let shared = WSManager() // создаем Синглтон
    private init() {}

    private var webSocketTask: URLSessionWebSocketTask?
    private var clientType: ClientType = .tv
    public func connectToWebSocket(type: ClientType, id: String?) {
        cancel()

        let deviceId: String = id ?? UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let wsURL = URL(string: "ws://178.154.197.24:8080/webSocket/connect?type=\(type.rawValue)&id=\(deviceId)").unsafelyUnwrapped

        webSocketTask = URLSession.shared.webSocketTask(with: wsURL)
        clientType = type
        webSocketTask?.resume()
        scheduleNextPing()
    }

    public func cancel() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    public func sendStatus(_ status: WSStatus) {
        guard let data = try? JSONEncoder().encode(status), let jsonText = String(data: data, encoding: .utf8) else { return }
        let message = URLSessionWebSocketTask.Message.string(jsonText)
        webSocketTask?.send(message, completionHandler: ({
            if let error = $0 {
                print("Error send status: \(error)")
            }
        }))
    }

    public func receiveData(completion: @escaping (String) -> Void) {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case let .failure(error):
                print("Error in receiving message: \(error)")
            case let .success(message):
                switch message {
                case let .string(text):
                    completion(text)
                case let .data(data):
                    completion(String(data: data, encoding: .utf8) ?? "")
                @unknown default:
                    debugPrint("Unknown message")
                }
            }
            self?.receiveData(completion: completion)
        }
    }

    private func ping() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("Ping failed: \(error)")
            }
            self.scheduleNextPing()
        }
    }

    private func scheduleNextPing() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10, execute: ping)
    }
}

public enum WSStatus: Codable {
    private enum CodingKeys: String, CodingKey {
        case stop
        case start
        case play
    }

    enum PostTypeCodingError: Error {
        case decoding(String)
    }
    
    case stop
    case start
    case play(sec: Double)

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
        if let value = try? values.decode(Double.self, forKey: .play) {
            self = .play(sec: value)
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
        }
    }
}
