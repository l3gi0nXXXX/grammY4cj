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

    @TestCase
    public func inputMediaBuildersAcceptInputFilesForEveryKindGolden(): Unit {
        let options = TelegramObject()
        options.addString("caption", "file caption")

        let golden = InputMediaBuilder.photo(InputFile.fromBytes("photo-bytes", "photo.jpg"), options).toJSON() + "\n" +
            InputMediaBuilder.video(InputFile.fromPath("/tmp/video.mp4"), options).toJSON() + "\n" +
            InputMediaBuilder.animation(InputFile.fromUrl("https://example.test/a.gif"), options).toJSON() + "\n" +
            InputMediaBuilder.audio(InputFile.fromStream("audio-stream", "audio.ogg"), options).toJSON() + "\n" +
            InputMediaBuilder.document(InputFile.fromSupplier("document-supplier", "document.pdf"), options).toJSON()

        @Expect(
            golden,
            "{\"type\":\"photo\",\"media\":{\"source_kind\":\"bytes\",\"source_value\":\"photo-bytes\",\"filename\":\"photo.jpg\"},\"caption\":\"file caption\"}\n" +
                "{\"type\":\"video\",\"media\":{\"source_kind\":\"path\",\"source_value\":\"/tmp/video.mp4\",\"filename\":\"video.mp4\"},\"caption\":\"file caption\"}\n" +
                "{\"type\":\"animation\",\"media\":{\"source_kind\":\"url\",\"source_value\":\"https://example.test/a.gif\",\"filename\":\"a.gif\"},\"caption\":\"file caption\"}\n" +
                "{\"type\":\"audio\",\"media\":{\"source_kind\":\"stream\",\"source_value\":\"audio-stream\",\"filename\":\"audio.ogg\"},\"caption\":\"file caption\"}\n" +
                "{\"type\":\"document\",\"media\":{\"source_kind\":\"supplier\",\"source_value\":\"document-supplier\",\"filename\":\"document.pdf\"},\"caption\":\"file caption\"}"
        )
    }
}
