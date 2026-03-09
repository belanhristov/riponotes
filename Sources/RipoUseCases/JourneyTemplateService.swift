import Foundation

public enum JourneyMood: String, CaseIterable, Sendable {
    case joyful
    case sad
    case calm
    case anxious
    case excited
    case tired

    public var title: String {
        switch self {
        case .joyful: return "Neseli"
        case .sad: return "Uzgyn"
        case .calm: return "Sakin"
        case .anxious: return "Kaygili"
        case .excited: return "Heyecanli"
        case .tired: return "Yorgun"
        }
    }
}

public enum JourneyDayPart: String, CaseIterable, Sendable {
    case daytime
    case night

    public var title: String {
        switch self {
        case .daytime: return "Gunduz"
        case .night: return "Gece"
        }
    }
}

public struct JourneyTemplateDraft: Sendable, Equatable {
    public var title: String
    public var body: String
    public var tags: [String]

    public init(title: String, body: String, tags: [String]) {
        self.title = title
        self.body = body
        self.tags = tags
    }
}

public struct JourneyTemplateService: Sendable {
    public init() {}

    public func makeDraft(
        mood: JourneyMood,
        dayPart: JourneyDayPart,
        date: Date = .now
    ) -> JourneyTemplateDraft {
        let dateText = date.formatted(date: .abbreviated, time: .omitted)
        let title = "\(dayPart.title) \(mood.title) - \(dateText)"
        let tags = ["journey", mood.rawValue, dayPart.rawValue]

        let focusLine = focusPrompt(mood: mood, dayPart: dayPart)
        let body = """
        Bugunun modu: \(mood.title)
        Zaman: \(dayPart.title)

        1) Bugunun hikayesi (2-3 cumle):
        -

        2) Duygu yogunlugu (1-10):
        -

        3) Bedende hissettigim sey:
        -

        4) Bu duyguyu tetikleyen olay:
        -

        5) O an aklimdan gecen cumle:
        -

        6) Ihtiyacim neydi / ne?
        -

        7) Kendime sefkat cumlem:
        -

        8) Yarinin mikro adimi (5 dakikalik):
        -

        9) Hafiza kapsulu (o gunun bir sesi, bir kokusu, bir goruntusu):
        -

        Ozel odak:
        \(focusLine)
        """

        return JourneyTemplateDraft(title: title, body: body, tags: tags)
    }

    private func focusPrompt(mood: JourneyMood, dayPart: JourneyDayPart) -> String {
        switch (mood, dayPart) {
        case (.sad, .night):
            return "Aksam uzgynlugunde kendine yumusak davran: bugun seni en cok zorlayan an neydi, buna ragmen ayakta kalmana ne yardim etti?"
        case (.joyful, .night):
            return "Bugunun sevincini sabitle: seni gulumseten 3 ani ve yarina tasimak istedigin 1 duyguyu yaz."
        case (.joyful, .daytime):
            return "Enerjini dagitmadan kullan: bugunun en guzel anini ve bunu tekrar etmenin kucuk yolunu yaz."
        case (.excited, .daytime):
            return "Heyecani odaga cevir: bugunun firsatini ve ilk somut adimini tek satirda yaz."
        case (.calm, _):
            return "Sakinligi koru: bugun iyi gelen ritmini ve bozmamak icin bir sinirini yaz."
        case (.anxious, _):
            return "Kaygiyi regule et: kontrol edebildigin 1 sey, erteleyebilecegin 1 sey, birakabilecegin 1 sey yaz."
        case (.tired, _):
            return "Yorgunlukta toparlanma: bugun senden enerji ceken seyi ve yarin enerji kazandiracak 1 aliskanligi yaz."
        case (.sad, .daytime):
            return "Gun ortasi uzgynlukte kendini suclama: su anda en cok neye ihtiyacin var, bunu bugun nasil karsilayabilirsin?"
        case (.excited, .night):
            return "Aksam heyecanini dengede bitir: bugunun zirve anini ve yarina biraktigin tek gorevi yaz."
        }
    }
}
