//
//  File.swift
//  
//
//  Created by Vitalii Stikhurov on 20.08.2021.
//

import Foundation

struct Cinema: Encodable {
    var id: String
    var name: String
    var url: String
    var photoUrl: String
    var description: String
    var ruSubtitles: [SubtitleParser.Subtitle]
    var engSubtitles: [SubtitleParser.Subtitle]
    var rating: Double
    var tags: [String]
    var dictionary: [String]
    var relevantCinemaIds: [String]
    var reviews: [Review]
}

struct Review: Encodable {
    var name: String
    var text: String
    var dateStr: String
}

let reviews: [Review] = [
    Review(name: "Еще утром был одним 2018",
           text: "Мой английский лексикон пополнился ярными и пестрящими словами. Отличное начало дня))",
           dateStr: "15 августа"),
    Review(name: "Джемба-Джемба",
           text: "Познавательно и продуктивно поучился. Криминал моя тема, генста",
           dateStr: "4 августа"),
]

let cinimasSubtitle: [String: String] = [
    "1": "pulp_fiction",
    "2": "pulp_fiction",
    "3": "pulp_fiction",
    "4": "pulp_fiction",
]

let cinimas: [Cinema] = [
    Cinema(
        id: "1",
        name: "Криминальное чтиво",
        url: "https://hulucdn.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTc1Mjc1NyZoPXV1NkdhbjRXWko3Skl2ZklOU3RaTVEmZT0xNjI5ODM5MTU3/5/d0/P30e5RYq9PKCDTAVJ.mp4/master-v1a1.m3u8?loc=nl",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/392.jpg",
        description: "Двое бандитов Винсент Вега и Джулс Винфилд ведут философские беседы в перерывах между разборками и решением проблем с должниками криминального босса Марселласа Уоллеса. В первой истории Винсент проводит незабываемый вечер с женой Марселласа Мией. Во второй рассказывается о боксёре Бутче Кулидже, купленном Уоллесом, чтобы сдать бой. В третьей истории Винсент и Джулс по нелепой случайности попадают в неприятности.",
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Криминал", "#Сложный"],
        dictionary: [
            "Mayonnaise",
            "You see that, young lady? Respect",
            "Uncomfortable silences",
            "Hate what",
            "I don't know. That's a good question",
            "I've seen 'em do it, man",
            "I have character",
            "And you know what they call a... a... a Quarter Pounder with Cheese in Paris?",
            "Hate what",
            "to yak about bullshit",
            "Goddamn",
            "We should have shotguns for this kind of deal",
        ],
        relevantCinemaIds: ["2", "3", "4"],
        reviews: reviews
    ),
    Cinema(
        id: "2",
        name: "Настоящий детектив",
        url: "https://3b92cc61-de74-40bc-aa1b-8e320c15508b.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxNzc0NyZoPUNUR082eGZqaG5oMFVBX0VlUktrMmcmZT0xNjI5NTA0MTQ3/9/5a/I4QoKy2hgz3IblosB.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/8741.jpg",
        description: """
        Первый сезон. В Луизиане в 1995 году происходит странное убийство девушки. В 2012 году дело об убийстве 1995г. повторно открывают, так как произошло похожее убийство. Дабы лучше продвинуться в расследовании, полиция решает допросить бывших детективов, которые работали над делом в 1995г.

        Второй сезон. В калифорнийском городе Винчи в преддверии презентации новой линии железной дороги, которая улучшит финансовое положение города, пропадает глава администрации города. Позже его труп находит на шоссе офицер дорожной полиции. К расследованию подключают детектива из полиции Винчи и детектива из департамента шерифа округа Вентура. То, что начиналось как убийство, превратилось в сеть заговоров и махинаций.

        Третий сезон. Действие разворачивается в районе известнякового плато Озарк, расположенного одновременно в нескольких штатах. Детектив Уэйн Хейз совместно со следователем из Арканзаса Роландом Уэстом пытаются разобраться в загадочном преступлении, растянувшемся на три десятилетия.
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Криминал", "#Сложный"],
        dictionary: [
            "Mayonnaise",
            "You see that, young lady? Respect",
            "Uncomfortable silences",
            "Hate what",
            "I don't know. That's a good question",
            "I've seen 'em do it, man",
            "I have character",
            "And you know what they call a... a... a Quarter Pounder with Cheese in Paris?",
            "Hate what",
            "to yak about bullshit",
            "Goddamn",
            "We should have shotguns for this kind of deal",
        ],
        relevantCinemaIds: ["1", "3", "4"],
        reviews: reviews
    ),
    Cinema(
        id: "3",
        name: "Во все тяжкие",
        url: "https://1a5af214-d010-4ccc-b666-eba61130c0db.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxNzg4MSZoPWFXaWVNaFVnNlppdndtY2ZZMG14Q2cmZT0xNjI5NTA0Mjgx/e/a5/8obVcGpK1uSWO6XA0.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/8739.jpg",
        description: """
        Школьный учитель химии Уолтер Уайт узнаёт, что болен раком лёгких. Учитывая сложное финансовое состояние дел семьи, а также перспективы, Уолтер решает заняться изготовлением метамфетамина. Для этого он привлекает своего бывшего ученика Джесси Пинкмана, когда-то исключённого из школы при активном содействии Уайта. Пинкман сам занимался «варкой мета», но накануне, в ходе рейда ОБН, он лишился подельника и лаборатории…
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Криминал", "#Средний"],
        dictionary: [
            "Mayonnaise",
            "You see that, young lady? Respect",
            "Uncomfortable silences",
            "Hate what",
            "I don't know. That's a good question",
            "I've seen 'em do it, man",
            "I have character",
            "And you know what they call a... a... a Quarter Pounder with Cheese in Paris?",
            "Hate what",
            "to yak about bullshit",
            "Goddamn",
            "We should have shotguns for this kind of deal",
        ],
        relevantCinemaIds: ["1", "2", "4"],
        reviews: reviews
    ),
    Cinema(
        id: "4",
        name: "Клан Сопрано",
        url: "https://43645b24-1d0c-4447-ad7d-b1fbbfe77210.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxODEwMyZoPUxUMDgtSTJ2eGg4RUx4TW9kZUk5aFEmZT0xNjI5NTA0NTAz/5/fa/TllNYF2Y76RycryJR.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/8668.jpg",
        description: """
        Повседневная жизнь современного Крестного отца: его мысли - стремительны, действия - решительны, а юмор - черен. Мафиозный босс Северного Джерси Тони Сопрано успешно справляется с проблемами «Семьи».

        Но вот собственная семья немного подкачала: дети от рук отбились, брак - под угрозой, мамаша - пилит. Он надеется на помощь психиатра, но как тому рассказать обо всех своих проблемах, если связан «Омертой» - обетом молчания, нарушать который нельзя под страхом смерти?
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Криминал", "#Легкий"],
        dictionary: [
            "Mayonnaise",
            "You see that, young lady? Respect",
            "Uncomfortable silences",
            "Hate what",
            "I don't know. That's a good question",
            "I've seen 'em do it, man",
            "I have character",
            "And you know what they call a... a... a Quarter Pounder with Cheese in Paris?",
            "Hate what",
            "to yak about bullshit",
            "Goddamn",
            "We should have shotguns for this kind of deal",
        ],
        relevantCinemaIds: ["1", "2", "3"],
        reviews: reviews
    )
]
