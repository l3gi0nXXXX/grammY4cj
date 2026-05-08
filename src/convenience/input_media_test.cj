package grammy4cj.convenience

import grammy4cj.types.InputFile
import std.unittest.*

@Test
public class InputMediaBuilderTest {
    @TestCase
    public func upstream001BuildsPhotosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "photo caption")
        let photo = InputMediaBuilder.photo(InputFile.fromBytes("ABC", "photo.jpg"), options)

        @Expect(photo.toJSON(), "{\"type\":\"photo\",\"media\":\"attach://media\",\"caption\":\"photo caption\"}")
        @Expect(photo.hasMediaFile(), true)
        @Expect(photo.inputFile().filename, "photo.jpg")
        @Expect(photo.toJSON().contains("source_kind"), false)
        let fromFileId = InputMediaBuilder.photo("file-id", options)
        @Expect(fromFileId.schemaIsValid(), true)
        @Expect(fromFileId.toTelegramObject().stringField("caption"), "photo caption")
        @Expect(fromFileId.hasMediaFile(), false)
    }

    @TestCase
    public func upstream002BuildsVideosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "video caption")

        @Expect(
            InputMediaBuilder.video(InputFile.fromBytes("ABC", "video.mp4"), options).toJSON(),
            "{\"type\":\"video\",\"media\":\"attach://media\",\"caption\":\"video caption\"}"
        )
        let thumbnailOptions = TelegramObject()
        thumbnailOptions.addString("thumbnail", "attach://thumb")
        let withThumbnail = InputMediaBuilder.video("video-file-id", thumbnailOptions)
        @Expect(withThumbnail.schemaIsValid(), true)
        @Expect(withThumbnail.toTelegramObject().stringField("thumbnail"), "attach://thumb")
    }

    @TestCase
    public func upstream003BuildsAnimationsGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "animation caption")

        @Expect(
            InputMediaBuilder.animation(InputFile.fromBytes("ABC", "animation.gif"), options).toJSON(),
            "{\"type\":\"animation\",\"media\":\"attach://media\",\"caption\":\"animation caption\"}"
        )
        @Expect(InputMediaBuilder.animation("animation-file-id", options).schemaIsValid(), true)
    }

    @TestCase
    public func upstream004BuildsAudiosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "audio caption")

        @Expect(
            InputMediaBuilder.audio(InputFile.fromBytes("ABC", "audio.ogg"), options).toJSON(),
            "{\"type\":\"audio\",\"media\":\"attach://media\",\"caption\":\"audio caption\"}"
        )
        let audioOptions = TelegramObject()
        audioOptions.addString("performer", "grammY")
        audioOptions.addString("title", "song")
        @Expect(InputMediaBuilder.audio("audio-file-id", audioOptions).schemaIsValid(), true)
    }

    @TestCase
    public func upstream005BuildsDocumentsGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "document caption")

        @Expect(
            InputMediaBuilder.document(InputFile.fromBytes("ABC", "document.pdf"), options).toJSON(),
            "{\"type\":\"document\",\"media\":\"attach://media\",\"caption\":\"document caption\"}"
        )
        let documentOptions = TelegramObject()
        documentOptions.addBool("disable_content_type_detection", true)
        @Expect(InputMediaBuilder.document("document-file-id", documentOptions).schemaIsValid(), true)
    }
}
