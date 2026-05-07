package grammy4cj.convenience

import std.unittest.*

@Test
public class InlineQueryResultBuilderTest {
    @TestCase
    public func allInlineQueryResultBuildersEmitGoldenObjects(): Unit {
        let textOptions = TelegramObject()
        textOptions.addString("parse_mode", "HTML")

        let golden =
            InlineQueryResultBuilder.article("article", "Article").text("Article body", textOptions).toJSON() + "\n" +
            InlineQueryResultBuilder.audio("audio", "Audio", "https://example.test/audio.mp3").toJSON() + "\n" +
            InlineQueryResultBuilder.audioCached("audio-cached", "audio-file-id").toJSON() + "\n" +
            InlineQueryResultBuilder.contact("contact", "+100000000", "Ada").toJSON() + "\n" +
            InlineQueryResultBuilder.documentPdf("pdf", "PDF", "https://example.test/file.pdf").toJSON() + "\n" +
            InlineQueryResultBuilder.documentZip("zip", "ZIP", "https://example.test/file.zip").toJSON() + "\n" +
            InlineQueryResultBuilder.documentCached("doc-cached", "Doc", "document-file-id").toJSON() + "\n" +
            InlineQueryResultBuilder.game("game", "short-game").toJSON() + "\n" +
            InlineQueryResultBuilder.gif("gif", "https://example.test/a.gif", "https://example.test/thumb.jpg").toJSON() + "\n" +
            InlineQueryResultBuilder.gifCached("gif-cached", "gif-file-id").toJSON() + "\n" +
            InlineQueryResultBuilder.location("location", "Place", 1.25, 2.5).toJSON() + "\n" +
            InlineQueryResultBuilder.mpeg4gif("mpeg4", "https://example.test/a.mp4", "https://example.test/t.jpg").toJSON() + "\n" +
            InlineQueryResultBuilder.mpeg4gifCached("mpeg4-cached", "mpeg4-file-id").toJSON() + "\n" +
            InlineQueryResultBuilder.photo("photo", "https://example.test/photo.jpg").toJSON() + "\n" +
            InlineQueryResultBuilder.photoCached("photo-cached", "photo-file-id").toJSON() + "\n" +
            InlineQueryResultBuilder.stickerCached("sticker-cached", "sticker-file-id").toJSON() + "\n" +
            InlineQueryResultBuilder.venue("venue", "Venue", 3.25, 4.5, "Main Street").toJSON() + "\n" +
            InlineQueryResultBuilder.videoHtml("video-html", "HTML", "https://example.test/player", "https://example.test/v.jpg").text("HTML fallback").toJSON() + "\n" +
            InlineQueryResultBuilder.videoMp4("video-mp4", "MP4", "https://example.test/video.mp4", "https://example.test/v.jpg").toJSON() + "\n" +
            InlineQueryResultBuilder.videoCached("video-cached", "Video", "video-file-id").toJSON() + "\n" +
            InlineQueryResultBuilder.voice("voice", "Voice", "https://example.test/voice.ogg").toJSON() + "\n" +
            InlineQueryResultBuilder.voiceCached("voice-cached", "Voice", "voice-file-id").toJSON()

        @Expect(
            golden,
            "{\"type\":\"article\",\"id\":\"article\",\"title\":\"Article\",\"input_message_content\":{\"message_text\":\"Article body\",\"parse_mode\":\"HTML\"}}\n" +
                "{\"type\":\"audio\",\"id\":\"audio\",\"title\":\"Audio\",\"audio_url\":\"https://example.test/audio.mp3\"}\n" +
                "{\"type\":\"audio\",\"id\":\"audio-cached\",\"audio_file_id\":\"audio-file-id\"}\n" +
                "{\"type\":\"contact\",\"id\":\"contact\",\"phone_number\":\"+100000000\",\"first_name\":\"Ada\"}\n" +
                "{\"type\":\"document\",\"mime_type\":\"application/pdf\",\"id\":\"pdf\",\"title\":\"PDF\",\"document_url\":\"https://example.test/file.pdf\"}\n" +
                "{\"type\":\"document\",\"mime_type\":\"application/zip\",\"id\":\"zip\",\"title\":\"ZIP\",\"document_url\":\"https://example.test/file.zip\"}\n" +
                "{\"type\":\"document\",\"id\":\"doc-cached\",\"title\":\"Doc\",\"document_file_id\":\"document-file-id\"}\n" +
                "{\"type\":\"game\",\"id\":\"game\",\"game_short_name\":\"short-game\"}\n" +
                "{\"type\":\"gif\",\"id\":\"gif\",\"gif_url\":\"https://example.test/a.gif\",\"thumbnail_url\":\"https://example.test/thumb.jpg\"}\n" +
                "{\"type\":\"gif\",\"id\":\"gif-cached\",\"gif_file_id\":\"gif-file-id\"}\n" +
                "{\"type\":\"location\",\"id\":\"location\",\"title\":\"Place\",\"latitude\":1.250000,\"longitude\":2.500000}\n" +
                "{\"type\":\"mpeg4_gif\",\"id\":\"mpeg4\",\"mpeg4_url\":\"https://example.test/a.mp4\",\"thumbnail_url\":\"https://example.test/t.jpg\"}\n" +
                "{\"type\":\"mpeg4_gif\",\"id\":\"mpeg4-cached\",\"mpeg4_file_id\":\"mpeg4-file-id\"}\n" +
                "{\"type\":\"photo\",\"id\":\"photo\",\"photo_url\":\"https://example.test/photo.jpg\",\"thumbnail_url\":\"https://example.test/photo.jpg\"}\n" +
                "{\"type\":\"photo\",\"id\":\"photo-cached\",\"photo_file_id\":\"photo-file-id\"}\n" +
                "{\"type\":\"sticker\",\"id\":\"sticker-cached\",\"sticker_file_id\":\"sticker-file-id\"}\n" +
                "{\"type\":\"venue\",\"id\":\"venue\",\"title\":\"Venue\",\"latitude\":3.250000,\"longitude\":4.500000,\"address\":\"Main Street\"}\n" +
                "{\"type\":\"video\",\"mime_type\":\"text/html\",\"id\":\"video-html\",\"title\":\"HTML\",\"video_url\":\"https://example.test/player\",\"thumbnail_url\":\"https://example.test/v.jpg\",\"input_message_content\":{\"message_text\":\"HTML fallback\"}}\n" +
                "{\"type\":\"video\",\"mime_type\":\"video/mp4\",\"id\":\"video-mp4\",\"title\":\"MP4\",\"video_url\":\"https://example.test/video.mp4\",\"thumbnail_url\":\"https://example.test/v.jpg\"}\n" +
                "{\"type\":\"video\",\"id\":\"video-cached\",\"title\":\"Video\",\"video_file_id\":\"video-file-id\"}\n" +
                "{\"type\":\"voice\",\"id\":\"voice\",\"title\":\"Voice\",\"voice_url\":\"https://example.test/voice.ogg\"}\n" +
                "{\"type\":\"voice\",\"id\":\"voice-cached\",\"title\":\"Voice\",\"voice_file_id\":\"voice-file-id\"}"
        )
    }
}
