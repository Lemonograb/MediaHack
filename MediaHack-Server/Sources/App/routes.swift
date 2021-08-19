import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("subtitle") { req -> String in
        let homeDirURL = FileManager.default.homeDirectoryForCurrentUser
        let resourceURL = homeDirURL.appendingPathComponent("server_content/").appendingPathComponent("GoT401.srt", isDirectory: false)
        let data = try Data(contentsOf: resourceURL)
        if let timeFromStartStr: String = req.query["timeFromStart"],
           let timeFromStart = Double(timeFromStartStr),
           let subtitles = String(data: data, encoding: .utf8)
           {
            let parser = SubtitleParser(text: subtitles)
            return parser?.subtitle(for: timeFromStart)?.text.joined(separator: "\n") ?? ""
        } else {
            return String(data: data, encoding: .utf8) ?? "fail"
        }
    }

    app.get("film") { req in
        return
            req.redirect(to: "https://3b92cc61-de74-40bc-aa1b-8e320c15508b.ams-static-03.cdntogo.net/pd/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTEzOTEyNSZoPVI1amxoVml1VUhUcmFZOHAtWnlBOGcmZT0xNjI5MjI1NTI1/1/a0/3q5UbAdIP1lWJuN7N.mp4", type: .permanent)
    }
}
