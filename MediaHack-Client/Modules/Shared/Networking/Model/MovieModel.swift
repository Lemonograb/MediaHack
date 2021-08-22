import Foundation

public struct Movie: Codable {
    public let rating: Double
    public let tags: [String]
    public let dictionary: [String]
    public let url: String
    public let relevantCinemaIDS: [String]
    public let reviews: [Review]
    public let name, movieListDescription: String
    public let photoURL: String
    public let id: String

    enum CodingKeys: String, CodingKey {
        case rating, tags, dictionary, url
        case relevantCinemaIDS = "relevantCinemaIds"
        case reviews, name
        case movieListDescription = "description"
        case photoURL = "photoUrl"
        case id
    }

    public init(rating: Double, tags: [String], dictionary: [String], url: String, relevantCinemaIDS: [String], reviews: [Review], name: String, movieListDescription: String, photoURL: String, id: String) {
        self.rating = rating
        self.tags = tags
        self.dictionary = dictionary
        self.url = url
        self.relevantCinemaIDS = relevantCinemaIDS
        self.reviews = reviews
        self.name = name
        self.movieListDescription = movieListDescription
        self.photoURL = photoURL
        self.id = id
    }
}

// MARK: - Review

public struct Review: Codable {
    public let text, name, dateStr: String

    public init(text: String, name: String, dateStr: String) {
        self.text = text
        self.name = name
        self.dateStr = dateStr
    }
}
