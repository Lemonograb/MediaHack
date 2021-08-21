//
//  File.swift
//
//
//  Created by Vitalii Stikhurov on 16.08.2021.
//

import Foundation

extension String {
    func toDouble() -> Double? {
        let pattern = "^[+-]?(?:\\d*[\\.,])?\\d+$"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.dotMatchesLineSeparators)

            let numberOfMatches = regex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, count))

            if numberOfMatches != 1 {
                return nil
            }

            let dottedString = replacingOccurrences(of: ",", with: ".", options: String.CompareOptions.literal, range: nil)

            return strtod(dottedString, nil)
        } catch {
            return 0.0
        }
    }
}

struct Time: Encodable {
    var timeInSeconds: Double
    init(fromMilliseconds milliseconds: Int) {
        self.timeInSeconds = Double(milliseconds) / 1000.0
    }

    init?(fromTimeStamp timeStamp: String) {
        self.timeInSeconds = 0.0

        var components = timeStamp.components(separatedBy: ":")

        if let seconds = components.last?.toDouble() {
            self.timeInSeconds = seconds

            components.removeLast()
            if let last = components.last, let minutes = Int(last) {
                timeInSeconds += Double(minutes) * 60.0

                components.removeLast()
                if let last = components.last, let hours = Int(last) {
                    timeInSeconds += Double(hours) * 3600.0
                }
            }
        } else {
            return nil
        }
    }

    init(_ seconds: Double) {
        self.timeInSeconds = seconds
    }
}

class SubtitleParser {
    var subtitles: [Subtitle] = []

    var length: Double {
        if !subtitles.isEmpty {
            return subtitles.last!.end.timeInSeconds
        } else {
            return 0.0
        }
    }

    enum SubtitleType {
        case SubRip, Unknown
    }

    struct Subtitle: Encodable {
        var start: Time, end: Time
        var text: [String] = []

        var length: Double {
            return end.timeInSeconds - start.timeInSeconds
        }
    }

    init?(text: String) {
        if !parseSubRip(text: text) {
            return nil
        }
    }

    func subtitle(for second: Double) -> Subtitle? {
        return subtitles.first(where: { $0.start.timeInSeconds <= second && $0.end.timeInSeconds >= second })
    }

    private func parseSubRip(text: String) -> Bool {
        let formatedText = text.replacingOccurrences(of: "\r", with: "")
        let subs = formatedText.components(separatedBy: "\n\n")
        var needAddEndTimeToPrev: Bool = false
        for (index, sub) in subs.enumerated() {
            let rows = sub.components(separatedBy: CharacterSet.newlines)

            if rows.count < 3 {
                continue
            }

            if let id = Int(rows[0]) {
                let times = rows[1].components(separatedBy: " --> ")
                guard !times.isEmpty else { continue }

                if let startTime = Time(fromTimeStamp: times[0]) {
                    if needAddEndTimeToPrev {
                        subtitles[index - 1].end = Time(startTime.timeInSeconds - 1)
                    }
                    let text = Array(rows[2 ... rows.count - 1])
                    var subtitle = Subtitle(start: startTime, end: .init(0), text: text)
                    if let endTime = Time(fromTimeStamp: times[1].components(separatedBy: " ")[0]) {
                        needAddEndTimeToPrev = false
                        subtitle.end = endTime
                    } else {
                        needAddEndTimeToPrev = true
                    }
                    subtitles.append(subtitle)
                }
            }
        }

        return true
    }
}

extension SubtitleParser {
    static func getSubtitles(from fileName: String) -> [Subtitle] {
        guard let folder = String(utf8String: getenv("SUBTITLES_FOLDER")) else {
            return []
        }
        let dir = URL(fileURLWithPath: folder)
        guard
            let data = try? Data(contentsOf: dir.appendingPathComponent(fileName)),
            let subtitles = String(data: data, encoding: .utf8),
            let parser = SubtitleParser(text: subtitles)
        else {
            return []
        }
        return parser.subtitles
    }
}
