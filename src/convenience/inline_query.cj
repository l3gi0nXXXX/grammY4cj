package grammy4cj.convenience

import std.collection.ArrayList

public class InlineQueryResult {
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
}

public func labeledPrice(label: String, amount: Int64): TelegramObject {
    let price = TelegramObject()
    price.addString("label", label)
    price.addInt("amount", amount)
    price
}

public class InlineQueryResultBuilder {
    public static func article(id: String, title: String): InlineQueryResult {
        InlineQueryResultBuilder.article(id, title, TelegramObject())
    }

    public static func article(id: String, title: String, options: TelegramObject): InlineQueryResult {
        let object = typed("article", id)
        object.addString("title", title)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func audio(id: String, title: String, audioUrl: String): InlineQueryResult {
        InlineQueryResultBuilder.audio(id, title, audioUrl, TelegramObject())
    }

    public static func audio(id: String, title: String, audioUrl: String, options: TelegramObject): InlineQueryResult {
        let object = typed("audio", id)
        object.addString("title", title)
        object.addString("audio_url", audioUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func audioCached(id: String, audioFileId: String): InlineQueryResult {
        InlineQueryResultBuilder.audioCached(id, audioFileId, TelegramObject())
    }

    public static func audioCached(id: String, audioFileId: String, options: TelegramObject): InlineQueryResult {
        let object = typed("audio", id)
        object.addString("audio_file_id", audioFileId)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func contact(id: String, phoneNumber: String, firstName: String): InlineQueryResult {
        InlineQueryResultBuilder.contact(id, phoneNumber, firstName, TelegramObject())
    }

    public static func contact(
        id: String,
        phoneNumber: String,
        firstName: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("contact", id)
        object.addString("phone_number", phoneNumber)
        object.addString("first_name", firstName)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func documentPdf(id: String, title: String, documentUrl: String): InlineQueryResult {
        InlineQueryResultBuilder.documentPdf(id, title, documentUrl, TelegramObject())
    }

    public static func documentPdf(
        id: String,
        title: String,
        documentUrl: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = TelegramObject()
        object.addString("type", "document")
        object.addString("mime_type", "application/pdf")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("document_url", documentUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func documentZip(id: String, title: String, documentUrl: String): InlineQueryResult {
        InlineQueryResultBuilder.documentZip(id, title, documentUrl, TelegramObject())
    }

    public static func documentZip(
        id: String,
        title: String,
        documentUrl: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = TelegramObject()
        object.addString("type", "document")
        object.addString("mime_type", "application/zip")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("document_url", documentUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func documentCached(id: String, title: String, documentFileId: String): InlineQueryResult {
        InlineQueryResultBuilder.documentCached(id, title, documentFileId, TelegramObject())
    }

    public static func documentCached(
        id: String,
        title: String,
        documentFileId: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("document", id)
        object.addString("title", title)
        object.addString("document_file_id", documentFileId)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func game(id: String, gameShortName: String): InlineQueryResult {
        InlineQueryResultBuilder.game(id, gameShortName, TelegramObject())
    }

    public static func game(id: String, gameShortName: String, options: TelegramObject): InlineQueryResult {
        let object = typed("game", id)
        object.addString("game_short_name", gameShortName)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func gif(id: String, gifUrl: String, thumbnailUrl: String): InlineQueryResult {
        InlineQueryResultBuilder.gif(id, gifUrl, thumbnailUrl, TelegramObject())
    }

    public static func gif(
        id: String,
        gifUrl: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("gif", id)
        object.addString("gif_url", gifUrl)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func gifCached(id: String, gifFileId: String): InlineQueryResult {
        InlineQueryResultBuilder.gifCached(id, gifFileId, TelegramObject())
    }

    public static func gifCached(id: String, gifFileId: String, options: TelegramObject): InlineQueryResult {
        let object = typed("gif", id)
        object.addString("gif_file_id", gifFileId)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func location(id: String, title: String, latitude: Float64, longitude: Float64): InlineQueryResult {
        InlineQueryResultBuilder.location(id, title, latitude, longitude, TelegramObject())
    }

    public static func location(
        id: String,
        title: String,
        latitude: Float64,
        longitude: Float64,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("location", id)
        object.addString("title", title)
        object.addFloat("latitude", latitude)
        object.addFloat("longitude", longitude)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func mpeg4gif(id: String, mpeg4Url: String, thumbnailUrl: String): InlineQueryResult {
        InlineQueryResultBuilder.mpeg4gif(id, mpeg4Url, thumbnailUrl, TelegramObject())
    }

    public static func mpeg4gif(
        id: String,
        mpeg4Url: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("mpeg4_gif", id)
        object.addString("mpeg4_url", mpeg4Url)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func mpeg4gifCached(id: String, mpeg4FileId: String): InlineQueryResult {
        InlineQueryResultBuilder.mpeg4gifCached(id, mpeg4FileId, TelegramObject())
    }

    public static func mpeg4gifCached(id: String, mpeg4FileId: String, options: TelegramObject): InlineQueryResult {
        let object = typed("mpeg4_gif", id)
        object.addString("mpeg4_file_id", mpeg4FileId)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func photo(id: String, photoUrl: String): InlineQueryResult {
        InlineQueryResultBuilder.photo(id, photoUrl, TelegramObject())
    }

    public static func photo(id: String, photoUrl: String, options: TelegramObject): InlineQueryResult {
        let object = typed("photo", id)
        object.addString("photo_url", photoUrl)
        object.addString("thumbnail_url", photoUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func photoCached(id: String, photoFileId: String): InlineQueryResult {
        InlineQueryResultBuilder.photoCached(id, photoFileId, TelegramObject())
    }

    public static func photoCached(id: String, photoFileId: String, options: TelegramObject): InlineQueryResult {
        let object = typed("photo", id)
        object.addString("photo_file_id", photoFileId)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func stickerCached(id: String, stickerFileId: String): InlineQueryResult {
        InlineQueryResultBuilder.stickerCached(id, stickerFileId, TelegramObject())
    }

    public static func stickerCached(id: String, stickerFileId: String, options: TelegramObject): InlineQueryResult {
        let object = typed("sticker", id)
        object.addString("sticker_file_id", stickerFileId)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func venue(
        id: String,
        title: String,
        latitude: Float64,
        longitude: Float64,
        address: String
    ): InlineQueryResult {
        InlineQueryResultBuilder.venue(id, title, latitude, longitude, address, TelegramObject())
    }

    public static func venue(
        id: String,
        title: String,
        latitude: Float64,
        longitude: Float64,
        address: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("venue", id)
        object.addString("title", title)
        object.addFloat("latitude", latitude)
        object.addFloat("longitude", longitude)
        object.addString("address", address)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func videoHtml(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String
    ): InlineQueryResult {
        InlineQueryResultBuilder.videoHtml(id, title, videoUrl, thumbnailUrl, TelegramObject())
    }

    public static func videoHtml(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = TelegramObject()
        object.addString("type", "video")
        object.addString("mime_type", "text/html")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("video_url", videoUrl)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func videoMp4(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String
    ): InlineQueryResult {
        InlineQueryResultBuilder.videoMp4(id, title, videoUrl, thumbnailUrl, TelegramObject())
    }

    public static func videoMp4(
        id: String,
        title: String,
        videoUrl: String,
        thumbnailUrl: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = TelegramObject()
        object.addString("type", "video")
        object.addString("mime_type", "video/mp4")
        object.addString("id", id)
        object.addString("title", title)
        object.addString("video_url", videoUrl)
        object.addString("thumbnail_url", thumbnailUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func videoCached(id: String, title: String, videoFileId: String): InlineQueryResult {
        InlineQueryResultBuilder.videoCached(id, title, videoFileId, TelegramObject())
    }

    public static func videoCached(
        id: String,
        title: String,
        videoFileId: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("video", id)
        object.addString("title", title)
        object.addString("video_file_id", videoFileId)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func voice(id: String, title: String, voiceUrl: String): InlineQueryResult {
        InlineQueryResultBuilder.voice(id, title, voiceUrl, TelegramObject())
    }

    public static func voice(id: String, title: String, voiceUrl: String, options: TelegramObject): InlineQueryResult {
        let object = typed("voice", id)
        object.addString("title", title)
        object.addString("voice_url", voiceUrl)
        object.addAll(options)
        InlineQueryResult(object)
    }

    public static func voiceCached(id: String, title: String, voiceFileId: String): InlineQueryResult {
        InlineQueryResultBuilder.voiceCached(id, title, voiceFileId, TelegramObject())
    }

    public static func voiceCached(
        id: String,
        title: String,
        voiceFileId: String,
        options: TelegramObject
    ): InlineQueryResult {
        let object = typed("voice", id)
        object.addString("title", title)
        object.addString("voice_file_id", voiceFileId)
        object.addAll(options)
        InlineQueryResult(object)
    }
}

private func typed(kind: String, id: String): TelegramObject {
    let object = TelegramObject()
    object.addString("type", kind)
    object.addString("id", id)
    object
}
