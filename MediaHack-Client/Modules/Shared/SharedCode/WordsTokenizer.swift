import UIKit

public enum WordsTokenizer {
    @inline(__always)
    public static func process(text: [String]) -> NSAttributedString {
        let punc = [",", ".", ";", "'", "-", "\"", "–", "?", "!"]
        let result = NSMutableAttributedString()
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)

        for (i, line) in text.enumerated() {
            for word in line.split(separator: " ") {
                let s = String(word)
                var toCheck = s.lowercased()
                for x in punc {
                    toCheck = toCheck.replacingOccurrences(of: x, with: "")
                }
                toCheck = toCheck.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if toCheck.isEmpty || WordsChecker.badWords.contains(toCheck) {
                    let part = "\(s)\(String.nbsp)\(String.nbsp)".builder
                        .font(font)
                        .foregroundColor(.white)
                        .result
                    result.append(part)
                } else {
                    let part = "\(s)\(String.nbsp)\(String.nbsp)".builder
                        .font(font)
                        .foregroundColor(#colorLiteral(red: 0.8695564866, green: 0.5418210626, blue: 0, alpha: 1))
                        .result
                    result.append(part)
                }
            }
            if i != text.endIndex - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    @inline(__always)
    public static func process(text: [String], whiteList: Set<String>, whiteListLines: Set<String>) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let punc = [",", ".", ";", "'", "-", "\"", "–", "?", "!"]

        for (i, line) in text.enumerated() {
            for x in whiteListLines {
                if line.contains(x) {
                    for word in line.split(separator: " ") {
                        let s = String(word)
                        var toCheck = s.lowercased()
                        for x in punc {
                            toCheck = toCheck.replacingOccurrences(of: x, with: "")
                        }
                        toCheck = toCheck.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        if toCheck.isEmpty || !whiteList.contains(toCheck) {
                            let part = "\(s)\(String.nbsp)\(String.nbsp)".builder
                                .font(font)
                                .foregroundColor(.white)
                                .result
                            result.append(part)
                        } else {
                            let part = "\(s)\(String.nbsp)\(String.nbsp)".builder
                                .font(font)
                                .foregroundColor(#colorLiteral(red: 0.8695564866, green: 0.5418210626, blue: 0, alpha: 1))
                                .result
                            result.append(part)
                        }
                    }
                } else {
                    let part = "\(line)\(String.nbsp)\(String.nbsp)".builder
                        .font(font)
                        .foregroundColor(.white)
                        .result
                    result.append(part)
                }
            }
            if i != text.endIndex - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    @inline(__always)
    public static func processTV(text: [String]) -> NSAttributedString {
        let punc = [",", ".", ";", "'", "-", "\"", "–", "?", "!"]
        let result = NSMutableAttributedString()

        for (i, line) in text.enumerated() {
            for word in line.split(separator: " ") {
                let s = String(word)
                var toCheck = s.lowercased()
                for x in punc {
                    toCheck = toCheck.replacingOccurrences(of: x, with: "")
                }
                toCheck = toCheck.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if toCheck.isEmpty || WordsChecker.badWords.contains(toCheck) {
                    let part = "\(s)\(String.nbsp)\(String.nbsp)".builder
                        .font(UIFont.systemFont(ofSize: 60, weight: .regular))
                        .foregroundColor(.white)
                        .result
                    result.append(part)
                } else {
                    let part = "\(s)\(String.nbsp)\(String.nbsp)".builder
                        .font(UIFont.systemFont(ofSize: 70, weight: .bold))
                        .foregroundColor(#colorLiteral(red: 0.8695564866, green: 0.5418210626, blue: 0, alpha: 1))
                        .result
                    result.append(part)
                }
            }
            if i != text.endIndex - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }
}
