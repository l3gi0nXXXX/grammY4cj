package grammy4cj.convenience

import grammy4cj.types.InputFile
import std.unittest.*

@Test
public class InputMediaBuilderTest {
    @TestCase
    public func inputMediaBuildersEmitGoldenObjects(): Unit {
        let photoOptions = TelegramObject()
        photoOptions.addString("caption", "photo caption")
        photoOptions.addString("parse_mode", "Markdown")

        let videoOptions = TelegramObject()
        videoOptions.addBool("supports_streaming", true)
        videoOptions.addInt("duration", 10)

        let animationOptions = TelegramObject()
        animationOptions.addString("thumbnail", "thumb-file-id")

        let audioOptions = TelegramObject()
        audioOptions.addString("performer", "Ada")
        audioOptions.addString("title", "Song")

        let documentOptions = TelegramObject()
        documentOptions.addBool("disable_content_type_detection", true)

        let golden = InputMediaBuilder.photo("photo-file-id", photoOptions).toJSON() + "\n" +
            InputMediaBuilder.video(InputFile.fromBytes("video-bytes", "clip.mp4"), videoOptions).toJSON() + "\n" +
            InputMediaBuilder.animation("animation-file-id", animationOptions).toJSON() + "\n" +
            InputMediaBuilder.audio("audio-file-id", audioOptions).toJSON() + "\n" +
            InputMediaBuilder.document("document-file-id", documentOptions).toJSON()

        @Expect(
            golden,
            "{\"type\":\"photo\",\"media\":\"photo-file-id\",\"caption\":\"photo caption\",\"parse_mode\":\"Markdown\"}\n" +
                "{\"type\":\"video\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"video-bytes\",\"filename\":\"clip.mp4\"},\"supports_streaming\":true,\"duration\":10}\n" +
                "{\"type\":\"animation\",\"media\":\"animation-file-id\",\"thumbnail\":\"thumb-file-id\"}\n" +
                "{\"type\":\"audio\",\"media\":\"audio-file-id\",\"performer\":\"Ada\",\"title\":\"Song\"}\n" +
                "{\"type\":\"document\",\"media\":\"document-file-id\",\"disable_content_type_detection\":true}"
        )
    }
}
