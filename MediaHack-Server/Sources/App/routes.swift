import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    app.get("film") { req in
        return
            req.redirect(to: "https://1a5af214-d010-4ccc-b666-eba61130c0db.ams-static-03.cdntogo.net/pd/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzODM4Nzg7MTYyOTA2MTk0NCZoPXQtSEIyRG9UOVFZOGdVa3pPMWJvM0EmZT0xNjI5MTQ4MzQ0/9/5f/UShR5jRxtgmLNkVXY.mp4", type: .permanent)
    }
}
