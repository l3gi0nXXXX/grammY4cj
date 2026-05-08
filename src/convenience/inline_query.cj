package grammy4cj.convenience

import std.collection.ArrayList

public open class InlineQueryResult {
    public let template: TelegramObject

    public init(template: TelegramObject) {
        this.template = template.copy()
    }

    public func text(messageText: String): InlineQueryResult {
        this.text(messageText, TelegramObject())
    }

    public func text(messageText: String, options: TelegramObject): InlineQueryResult {
        let content = TelegramObject()
        content.addString("message_text", messageText)
        content.addAll(options)
        this.withInputMessageContent(content)
    }

    public func location(latitude: Float64, longitude: Float64): InlineQueryResult {
        this.location(latitude, longitude, TelegramObject())
    }

    public func location(latitude: Float64, longitude: Float64, options: TelegramObject): InlineQueryResult {
        let content = TelegramObject()
        content.addFloat("latitude", latitude)
        content.addFloat("longitude", longitude)
        content.addAll(options)
        this.withInputMessageContent(content)
    }

    public func venue(title: String, latitude: Float64, longitude: Float64, address: String): InlineQueryResult {
        this.venue(title, latitude, longitude, address, TelegramObject())
    }

    public func venue(
        title: String,
        latitude: Float64,
        longitude: Float64,
        address: String,
        options: TelegramObject
    ): InlineQueryResult {
        let content = TelegramObject()
        content.addString("title", title)
        content.addFloat("latitude", latitude)
        content.addFloat("longitude", longitude)
        content.addString("address", address)
        content.addAll(options)
        this.withInputMessageContent(content)
    }

    public func contact(firstName: String, phoneNumber: String): InlineQueryResult {
        this.contact(firstName, phoneNumber, TelegramObject())
    }

    public func contact(firstName: String, phoneNumber: String, options: TelegramObject): InlineQueryResult {
        let content = TelegramObject()
        content.addString("first_name", firstName)
        content.addString("phone_number", phoneNumber)
        content.addAll(options)
        this.withInputMessageContent(content)
    }

    public func invoice(
        title: String,
        description: String,
        payload: String,
        providerToken: String,
        currency: String,
        prices: ArrayList<TelegramObject>
    ): InlineQueryResult {
        this.invoice(title, description, payload, providerToken, currency, prices, TelegramObject())
    }

    public func invoice(
        title: String,
        description: String,
        payload: String,
        providerToken: String,
        currency: String,
        prices: ArrayList<TelegramObject>,
        options: TelegramObject
    ): InlineQueryResult {
        let content = TelegramObject()
        content.addString("title", title)
        content.addString("description", description)
        content.addString("payload", payload)
        content.addString("provider_token", providerToken)
        content.addString("currency", currency)
        content.addArray("prices", objectArrayValue(prices))
        content.addAll(options)
        this.withInputMessageContent(content)
    }

    public func withInputMessageContent(content: TelegramObject): InlineQueryResult {
        let object = this.template.copy()
        object.addObject("input_message_content", content)
        InlineQueryResult(object)
    }

    public func toTelegramObject(): TelegramObject {
        this.template.copy()
    }

    public func toJSON(): String {
        this.template.toJSON()
    }

    public func schema(): TelegramObjectSchema {
        inlineQueryResultTelegramObjectSchema(this.template.stringField("type"), this.template.stringField("mime_type"))
    }

    public func schemaIsValid(): Bool {
        this.schema().isValid(this.toTelegramObject())
    }
}

public class InlineQueryResultArticle <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultAudio <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedAudio <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultContact <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultDocument <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedDocument <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultGame <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultGif <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedGif <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultLocation <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultMpeg4Gif <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedMpeg4Gif <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultPhoto <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedPhoto <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedSticker <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultVenue <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultVideo <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedVideo <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultVoice <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }
public class InlineQueryResultCachedVoice <: InlineQueryResult { public init(template: TelegramObject) { super(template) } }

public func labeledPrice(label: String, amount: Int64): TelegramObject {
    let price = TelegramObject()
    price.addString("label", label)
    price.addInt("amount", amount)
    price
}

public class InlineQueryResultBuilder {
    public static func article(id: String, title: String): InlineQueryResultArticle {
        InlineQueryResultBuilder.article(id, title, TelegramObject())
    }

    public static func article(id: String, title: String, options: TelegramObject): InlineQueryResultArticle {
        let object = typed("article", id)
        object.addString("title", title)
        object.addAll(options)
        InlineQueryResultArticle(object)
    }

    public static func audio(id: String, title: String, audioUrl: String): InlineQueryResultAudio {
        InlineQueryResultBuilder.audio(id, title, audioUrl, TelegramObject())
    }

