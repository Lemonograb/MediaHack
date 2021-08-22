import Combine
import Foundation

public enum API {
    private static let session = URLSession.shared
    private static let baseURL = URL(string: "http://178.154.197.24").unsafelyUnwrapped
    private static let decoder = JSONDecoder()

    public static func getMovies() -> AnyPublisher<[Movie], Error> {
        let endpoint = baseURL.appendingPathComponent("cinemaList")
        return session.dataTaskPublisher(for: endpoint).tryMap { (data: Data, _: URLResponse) in
            try decoder.decode([Movie].self, from: data)
        }.eraseToAnyPublisher()
    }

    public static func getSubtitle(movie: Movie) -> AnyPublisher<MovieSubtitles, Error> {
        var endpoint = baseURL.appendingPathComponent("subtitle")
        endpoint = endpoint.appending("id", value: movie.id)
        return session.dataTaskPublisher(for: endpoint).tryMap { (data: Data, _: URLResponse) in
            try decoder.decode(MovieSubtitles.self, from: data)
        }.eraseToAnyPublisher()
    }

    public static func define(word: String) -> AnyPublisher<[String], Error> {
        var endpoint = baseURL.appendingPathComponent("translate")
        endpoint = endpoint.appending("word", value: word)
        return session.dataTaskPublisher(for: endpoint).tryMap { (data: Data, _: URLResponse) in
            try decoder.decode([String].self, from: data)
        }.eraseToAnyPublisher()
    }
}

extension URL {
    func appending(_ queryItem: String, value: String?) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }

        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []

        // Create query item
        let queryItem = URLQueryItem(name: queryItem, value: value)

        // Append the new query item in the existing query items array
        queryItems.append(queryItem)

        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems

        // Returns the url from new url components
        return urlComponents.url!
    }
}
