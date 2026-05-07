package grammy4cj.types

import std.unittest.*

@Test
public class TelegramTypesTest {
    @TestCase
    public func apiResponseModelsSuccessAndFailure(): Unit {
        let success = ApiResponse.success("{\"id\":1}")
        let failure = ApiResponse.failure(429, "Too Many Requests", ResponseParameters(0, 3))

        @Expect(success.ok, true)
        @Expect(success.result, "{\"id\":1}")
        @Expect(success.error.errorCode, 0)
        @Expect(failure.ok, false)
        @Expect(failure.error.errorCode, 429)
        @Expect(failure.error.parameters.retryAfter, 3)
    }

    @TestCase
    public func updateUserChatAndMessageKeepTelegramFields(): Unit {
        let user = User(1, false, "Ada", "ada")
        let chat = Chat(2, "private")
        let message = Message(3, chat, "hello")
        let update = Update(4, "message")

        @Expect(user.username, "ada")
        @Expect(message.messageId, 3)
        @Expect(message.chat.kind, "private")
        @Expect(update.kind, "message")
    }
}

@Test
public class InputFileTest {
    @TestCase
    public func inputFileSourcesKeepKindValueAndFilename(): Unit {
        let pathFile = InputFile.fromPath("/tmp/photo.png")
        let urlFile = InputFile.fromUrl("https://example.test/files/report.pdf")
        let bytesFile = InputFile.fromBytes("bytes:3", "data.bin")
        let streamFile = InputFile.fromStream("stream:1", "video.mp4")
        let supplierFile = InputFile.fromSupplier("supplier:1", "voice.ogg")

        @Expect(pathFile.sourceKind, "path")
        @Expect(pathFile.filename, "photo.png")
        @Expect(urlFile.sourceKind, "url")
        @Expect(urlFile.filename, "report.pdf")
        @Expect(bytesFile.sourceValue, "bytes:3")
        @Expect(streamFile.filename, "video.mp4")
        @Expect(supplierFile.sourceKind, "supplier")
    }

    @TestCase
    public func inputFileConsumeMarksSingleUseSources(): Unit {
        let streamFile = InputFile.fromStream("stream:1", "video.mp4")

        @Expect(streamFile.consumed, false)
        streamFile.consume()
        @Expect(streamFile.consumed, true)
    }

    @TestCase
    public func inferFilenameFallsBackToEmptyString(): Unit {
        @Expect(inferFilename("file.txt"), "file.txt")
        @Expect(inferFilename("/tmp/file.txt"), "file.txt")
        @Expect(inferFilename("/tmp/"), "")
    }
}
