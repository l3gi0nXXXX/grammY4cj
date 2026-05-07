package grammy4cj.convenience

import grammy4cj.types.InputFile

public class InputMedia {
    public let kind: String
    public let media: String
    public let isInputFile: Bool
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public let options: TelegramObject

    public init(kind: String, media: String, options: TelegramObject) {
        this.kind = kind
        this.media = media
        this.isInputFile = false
        this.sourceKind = ""
        this.sourceValue = ""
        this.filename = ""
        this.options = options.copy()
    }

    public init(kind: String, file: InputFile, options: TelegramObject) {
        this.kind = kind
        this.media = ""
        this.isInputFile = true
        this.sourceKind = file.sourceKind
        this.sourceValue = file.sourceValue
        this.filename = file.filename
        this.options = options.copy()
    }

    public func toTelegramObject(): TelegramObject {
        let object = TelegramObject()
        object.addString("type", this.kind)
        if (this.isInputFile) {
            let file = TelegramObject()
            file.addString("source_kind", this.sourceKind)
            file.addString("source_value", this.sourceValue)
            file.addString("filename", this.filename)
            object.addObject("media", file)
        } else {
            object.addString("media", this.media)
        }
        object.addAll(this.options)
        object
    }

    public func toJSON(): String {
        this.toTelegramObject().toJSON()
    }
}

public class InputMediaBuilder {
    public static func photo(media: String): InputMedia {
        InputMedia("photo", media, TelegramObject())
    }

    public static func photo(media: String, options: TelegramObject): InputMedia {
        InputMedia("photo", media, options)
    }

    public static func photo(media: InputFile): InputMedia {
        InputMedia("photo", media, TelegramObject())
    }

    public static func photo(media: InputFile, options: TelegramObject): InputMedia {
        InputMedia("photo", media, options)
    }

    public static func video(media: String): InputMedia {
        InputMedia("video", media, TelegramObject())
    }

    public static func video(media: String, options: TelegramObject): InputMedia {
        InputMedia("video", media, options)
    }

    public static func video(media: InputFile): InputMedia {
        InputMedia("video", media, TelegramObject())
    }

    public static func video(media: InputFile, options: TelegramObject): InputMedia {
        InputMedia("video", media, options)
    }

    public static func animation(media: String): InputMedia {
        InputMedia("animation", media, TelegramObject())
    }

    public static func animation(media: String, options: TelegramObject): InputMedia {
        InputMedia("animation", media, options)
    }

    public static func animation(media: InputFile): InputMedia {
        InputMedia("animation", media, TelegramObject())
    }

    public static func animation(media: InputFile, options: TelegramObject): InputMedia {
        InputMedia("animation", media, options)
    }

    public static func audio(media: String): InputMedia {
        InputMedia("audio", media, TelegramObject())
    }

    public static func audio(media: String, options: TelegramObject): InputMedia {
        InputMedia("audio", media, options)
    }

    public static func audio(media: InputFile): InputMedia {
        InputMedia("audio", media, TelegramObject())
    }

    public static func audio(media: InputFile, options: TelegramObject): InputMedia {
        InputMedia("audio", media, options)
    }

    public static func document(media: String): InputMedia {
        InputMedia("document", media, TelegramObject())
    }

    public static func document(media: String, options: TelegramObject): InputMedia {
        InputMedia("document", media, options)
    }

    public static func document(media: InputFile): InputMedia {
        InputMedia("document", media, TelegramObject())
    }

    public static func document(media: InputFile, options: TelegramObject): InputMedia {
        InputMedia("document", media, options)
    }
}
