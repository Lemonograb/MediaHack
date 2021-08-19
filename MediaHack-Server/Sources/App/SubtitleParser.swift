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

            let numberOfMatches = regex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, self.count))

            if numberOfMatches != 1 {
                return nil
            }

            let dottedString = self.replacingOccurrences(of: ",", with: ".", options: String.CompareOptions.literal, range: nil)

            return strtod(dottedString, nil)
        } catch {
            return 0.0
        }
    }
}

struct Time {
    var timeInSeconds: Double
    init(fromMilliseconds milliseconds: Int) {
        timeInSeconds = Double(milliseconds) / 1000.0
    }
    init?(fromTimeStamp timeStamp: String) {
        timeInSeconds = 0.0

        var components = timeStamp.components(separatedBy: ":")

        if let seconds = components.last?.toDouble() {
            timeInSeconds = seconds

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
        timeInSeconds = seconds
    }
}

class SubtitleParser {
    var subtitles: [Subtitle] = []

    var length:Double {
        get {
            if subtitles.count > 0 {
                return subtitles.last!.end.timeInSeconds
            } else {
                return 0.0
            }
        }
    }

    enum SubtitleType {
        case SubRip, Unknown
    }

    struct Subtitle {
        var start: Time, end: Time
        var text: [String] = []

        var length: Double {
            get {
                return end.timeInSeconds - start.timeInSeconds
            }
        }
    }

    init?(text: String) {
        let type = identifyFromText(text: text)

        if type == .Unknown {
            return nil
        } else if type == .SubRip {
            if !parseSubRip(text: text) {
                return nil
            }
        }
    }

    func subtitle(for second: Double) -> Subtitle? {
        return subtitles.first(where: { $0.start.timeInSeconds <= second && $0.end.timeInSeconds >= second })
    }

    private func parseSubRip(text: String) -> Bool {
        let formatedText = text.replacingOccurrences(of: "\r", with: "")
        let subs = formatedText.components(separatedBy: "\n\n")

        for sub in subs {
            let rows = sub.components(separatedBy: CharacterSet.newlines)

            if rows.count < 3 {
                continue
            }

            if let id = Int(rows[0]) {
                let times = rows[1].components(separatedBy: " --> ")

                if times.count < 2 {
                    continue
                }

                if let startTime = Time(fromTimeStamp: times[0]) {
                    if let endTime = Time(fromTimeStamp: times[1].components(separatedBy: " ")[0]) {

                        let text = Array(rows[2...rows.count-1])
                        let subtitle = Subtitle(start: startTime, end: endTime, text: text)

                        subtitles.append(subtitle)
                    }
                }
            }
        }

        return true
    }

    private func identifyFromText(text: String) -> SubtitleType {
        let scanner = Scanner(string: text)

        if scanner.scanInt(nil) {
            var timeLine:NSString?

            if scanner.scanCharacters(from: CharacterSet(charactersIn: "0123456789:.,-> "), into: &timeLine) {

                if let timeLine = timeLine {
                    if timeLine.components(separatedBy: " --> ").count == 2 {
                        return .SubRip
                    }
                }
            }
        }

        return .Unknown
    }
}
