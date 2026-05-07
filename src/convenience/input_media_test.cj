package grammy4cj.convenience

import grammy4cj.types.InputFile
import std.unittest.*

@Test
public class InputMediaBuilderTest {
    @TestCase
    public func upstream001BuildsPhotosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "photo caption")

        @Expect(
            InputMediaBuilder.photo(InputFile.fromBytes("ABC", "photo.jpg"), options).toJSON(),
            "{\"type\":\"photo\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"photo.jpg\"},\"caption\":\"photo caption\"}"
        )
        let fromFileId = InputMediaBuilder.photo("file-id", options)
        @Expect(fromFileId.schemaIsValid(), true)
        @Expect(fromFileId.toTelegramObject().stringField("caption"), "photo caption")
    }

    @TestCase
    public func upstream002BuildsVideosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "video caption")

        @Expect(
            InputMediaBuilder.video(InputFile.fromBytes("ABC", "video.mp4"), options).toJSON(),
            "{\"type\":\"video\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"video.mp4\"},\"caption\":\"video caption\"}"
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
            "{\"type\":\"animation\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"animation.gif\"},\"caption\":\"animation caption\"}"
        )
        @Expect(InputMediaBuilder.animation("animation-file-id", options).schemaIsValid(), true)
    }

    @TestCase
    public func upstream004BuildsAudiosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "audio caption")

        @Expect(
            InputMediaBuilder.audio(InputFile.fromBytes("ABC", "audio.ogg"), options).toJSON(),
            "{\"type\":\"audio\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"audio.ogg\"},\"caption\":\"audio caption\"}"
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
            "{\"type\":\"document\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"document.pdf\"},\"caption\":\"document caption\"}"
        )
        let documentOptions = TelegramObject()
        documentOptions.addBool("disable_content_type_detection", true)
        @Expect(InputMediaBuilder.document("document-file-id", documentOptions).schemaIsValid(), true)
    }
}
