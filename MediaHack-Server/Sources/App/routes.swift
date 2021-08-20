import Vapor

func routes(_ app: Application) throws {

    app.get { req in
        return "It works!"
    }

    app.get("cinemaList") { req -> String in
        let data = try JSONEncoder().encode(cinimas)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