    public static func audio(id: String, title: String, audioUrl: String, options: TelegramObject): InlineQueryResultAudio {
        let object = typed("audio", id)
        object.addString("title", title)
        object.addString("audio_url", audioUrl)
        object.addAll(options)
        InlineQueryResultAudio(object)
    }

    public static func audioCached(id: String, audioFileId: String): InlineQueryResultCachedAudio {
        InlineQueryResultBuilder.audioCached(id, audioFileId, TelegramObject())
    }

    public static func audioCached(id: String, audioFileId: String, options: TelegramObject): InlineQueryResultCachedAudio {
        let object = typed("audio", id)
        object.addString("audio_file_id", audioFileId)
        object.addAll(options)
        InlineQueryResultCachedAudio(object)
    }

    public static func contact(id: String, phoneNumber: String, firstName: String): InlineQueryResultContact {
        InlineQueryResultBuilder.contact(id, phoneNumber, firstName, TelegramObject())
    }

    public static func contact(
        id: String,
        phoneNumber: String,
        firstName: String,
        options: TelegramObject
    ): InlineQueryResultContact {
        let object = typed("contact", id)
        object.addString("phone_number", phoneNumber)
        object.addString("first_name", firstName)
        object.addAll(options)
        InlineQueryResultContact(object)
    }

    public static func documentPdf(id: String, title: String, documentUrl: String): InlineQueryResultDocument {
        InlineQueryResultBuilder.documentPdf(id, title, documentUrl, TelegramObject())
    }

    public static func documentPdf(
        id: String,
        title: String,
        documentUrl: String,
        options: TelegramObject
    ): InlineQueryResultDocument {
        let object = TelegramObject()
        object.addString("type", "document")
        object.addString("mime_type", "application/pdf")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("document_url", documentUrl)
        object.addAll(options)
        InlineQueryResultDocument(object)
    }

    public static func documentZip(id: String, title: String, documentUrl: String): InlineQueryResultDocument {
        InlineQueryResultBuilder.documentZip(id, title, documentUrl, TelegramObject())
    }

    public static func documentZip(
        id: String,
        title: String,
        documentUrl: String,
        options: TelegramObject
    ): InlineQueryResultDocument {
        let object = TelegramObject()
        object.addString("type", "document")
        object.addString("mime_type", "application/zip")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("document_url", documentUrl)
        object.addAll(options)
        InlineQueryResultDocument(object)
    }

    public static func documentCached(id: String, title: String, documentFileId: String): InlineQueryResultCachedDocument {
        InlineQueryResultBuilder.documentCached(id, title, documentFileId, TelegramObject())
    }

    public static func documentCached(
        id: String,
        title: String,
        documentFileId: String,
        options: TelegramObject
    ): InlineQueryResultCachedDocument {
        let object = typed("document", id)
        object.addString("title", title)
        object.addString("document_file_id", documentFileId)
        object.addAll(options)
        InlineQueryResultCachedDocument(object)
    }

    public static func game(id: String, gameShortName: String): InlineQueryResultGame {
        InlineQueryResultBuilder.game(id, gameShortName, TelegramObject())
    }

    public static func game(id: String, gameShortName: String, options: TelegramObject): InlineQueryResultGame {
        let object = typed("game", id)
        object.addString("game_short_name", gameShortName)
        object.addAll(options)
        InlineQueryResultGame(object)
    }

    public static func gif(id: String, gifUrl: String, thumbnailUrl: String): InlineQueryResultGif {
        InlineQueryResultBuilder.gif(id, gifUrl, thumbnailUrl, TelegramObject())
    }

