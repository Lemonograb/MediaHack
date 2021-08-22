import Foundation

public struct Subtitle: Codable {
    public struct Timing: Codable {
        public let timeInSeconds: Double

        public init(timeInSeconds: Double) {
            self.timeInSeconds = timeInSeconds
        }
    }

    public let start: Timing
    public let text: [String]
    public let end: Timing

    public init(start: Timing, text: [String], end: Timing) {
        self.start = start
        self.text = text
        self.end = end
    }
}

public struct MovieSubtitles: Codable {
    let ru: [Subtitle]
    let en: [Subtitle]

    public init(ru: [Subtitle], en: [Subtitle]) {
        self.ru = ru
        self.en = en
    }
}
