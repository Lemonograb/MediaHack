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
        url: "https://strm.yandex.ru/vh-ott-converted/ott-content/530389814-4a54e1d887da77c3ab345f7635ca9b59/master.m3u8?from=ott-kp&hash=b60bc9cbe1e6783ff44e51c6568b8386&vsid=b9690d561690dbd1eff4bfe5c79a1b9304a4d904a019xWEBx6710x1629612671&video_content_id=4a54e1d887da77c3ab345f7635ca9b59&session_data=1&preview=1&t=1629612671617",
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
        tags: ["#Фантастика", "#Легкий"],
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
    ),
    Cinema(
        id: "5",
        name: "Восхождение Юпитер",
        url: "https://43645b24-1d0c-4447-ad7d-b1fbbfe77210.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxODEwMyZoPUxUMDgtSTJ2eGg4RUx4TW9kZUk5aFEmZT0xNjI5NTA0NTAz/5/fa/TllNYF2Y76RycryJR.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/8645.jpg",
        description: """
        Прошло два года после высадки инопланетян на Землю. Пришельцам удалось захватить всю Австралию, но Сидней все еще не повержен — выжившие продолжают отчаянно сражаться, но их силы на исходе. Тем временем небольшая группа людей узнает о заговоре, который может положить конец войне.
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
        relevantCinemaIds: ["6", "2", "3"],
        reviews: reviews
    ),
    Cinema(
        id: "6",
        name: "Отряд самоубийц: Миссия навылет",
        url: "https://43645b24-1d0c-4447-ad7d-b1fbbfe77210.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxODEwMyZoPUxUMDgtSTJ2eGg4RUx4TW9kZUk5aFEmZT0xNjI5NTA0NTAz/5/fa/TllNYF2Y76RycryJR.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/73385.jpg",
        description: """
        Отобрав наиболее перспективных заключенных из тюрьмы, в которой содержатся не только самые опасные преступники, но и люди со свехрспособностями, и даже не люди, правительственный агент отправляет их на самоубийственное задание в одну латиноамериканскую страну, где недавно произошел военный переворот. А чтобы те наверняка не сбежали, каждому в голову вживляется взрывное устройство.
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Комедия", "#Легкий"],
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
        relevantCinemaIds: ["5", "2", "3"],
        reviews: reviews
    ),
    Cinema(
        id: "7",
        name: "Тролли. Мировой тур 3D",
        url: "https://43645b24-1d0c-4447-ad7d-b1fbbfe77210.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxODEwMyZoPUxUMDgtSTJ2eGg4RUx4TW9kZUk5aFEmZT0xNjI5NTA0NTAz/5/fa/TllNYF2Y76RycryJR.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/65713.jpg",
        description: """
        Поп-тролли в шоке – оказывается, мир музыки гораздо больше, чем они думали. Рейвы, оупен-эйры, классические концерты и, конечно, хип-хоп баттлы – впереди их ждет головокружительное веселье. Но неудержимая королева Рокс планирует уничтожить всё, чтобы миром безоговорочно правил хард-рок! Розочка, Цветан и их новые друзья отправляются в невероятное путешествие: им предстоит объединить всех троллей и помешать Рокс.
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Комедия", "#Легкий"],
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
        relevantCinemaIds: ["8", "2", "3"],
        reviews: reviews
    ),
    Cinema(
        id: "8",
        name: "Невозможные животные",
        url: "https://43645b24-1d0c-4447-ad7d-b1fbbfe77210.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxODEwMyZoPUxUMDgtSTJ2eGg4RUx4TW9kZUk5aFEmZT0xNjI5NTA0NTAz/5/fa/TllNYF2Y76RycryJR.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/73678.jpg",
        description: """
        Документальный сериал о самых поразительных животных планеты. Каждая среда обитания на Земле — уникальна и сложна. Природа постоянно «подкидывает» проблемы, которые животным нужно решать. Некоторые из них развили невероятные способности, помогающие выживать в самых трудных условиях. «Невозможные животные» — самое подходящее для них описание. Разум и тело этих созданий больше напоминает удивительные механизмы, которые, кажется, способны принять любой вызов от агрессивной окружающей среды.
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Животные", "#Легкий"],
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
        relevantCinemaIds: ["7", "2", "3"],
        reviews: reviews
    ),
    Cinema(
        id: "9",
        name: "Рик и Морти",
        url: "https://43645b24-1d0c-4447-ad7d-b1fbbfe77210.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxODEwMyZoPUxUMDgtSTJ2eGg4RUx4TW9kZUk5aFEmZT0xNjI5NTA0NTAz/5/fa/TllNYF2Y76RycryJR.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/8738.jpg",
        description: """
        В центре сюжета - школьник по имени Морти и его дедушка Рик. Морти - самый обычный мальчик, который ничем не отличается от своих сверстников. А вот его дедуля занимается необычными научными исследованиями и зачастую полностью неадекватен. Он может в любое время дня и ночи схватить внука и отправиться вместе с ним в безумные приключения с помощью построенной из разного хлама летающей тарелки, которая способна перемещаться сквозь межпространственный тоннель. Каждый раз эта парочка оказывается в самых неожиданных местах и самых нелепых ситуациях.
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Анимация", "#Средний"],
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
        relevantCinemaIds: ["7", "2", "3"],
        reviews: reviews
    ),
    Cinema(
        id: "10",
        name: "С полудня до трех",
        url: "https://43645b24-1d0c-4447-ad7d-b1fbbfe77210.ams-static-04.cdntogo.net/hls/aWQ9NTM0OTA3OzE4NDUyODMxNDE7MTIzOTkxNTQ7MTYyOTQxODEwMyZoPUxUMDgtSTJ2eGg4RUx4TW9kZUk5aFEmZT0xNjI5NTA0NTAz/5/fa/TllNYF2Y76RycryJR.mp4/master-v1a1.m3u8",
        photoUrl: "https://cdn.service-kp.com/poster/item/big/73810.jpg",
        description: """
        Чтобы ограбить банк, банде преступников требуется еще одна лошадь. Один из бандитов по имени Дорси идет украсть лошадь, а её владелица, прекрасная молодая вдова Аманда, положила глаз на Дорси. И вместо того, чтобы грабить банк, Дорси проводит три прекрасных часа женщиной, и ждет возвращения банды. Но ограбление идет не по плану, и Дорси уезжает спасать своих криминальных товарищей, или по крайней мере так думает Аманда.
        """,
        ruSubtitles: [],
        engSubtitles: [],
        rating: 9.8,
        tags: ["#Вестерн", "#Средний"],
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
        relevantCinemaIds: ["7", "2", "3"],
        reviews: reviews
    )
]
