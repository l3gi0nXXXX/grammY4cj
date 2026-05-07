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
    }

    @TestCase
    public func upstream002BuildsVideosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "video caption")

        @Expect(
            InputMediaBuilder.video(InputFile.fromBytes("ABC", "video.mp4"), options).toJSON(),
            "{\"type\":\"video\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"video.mp4\"},\"caption\":\"video caption\"}"
        )
    }

    @TestCase
    public func upstream003BuildsAnimationsGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "animation caption")

        @Expect(
            InputMediaBuilder.animation(InputFile.fromBytes("ABC", "animation.gif"), options).toJSON(),
            "{\"type\":\"animation\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"animation.gif\"},\"caption\":\"animation caption\"}"
        )
    }

    @TestCase
    public func upstream004BuildsAudiosGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "audio caption")

        @Expect(
            InputMediaBuilder.audio(InputFile.fromBytes("ABC", "audio.ogg"), options).toJSON(),
            "{\"type\":\"audio\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"audio.ogg\"},\"caption\":\"audio caption\"}"
        )
    }

    @TestCase
    public func upstream005BuildsDocumentsGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "document caption")

        @Expect(
            InputMediaBuilder.document(InputFile.fromBytes("ABC", "document.pdf"), options).toJSON(),
            "{\"type\":\"document\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"ABC\",\"filename\":\"document.pdf\"},\"caption\":\"document caption\"}"
        )
    }
}
