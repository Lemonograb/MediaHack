import Foundation

public enum DefinitionHandler {
    private(set) static var definitions: [String: [String]] = [:]

    public static func add(word: String, def: [String]) {
        definitions[word] = def
    }
}