    public static func gif(
        id: String,
        gifUrl: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResultGif {
        let object = typed("gif", id)
        object.addString("gif_url", gifUrl)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResultGif(object)
    }

    public static func gifCached(id: String, gifFileId: String): InlineQueryResultCachedGif {
        InlineQueryResultBuilder.gifCached(id, gifFileId, TelegramObject())
    }

    public static func gifCached(id: String, gifFileId: String, options: TelegramObject): InlineQueryResultCachedGif {
        let object = typed("gif", id)
        object.addString("gif_file_id", gifFileId)
        object.addAll(options)
        InlineQueryResultCachedGif(object)
    }

    public static func location(id: String, title: String, latitude: Float64, longitude: Float64): InlineQueryResultLocation {
        InlineQueryResultBuilder.location(id, title, latitude, longitude, TelegramObject())
    }

    public static func location(
        id: String,
        title: String,
        latitude: Float64,
        longitude: Float64,
        options: TelegramObject
    ): InlineQueryResultLocation {
        let object = typed("location", id)
        object.addString("title", title)
        object.addFloat("latitude", latitude)
        object.addFloat("longitude", longitude)
        object.addAll(options)
        InlineQueryResultLocation(object)
    }

    public static func mpeg4gif(id: String, mpeg4Url: String, thumbnailUrl: String): InlineQueryResultMpeg4Gif {
        InlineQueryResultBuilder.mpeg4gif(id, mpeg4Url, thumbnailUrl, TelegramObject())
    }

    public static func mpeg4gif(
        id: String,
        mpeg4Url: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResultMpeg4Gif {
        let object = typed("mpeg4_gif", id)
        object.addString("mpeg4_url", mpeg4Url)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResultMpeg4Gif(object)
    }

    public static func mpeg4gifCached(id: String, mpeg4FileId: String): InlineQueryResultCachedMpeg4Gif {
        InlineQueryResultBuilder.mpeg4gifCached(id, mpeg4FileId, TelegramObject())
    }

    public static func mpeg4gifCached(id: String, mpeg4FileId: String, options: TelegramObject): InlineQueryResultCachedMpeg4Gif {
        let object = typed("mpeg4_gif", id)
        object.addString("mpeg4_file_id", mpeg4FileId)
        object.addAll(options)
        InlineQueryResultCachedMpeg4Gif(object)
    }

    public static func photo(id: String, photoUrl: String): InlineQueryResultPhoto {
        InlineQueryResultBuilder.photo(id, photoUrl, TelegramObject())
    }

    public static func photo(id: String, photoUrl: String, options: TelegramObject): InlineQueryResultPhoto {
        let object = typed("photo", id)
        object.addString("photo_url", photoUrl)
        object.addString("thumbnail_url", photoUrl)
        object.addAll(options)
        InlineQueryResultPhoto(object)
    }

    public static func photoCached(id: String, photoFileId: String): InlineQueryResultCachedPhoto {
        InlineQueryResultBuilder.photoCached(id, photoFileId, TelegramObject())
    }

    public static func photoCached(id: String, photoFileId: String, options: TelegramObject): InlineQueryResultCachedPhoto {
        let object = typed("photo", id)
        object.addString("photo_file_id", photoFileId)
        object.addAll(options)
        InlineQueryResultCachedPhoto(object)
    }

    public static func stickerCached(id: String, stickerFileId: String): InlineQueryResultCachedSticker {
        InlineQueryResultBuilder.stickerCached(id, stickerFileId, TelegramObject())
    }

    public static func stickerCached(id: String, stickerFileId: String, options: TelegramObject): InlineQueryResultCachedSticker {
        let object = typed("sticker", id)
        object.addString("sticker_file_id", stickerFileId)
        object.addAll(options)
        InlineQueryResultCachedSticker(object)
    }

    public static func venue(
        id: String,
        title: String,
        latitude: Float64,
        longitude: Float64,
        address: String
    ): InlineQueryResultVenue {
        InlineQueryResultBuilder.venue(id, title, latitude, longitude, address, TelegramObject())
    }

    public static func venue(
        id: String,
        title: String,
        latitude: Float64,
        longitude: Float64,
        address: String,
        options: TelegramObject
    ): InlineQueryResultVenue {
        let object = typed("venue", id)
        object.addString("title", title)
        object.addFloat("latitude", latitude)
        object.addFloat("longitude", longitude)
        object.addString("address", address)
        object.addAll(options)
        InlineQueryResultVenue(object)
    }

    public static func videoHtml(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String
    ): InlineQueryResultVideo {
        InlineQueryResultBuilder.videoHtml(id, title, videoUrl, thumbnailUrl, TelegramObject())
    }

    public static func videoHtml(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResultVideo {
        let object = TelegramObject()
        object.addString("type", "video")
        object.addString("mime_type", "text/html")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("video_url", videoUrl)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResultVideo(object)
    }

    public static func videoMp4(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String
    ): InlineQueryResultVideo {
        InlineQueryResultBuilder.videoMp4(id, title, videoUrl, thumbnailUrl, TelegramObject())
    }

    public static func videoMp4(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResultVideo {
        let object = TelegramObject()
        object.addString("type", "video")
        object.addString("mime_type", "video/mp4")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("video_url", videoUrl)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResultVideo(object)
    }

    public static func videoCached(id: String, title: String, videoFileId: String): InlineQueryResultCachedVideo {
        InlineQueryResultBuilder.videoCached(id, title, videoFileId, TelegramObject())
    }

    public static func videoCached(
        id: String,
        title: String,
        videoFileId: String,
        options: TelegramObject
    ): InlineQueryResultCachedVideo {
        let object = typed("video", id)
        object.addString("title", title)
        object.addString("video_file_id", videoFileId)
        object.addAll(options)
        InlineQueryResultCachedVideo(object)
    }

    public static func voice(id: String, title: String, voiceUrl: String): InlineQueryResultVoice {
        InlineQueryResultBuilder.voice(id, title, voiceUrl, TelegramObject())
    }

    public static func voice(id: String, title: String, voiceUrl: String, options: TelegramObject): InlineQueryResultVoice {
        let object = typed("voice", id)
        object.addString("title", title)
        object.addString("voice_url", voiceUrl)
        object.addAll(options)
        InlineQueryResultVoice(object)
    }

    public static func voiceCached(id: String, title: String, voiceFileId: String): InlineQueryResultCachedVoice {
        InlineQueryResultBuilder.voiceCached(id, title, voiceFileId, TelegramObject())
    }

    public static func voiceCached(
        id: String,
        title: String,
        voiceFileId: String,
        options: TelegramObject
    ): InlineQueryResultCachedVoice {
        let object = typed("voice", id)
        object.addString("title", title)
        object.addString("voice_file_id", voiceFileId)
        object.addAll(options)
        InlineQueryResultCachedVoice(object)
    }

    public static func schema(kind: String): TelegramObjectSchema {
        inlineQueryResultTelegramObjectSchema(kind)
    }
}

private func typed(kind: String, id: String): TelegramObject {
    let object = TelegramObject()
    object.addString("type", kind)
    object.addString("id", id)
    object
}

private func inlineQueryResultTelegramObjectSchema(kind: String): TelegramObjectSchema {
    inlineQueryResultTelegramObjectSchema(kind, "")
}

private func inlineQueryResultTelegramObjectSchema(kind: String, mimeType: String): TelegramObjectSchema {
    let schema = TelegramObjectSchema("InlineQueryResult." + kind)
        .requireString("type", kind)
        .requireField("id")
        .allowFields([
            "title",
            "caption",
            "parse_mode",
            "caption_entities",
            "show_caption_above_media",
            "description",
            "reply_markup",
            "input_message_content",
            "thumbnail_url",
            "thumbnail_width",
            "thumbnail_height",
            "audio_url",
            "audio_file_id",
            "audio_duration",
            "performer",
            "phone_number",
            "first_name",
            "last_name",
            "vcard",
            "mime_type",
            "document_url",
            "document_file_id",
            "game_short_name",
            "gif_url",
            "gif_file_id",
            "gif_width",
            "gif_height",
            "gif_duration",
            "latitude",
            "longitude",
            "horizontal_accuracy",
            "live_period",
            "heading",
            "proximity_alert_radius",
            "mpeg4_url",
            "mpeg4_file_id",
            "mpeg4_width",
            "mpeg4_height",
            "mpeg4_duration",
            "photo_url",
            "photo_file_id",
            "photo_width",
            "photo_height",
            "sticker_file_id",
            "address",
            "foursquare_id",
            "foursquare_type",
            "google_place_id",
            "google_place_type",
            "video_url",
            "video_file_id",
            "video_width",
            "video_height",
            "video_duration",
            "voice_url",
            "voice_file_id",
            "voice_duration"
        ])

    if (kind == "article") {
        schema.requireField("title").requireField("input_message_content").allowField("url").allowField("hide_url")
    } else if (kind == "audio") {
        schema.allowField("title").allowField("audio_url").allowField("audio_file_id")
    } else if (kind == "contact") {
        schema.requireField("phone_number").requireField("first_name")
    } else if (kind == "document") {
        schema.allowField("title").allowField("document_url").allowField("document_file_id").allowField("mime_type")
    } else if (kind == "game") {
        schema.requireField("game_short_name")
    } else if (kind == "gif") {
        schema.allowField("gif_url").allowField("gif_file_id").allowField("thumbnail_url")
    } else if (kind == "location") {
        schema.requireField("title").requireField("latitude").requireField("longitude")
    } else if (kind == "mpeg4_gif") {
        schema.allowField("mpeg4_url").allowField("mpeg4_file_id").allowField("thumbnail_url")
    } else if (kind == "photo") {
        schema.allowField("photo_url").allowField("photo_file_id").allowField("thumbnail_url")
    } else if (kind == "sticker") {
        schema.requireField("sticker_file_id")
    } else if (kind == "venue") {
        schema.requireField("title").requireField("latitude").requireField("longitude").requireField("address")
    } else if (kind == "video") {
        schema.allowField("title").allowField("video_url").allowField("video_file_id").allowField("mime_type").allowField("thumbnail_url")
        if (mimeType == "text/html") {
            schema.requireField("input_message_content")
        }
    } else if (kind == "voice") {
        schema.allowField("title").allowField("voice_url").allowField("voice_file_id")
    }
    schema
}
