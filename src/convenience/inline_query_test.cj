package grammy4cj.convenience

import std.collection.ArrayList
import std.unittest.*

private func optionString(key: String, value: String): TelegramObject {
    let options = TelegramObject()
    options.addString(key, value)
    options
}

private func caption(value: String): TelegramObject {
    optionString("caption", value)
}

private func markdown(): TelegramObject {
    optionString("parse_mode", "Markdown")
}

private func heading(): TelegramObject {
    let options = TelegramObject()
    options.addInt("heading", 1)
    options
}

private func venueProvider(): TelegramObject {
    optionString("foursquare_id", "grammy-foursquare-id")
}

private func contactLastName(): TelegramObject {
    optionString("last_name", "Doe")
}

private func invoiceNeedName(): TelegramObject {
    let options = TelegramObject()
    options.addBool("need_name", true)
    options
}

private func invoicePrices(): ArrayList<TelegramObject> {
    let prices = ArrayList<TelegramObject>()
    let price = TelegramObject()
    price.addInt("amount", 10)
    price.addString("label", "Item 0")
    prices.add(price)
    prices
}

private func replyMarkupOptions(): TelegramObject {
    let markup = TelegramObject()
    markup.addArray("inline_keyboard", arrayValue())
    let options = TelegramObject()
    options.addObject("reply_markup", markup)
    options
}

private func horizontalAccuracy(): TelegramObject {
    let options = TelegramObject()
    options.addInt("horizontal_accuracy", 3)
    options
}

@Test
public class InlineQueryResultBuilderTest {
    @TestCase
    public func upstream001ArticleFromStringGolden(): Unit {
        let missingContent: InlineQueryResultArticle = InlineQueryResultBuilder.article("id", "title")
        let result = InlineQueryResultBuilder.article("id", "title", optionString("description", "description")).text("text")
        @Expect(missingContent.schemaIsValid(), false)
        @Expect(
            result.toJSON(),
            "{\"type\":\"article\",\"id\":\"id\",\"title\":\"title\",\"description\":\"description\",\"input_message_content\":{\"message_text\":\"text\"}}"
        )
        @Expect(result.schemaIsValid(), true)
        @Expect(result.toTelegramObject().hasField("input_message_content"), true)
    }

    @TestCase
    public func upstream002AudioFromStringGolden(): Unit {
        let result: InlineQueryResultAudio = InlineQueryResultBuilder.audio("id", "title", "https://grammy.dev/", caption("cap"))
        @Expect(
            result.toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"title\":\"title\",\"audio_url\":\"https://grammy.dev/\",\"caption\":\"cap\"}"
        )
        @Expect(result.schemaIsValid(), true)
        @Expect(result.toTelegramObject().hasField("audio_url"), true)
    }

