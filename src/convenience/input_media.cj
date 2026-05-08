package grammy4cj.convenience

import grammy4cj.types.InputFile

public open class InputMedia {
    public let kind: String
    public let media: String
    public let isInputFile: Bool
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public let options: TelegramObject
    private let mediaFile: Option<InputFile>

    public init(kind: String, media: String, options: TelegramObject) {
        this.kind = kind
        this.media = media
        this.isInputFile = false
        this.sourceKind = ""
        this.sourceValue = ""
        this.filename = ""
        this.options = options.copy()
        this.mediaFile = None<InputFile>
    }

    public init(kind: String, file: InputFile, options: TelegramObject) {
        this.kind = kind
        this.media = "attach://media"
        this.isInputFile = true
        this.sourceKind = file.sourceKind
        this.sourceValue = file.sourceValue
        this.filename = file.filename
        this.options = options.copy()
        this.mediaFile = Some(file)
    }

    public func hasMediaFile(): Bool {
        match (this.mediaFile) {
            case Some(_) => true
            case None => false
        }
    }

    public func inputFile(): InputFile {
        match (this.mediaFile) {
            case Some(file) => file
            case None => throw Exception("input media does not contain an InputFile")
        }
    }

    public func toTelegramObject(): TelegramObject {
        let object = TelegramObject()
        object.addString("type", this.kind)
        object.addString("media", this.media)
        object.addAll(this.options)
        object
    }

    public func toJSON(): String {
        this.toTelegramObject().toJSON()
    }

    public func schema(): TelegramObjectSchema {
        inputMediaTelegramObjectSchema(this.kind)
    }

    public func schemaIsValid(): Bool {
        this.schema().isValid(this.toTelegramObject())
    }
}

public class InputMediaPhoto <: InputMedia {
    public init(media: String, options: TelegramObject) {
        super("photo", media, options)
    }

    public init(media: InputFile, options: TelegramObject) {
        super("photo", media, options)
    }
}

public class InputMediaVideo <: InputMedia {
    public init(media: String, options: TelegramObject) {
        super("video", media, options)
    }

    public init(media: InputFile, options: TelegramObject) {
        super("video", media, options)
    }
}

public class InputMediaAnimation <: InputMedia {
    public init(media: String, options: TelegramObject) {
        super("animation", media, options)
    }

    public init(media: InputFile, options: TelegramObject) {
        super("animation", media, options)
    }
}

public class InputMediaAudio <: InputMedia {
    public init(media: String, options: TelegramObject) {
        super("audio", media, options)
    }

    public init(media: InputFile, options: TelegramObject) {
        super("audio", media, options)
    }
}

public class InputMediaDocument <: InputMedia {
    public init(media: String, options: TelegramObject) {
        super("document", media, options)
    }

    public init(media: InputFile, options: TelegramObject) {
        super("document", media, options)
    }
}

public class InputMediaBuilder {
    public static func photo(media: String): InputMediaPhoto {
        InputMediaPhoto(media, TelegramObject())
    }

    public static func photo(media: String, options: TelegramObject): InputMediaPhoto {
        InputMediaPhoto(media, options)
    }

    public static func photo(media: InputFile): InputMediaPhoto {
        InputMediaPhoto(media, TelegramObject())
    }

    public static func photo(media: InputFile, options: TelegramObject): InputMediaPhoto {
        InputMediaPhoto(media, options)
    }

    public static func video(media: String): InputMediaVideo {
        InputMediaVideo(media, TelegramObject())
    }

    public static func video(media: String, options: TelegramObject): InputMediaVideo {
        InputMediaVideo(media, options)
    }

    public static func video(media: InputFile): InputMediaVideo {
        InputMediaVideo(media, TelegramObject())
    }

    public static func video(media: InputFile, options: TelegramObject): InputMediaVideo {
        InputMediaVideo(media, options)
    }

    public static func animation(media: String): InputMediaAnimation {
        InputMediaAnimation(media, TelegramObject())
    }

    public static func animation(media: String, options: TelegramObject): InputMediaAnimation {
        InputMediaAnimation(media, options)
    }

    public static func animation(media: InputFile): InputMediaAnimation {
        InputMediaAnimation(media, TelegramObject())
    }

    public static func animation(media: InputFile, options: TelegramObject): InputMediaAnimation {
        InputMediaAnimation(media, options)
    }

    public static func audio(media: String): InputMediaAudio {
        InputMediaAudio(media, TelegramObject())
    }

    public static func audio(media: String, options: TelegramObject): InputMediaAudio {
        InputMediaAudio(media, options)
    }

    public static func audio(media: InputFile): InputMediaAudio {
        InputMediaAudio(media, TelegramObject())
    }

    public static func audio(media: InputFile, options: TelegramObject): InputMediaAudio {
        InputMediaAudio(media, options)
    }

    public static func document(media: String): InputMediaDocument {
        InputMediaDocument(media, TelegramObject())
    }

    public static func document(media: String, options: TelegramObject): InputMediaDocument {
        InputMediaDocument(media, options)
    }

    public static func document(media: InputFile): InputMediaDocument {
        InputMediaDocument(media, TelegramObject())
    }

    public static func document(media: InputFile, options: TelegramObject): InputMediaDocument {
        InputMediaDocument(media, options)
    }

    public static func schema(kind: String): TelegramObjectSchema {
        inputMediaTelegramObjectSchema(kind)
    }
}

private func inputMediaTelegramObjectSchema(kind: String): TelegramObjectSchema {
    TelegramObjectSchema("InputMedia." + kind)
        .requireString("type", kind)
        .requireField("media")
        .allowFields([
            "caption",
            "parse_mode",
            "caption_entities",
            "show_caption_above_media",
            "has_spoiler",
            "thumbnail",
            "cover",
            "start_timestamp",
            "width",
            "height",
            "duration",
            "supports_streaming",
            "performer",
            "title",
            "disable_content_type_detection"
        ])
}