    @TestCase
    public func upstream003AudioFromUrlValueGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.audio("id", "title", "https://grammy.dev/", caption("cap")).toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"title\":\"title\",\"audio_url\":\"https://grammy.dev/\",\"caption\":\"cap\"}"
        )
    }

    @TestCase
    public func upstream004AudioWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.audio("id", "title", "https://grammy.dev/", caption("cap")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"title\":\"title\",\"audio_url\":\"https://grammy.dev/\",\"caption\":\"cap\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream005AudioWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.audio("id", "title", "https://grammy.dev/", caption("cap")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"title\":\"title\",\"audio_url\":\"https://grammy.dev/\",\"caption\":\"cap\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream006AudioWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.audio("id", "title", "https://grammy.dev/", caption("cap")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"title\":\"title\",\"audio_url\":\"https://grammy.dev/\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream007AudioWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.audio("id", "title", "https://grammy.dev/", caption("cap")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"title\":\"title\",\"audio_url\":\"https://grammy.dev/\",\"caption\":\"cap\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream008AudioWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.audio("id", "title", "https://grammy.dev/", caption("cap")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"title\":\"title\",\"audio_url\":\"https://grammy.dev/\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream009CachedAudioGolden(): Unit {
        let result: InlineQueryResultCachedAudio = InlineQueryResultBuilder.audioCached("id", "file_id", caption("my cached audio"))
        @Expect(
            result.toJSON(),
            "{\"type\":\"audio\",\"id\":\"id\",\"audio_file_id\":\"file_id\",\"caption\":\"my cached audio\"}"
        )
        @Expect(result.schemaIsValid(), true)
        @Expect(result.toTelegramObject().hasField("audio_file_id"), true)
    }

    @TestCase
    public func inlineQueryBuildersReturnConcreteTypedModels(): Unit {
        let photo: InlineQueryResultPhoto = InlineQueryResultBuilder.photo("id", "https://grammy.dev/")
        let video: InlineQueryResultVideo = InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/video", "https://grammy.dev/thumb")
        let cached: InlineQueryResultCachedSticker = InlineQueryResultBuilder.stickerCached("id", "sticker-id")

        @Expect(photo.toTelegramObject().stringField("type"), "photo")
        @Expect(photo.toTelegramObject().stringField("thumbnail_url"), "https://grammy.dev/")
        @Expect(video.toTelegramObject().stringField("mime_type"), "video/mp4")
        @Expect(cached.toTelegramObject().stringField("sticker_file_id"), "sticker-id")
    }

    @TestCase
    public func upstream010ContactGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.contact("id", "phone", "first", optionString("last_name", "last")).toJSON(),
            "{\"type\":\"contact\",\"id\":\"id\",\"phone_number\":\"phone\",\"first_name\":\"first\",\"last_name\":\"last\"}"
        )
    }

    @TestCase
    public func upstream011ContactWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.contact("id", "phone", "first", optionString("last_name", "last")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"contact\",\"id\":\"id\",\"phone_number\":\"phone\",\"first_name\":\"first\",\"last_name\":\"last\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream012ContactWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.contact("id", "phone", "first", optionString("last_name", "last")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"contact\",\"id\":\"id\",\"phone_number\":\"phone\",\"first_name\":\"first\",\"last_name\":\"last\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream013ContactWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.contact("id", "phone", "first", optionString("last_name", "last")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"contact\",\"id\":\"id\",\"phone_number\":\"phone\",\"first_name\":\"first\",\"last_name\":\"last\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream014ContactWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.contact("id", "phone", "first", optionString("last_name", "last")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"contact\",\"id\":\"id\",\"phone_number\":\"phone\",\"first_name\":\"first\",\"last_name\":\"last\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream015ContactWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.contact("id", "phone", "first", optionString("last_name", "last")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"contact\",\"id\":\"id\",\"phone_number\":\"phone\",\"first_name\":\"first\",\"last_name\":\"last\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream016DocumentPdfFromStringGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentPdf("id", "title", "https://grammy.dev/", caption("captain")).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\"}"
        )
    }

    @TestCase
    public func upstream017DocumentPdfFromUrlValueGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentPdf("id", "title", "https://grammy.dev/", caption("morgan")).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"morgan\"}"
        )
    }

    @TestCase
    public func upstream018DocumentPdfWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentPdf("id", "title", "https://grammy.dev/", caption("captain")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream019DocumentPdfWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentPdf("id", "title", "https://grammy.dev/", caption("captain")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream020DocumentPdfWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentPdf("id", "title", "https://grammy.dev/", caption("captain")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream021DocumentPdfWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentPdf("id", "title", "https://grammy.dev/", caption("captain")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream022DocumentPdfWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentPdf("id", "title", "https://grammy.dev/", caption("captain")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream023DocumentZipFromStringGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentZip("id", "title", "https://grammy.dev/", caption("captain")).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\"}"
        )
    }

    @TestCase
    public func upstream024DocumentZipFromUrlValueGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentZip("id", "title", "https://grammy.dev/", caption("morgan")).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"morgan\"}"
        )
    }

    @TestCase
    public func upstream025DocumentZipWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentZip("id", "title", "https://grammy.dev/", caption("captain")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream026DocumentZipWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentZip("id", "title", "https://grammy.dev/", caption("captain")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream027DocumentZipWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentZip("id", "title", "https://grammy.dev/", caption("captain")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream028DocumentZipWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentZip("id", "title", "https://grammy.dev/", caption("captain")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream029DocumentZipWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentZip("id", "title", "https://grammy.dev/", caption("captain")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"id\",\"title\":\"title\",\"document_url\":\"https://grammy.dev/\",\"caption\":\"captain\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream030DocumentCachedGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.documentCached("id", "title", "file_id", caption("c")).toJSON(),
            "{\"type\":\"document\",\"id\":\"id\",\"title\":\"title\",\"document_file_id\":\"file_id\",\"caption\":\"c\"}"
        )
    }

    @TestCase
    public func upstream031GameGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.game("id", "game", replyMarkupOptions()).toJSON(),
            "{\"type\":\"game\",\"id\":\"id\",\"game_short_name\":\"game\",\"reply_markup\":{\"inline_keyboard\":[]}}"
        )
    }

    @TestCase
    public func upstream032GifFromStringsGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("It's pronounced GIF.")).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"It's pronounced GIF.\"}"
        )
    }

    @TestCase
    public func upstream033GifFromUrlValuesGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("It's pronounced GIF.")).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"It's pronounced GIF.\"}"
        )
    }

    @TestCase
    public func upstream034GifWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("It's pronounced GIF.")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"It's pronounced GIF.\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream035GifWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("It's pronounced GIF.")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"It's pronounced GIF.\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream036GifWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("It's pronounced GIF.")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"It's pronounced GIF.\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream037GifWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("It's pronounced GIF.")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"It's pronounced GIF.\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream038GifWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("It's pronounced GIF.")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"It's pronounced GIF.\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream039GifCachedGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.gifCached("id", "file_id", caption("cappy")).toJSON(),
            "{\"type\":\"gif\",\"id\":\"id\",\"gif_file_id\":\"file_id\",\"caption\":\"cappy\"}"
        )
    }

    @TestCase
    public func upstream040LocationGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.location("id", "title", 54.0, 10.0, horizontalAccuracy()).toJSON(),
            "{\"type\":\"location\",\"id\":\"id\",\"title\":\"title\",\"latitude\":54.000000,\"longitude\":10.000000,\"horizontal_accuracy\":3}"
        )
    }

    @TestCase
    public func upstream041LocationWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.location("id", "title", 54.0, 10.0, horizontalAccuracy()).text("#Text", markdown()).toJSON(),
            "{\"type\":\"location\",\"id\":\"id\",\"title\":\"title\",\"latitude\":54.000000,\"longitude\":10.000000,\"horizontal_accuracy\":3,\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream042LocationWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.location("id", "title", 54.0, 10.0, horizontalAccuracy()).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"location\",\"id\":\"id\",\"title\":\"title\",\"latitude\":54.000000,\"longitude\":10.000000,\"horizontal_accuracy\":3,\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream043LocationWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.location("id", "title", 54.0, 10.0, horizontalAccuracy()).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"location\",\"id\":\"id\",\"title\":\"title\",\"latitude\":54.000000,\"longitude\":10.000000,\"horizontal_accuracy\":3,\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream044LocationWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.location("id", "title", 54.0, 10.0, horizontalAccuracy()).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"location\",\"id\":\"id\",\"title\":\"title\",\"latitude\":54.000000,\"longitude\":10.000000,\"horizontal_accuracy\":3,\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream045LocationWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.location("id", "title", 54.0, 10.0, horizontalAccuracy()).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"location\",\"id\":\"id\",\"title\":\"title\",\"latitude\":54.000000,\"longitude\":10.000000,\"horizontal_accuracy\":3,\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream046Mpeg4GifFromStringsGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\"}"
        )
    }

    @TestCase
    public func upstream047Mpeg4GifFromUrlValuesGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\"}"
        )
    }

    @TestCase
    public func upstream048Mpeg4GifWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream049Mpeg4GifWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream050Mpeg4GifWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream051Mpeg4GifWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream052Mpeg4GifWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gif("id", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream053Mpeg4GifCachedGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.mpeg4gifCached("id", "file_id", optionString("title", "title")).toJSON(),
            "{\"type\":\"mpeg4_gif\",\"id\":\"id\",\"mpeg4_file_id\":\"file_id\",\"title\":\"title\"}"
        )
    }

    @TestCase
    public func upstream054PhotoFromStringGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/").toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\"}"
        )
    }

    @TestCase
    public func upstream055PhotoFromUrlValueGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/").toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\"}"
        )
    }

    @TestCase
    public func upstream056PhotoDefaultsThumbnailGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/", caption("cap")).toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\",\"caption\":\"cap\"}"
        )
    }

    @TestCase
    public func upstream057PhotoExplicitThumbnailOverridesDefaultGolden(): Unit {
        let result = InlineQueryResultBuilder.photo("id", "https://grammy.dev/", optionString("thumbnail_url", "https://grammy.dev/thumb"))
        @Expect(
            result.toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\"}"
        )
        @Expect(result.schemaIsValid(), true)
        @Expect(result.toTelegramObject().stringField("thumbnail_url"), "https://grammy.dev/thumb")
    }

    @TestCase
    public func upstream058PhotoWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/").text("#Text", markdown()).toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream059PhotoWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/").location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream060PhotoWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/").venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream061PhotoWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/").contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream062PhotoWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photo("id", "https://grammy.dev/").invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream063PhotoCachedGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.photoCached("id", "file_id", caption("#pic")).toJSON(),
            "{\"type\":\"photo\",\"id\":\"id\",\"photo_file_id\":\"file_id\",\"caption\":\"#pic\"}"
        )
    }

    @TestCase
    public func upstream064StickerCachedGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.stickerCached("id", "file_id", replyMarkupOptions()).toJSON(),
            "{\"type\":\"sticker\",\"id\":\"id\",\"sticker_file_id\":\"file_id\",\"reply_markup\":{\"inline_keyboard\":[]}}"
        )
    }

    @TestCase
    public func upstream065StickerCachedWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.stickerCached("id", "file_id", replyMarkupOptions()).text("#Text", markdown()).toJSON(),
            "{\"type\":\"sticker\",\"id\":\"id\",\"sticker_file_id\":\"file_id\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream066StickerCachedWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.stickerCached("id", "file_id", replyMarkupOptions()).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"sticker\",\"id\":\"id\",\"sticker_file_id\":\"file_id\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream067StickerCachedWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.stickerCached("id", "file_id", replyMarkupOptions()).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"sticker\",\"id\":\"id\",\"sticker_file_id\":\"file_id\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream068StickerCachedWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.stickerCached("id", "file_id", replyMarkupOptions()).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"sticker\",\"id\":\"id\",\"sticker_file_id\":\"file_id\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream069StickerCachedWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.stickerCached("id", "file_id", replyMarkupOptions()).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"sticker\",\"id\":\"id\",\"sticker_file_id\":\"file_id\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream070VenueGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.venue("id", "grammY HQ", 54.0, 10.0, "grammY Street 1", replyMarkupOptions()).toJSON(),
            "{\"type\":\"venue\",\"id\":\"id\",\"title\":\"grammY HQ\",\"latitude\":54.000000,\"longitude\":10.000000,\"address\":\"grammY Street 1\",\"reply_markup\":{\"inline_keyboard\":[]}}"
        )
    }

    @TestCase
    public func upstream071VenueWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.venue("id", "grammY HQ", 54.0, 10.0, "grammY Street 1", replyMarkupOptions()).text("#Text", markdown()).toJSON(),
            "{\"type\":\"venue\",\"id\":\"id\",\"title\":\"grammY HQ\",\"latitude\":54.000000,\"longitude\":10.000000,\"address\":\"grammY Street 1\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream072VenueWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.venue("id", "grammY HQ", 54.0, 10.0, "grammY Street 1", replyMarkupOptions()).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"venue\",\"id\":\"id\",\"title\":\"grammY HQ\",\"latitude\":54.000000,\"longitude\":10.000000,\"address\":\"grammY Street 1\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream073VenueWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.venue("id", "grammY HQ", 54.0, 10.0, "grammY Street 1", replyMarkupOptions()).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"venue\",\"id\":\"id\",\"title\":\"grammY HQ\",\"latitude\":54.000000,\"longitude\":10.000000,\"address\":\"grammY Street 1\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream074VenueWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.venue("id", "grammY HQ", 54.0, 10.0, "grammY Street 1", replyMarkupOptions()).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"venue\",\"id\":\"id\",\"title\":\"grammY HQ\",\"latitude\":54.000000,\"longitude\":10.000000,\"address\":\"grammY Street 1\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream075VenueWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.venue("id", "grammY HQ", 54.0, 10.0, "grammY Street 1", replyMarkupOptions()).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"venue\",\"id\":\"id\",\"title\":\"grammY HQ\",\"latitude\":54.000000,\"longitude\":10.000000,\"address\":\"grammY Street 1\",\"reply_markup\":{\"inline_keyboard\":[]},\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream076VideoHtmlFromStringsGolden(): Unit {
        let missingContent = InlineQueryResultBuilder.videoHtml("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap"))
        let result = InlineQueryResultBuilder.videoHtml("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).text("#Text", markdown())
        @Expect(missingContent.schemaIsValid(), false)
        @Expect(
            result.toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"text/html\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
        @Expect(result.schemaIsValid(), true)
        @Expect(result.toTelegramObject().hasField("input_message_content"), true)
    }

    @TestCase
    public func upstream077VideoHtmlFromUrlValuesGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoHtml("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"text/html\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream078VideoHtmlWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoHtml("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"text/html\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream079VideoHtmlWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoHtml("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"text/html\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream080VideoHtmlWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoHtml("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"text/html\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream081VideoHtmlWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoHtml("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"text/html\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream082VideoMp4FromStringsGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\"}"
        )
    }

    @TestCase
    public func upstream083VideoMp4FromUrlValuesGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\"}"
        )
    }

    @TestCase
    public func upstream084VideoMp4WithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream085VideoMp4WithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream086VideoMp4WithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream087VideoMp4WithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream088VideoMp4WithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoMp4("id", "title", "https://grammy.dev/", "https://grammy.dev/thumb", caption("cap")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"id\",\"title\":\"title\",\"video_url\":\"https://grammy.dev/\",\"thumbnail_url\":\"https://grammy.dev/thumb\",\"caption\":\"cap\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream089VideoCachedGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.videoCached("id", "title", "file_id", caption("c")).toJSON(),
            "{\"type\":\"video\",\"id\":\"id\",\"title\":\"title\",\"video_file_id\":\"file_id\",\"caption\":\"c\"}"
        )
    }

    @TestCase
    public func upstream090VoiceFromStringGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voice("id", "title", "https://grammy.dev/", caption("voice caption? wtf")).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_url\":\"https://grammy.dev/\",\"caption\":\"voice caption? wtf\"}"
        )
    }

    @TestCase
    public func upstream091VoiceFromUrlValueGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voice("id", "title", "https://grammy.dev/", caption("voice caption? wtf")).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_url\":\"https://grammy.dev/\",\"caption\":\"voice caption? wtf\"}"
        )
    }

    @TestCase
    public func upstream092VoiceWithTextContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voice("id", "title", "https://grammy.dev/", caption("voice caption? wtf")).text("#Text", markdown()).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_url\":\"https://grammy.dev/\",\"caption\":\"voice caption? wtf\",\"input_message_content\":{\"message_text\":\"#Text\",\"parse_mode\":\"Markdown\"}}"
        )
    }

    @TestCase
    public func upstream093VoiceWithLocationContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voice("id", "title", "https://grammy.dev/", caption("voice caption? wtf")).location(83.0, 136.0, heading()).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_url\":\"https://grammy.dev/\",\"caption\":\"voice caption? wtf\",\"input_message_content\":{\"latitude\":83.000000,\"longitude\":136.000000,\"heading\":1}}"
        )
    }

    @TestCase
    public func upstream094VoiceWithVenueContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voice("id", "title", "https://grammy.dev/", caption("voice caption? wtf")).venue("grammY Venue", 83.0, 136.0, "1 grammY Venue", venueProvider()).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_url\":\"https://grammy.dev/\",\"caption\":\"voice caption? wtf\",\"input_message_content\":{\"title\":\"grammY Venue\",\"latitude\":83.000000,\"longitude\":136.000000,\"address\":\"1 grammY Venue\",\"foursquare_id\":\"grammy-foursquare-id\"}}"
        )
    }

    @TestCase
    public func upstream095VoiceWithContactContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voice("id", "title", "https://grammy.dev/", caption("voice caption? wtf")).contact("John", "498963648018", contactLastName()).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_url\":\"https://grammy.dev/\",\"caption\":\"voice caption? wtf\",\"input_message_content\":{\"first_name\":\"John\",\"phone_number\":\"498963648018\",\"last_name\":\"Doe\"}}"
        )
    }

    @TestCase
    public func upstream096VoiceWithInvoiceContentGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voice("id", "title", "https://grammy.dev/", caption("voice caption? wtf")).invoice("Invoice", "Invoice Description", "Payload", "Token", "Currency", invoicePrices(), invoiceNeedName()).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_url\":\"https://grammy.dev/\",\"caption\":\"voice caption? wtf\",\"input_message_content\":{\"title\":\"Invoice\",\"description\":\"Invoice Description\",\"payload\":\"Payload\",\"provider_token\":\"Token\",\"currency\":\"Currency\",\"prices\":[{\"amount\":10,\"label\":\"Item 0\"}],\"need_name\":true}}"
        )
    }

    @TestCase
    public func upstream097VoiceCachedGolden(): Unit {
        @Expect(
            InlineQueryResultBuilder.voiceCached("id", "title", "file_id", caption("capped")).toJSON(),
            "{\"type\":\"voice\",\"id\":\"id\",\"title\":\"title\",\"voice_file_id\":\"file_id\",\"caption\":\"capped\"}"
        )
    }
}
