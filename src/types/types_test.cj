package grammy4cj.types

import std.unittest.*

private func toJsonErrorMessage(file: InputFile): String {
    var message = ""
    try {
        file.toJSON()
    } catch (e: Exception) {
        message = e.message
    }
    message
}

private func toRawErrorMessage(file: InputFile): String {
    var message = ""
    try {
        file.toRaw()
    } catch (e: Exception) {
        message = e.message
    }
    message
}

private func toRawErrorMessage(file: InputFile, runtime: String): String {
    var message = ""
    try {
        file.toRaw(runtime)
    } catch (e: Exception) {
        message = e.message
    }
    message
}

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

    @TestCase
    public func telegramTypeAliasTraceCoversInputFileBoundExports(): Unit {
        let aliases = telegramInputFileAliasTrace()

        @Expect(telegramInputFileAliasTraceCount(), 18)
        @Expect(aliases.size, 18)
        @Expect(aliases[0].aliasName, "ApiMethods")
        @Expect(aliases[0].upstreamGeneric, "ApiMethodsF<InputFile>")
        @Expect(aliases[1].aliasName, "Opts")
        @Expect(aliases[17].aliasName, "InputStoryContentVideo")
        @Expect(aliases[17].inputFileBinding, "InputFile")
        @Expect(aliases[17].exportedFromDeno, true)
        @Expect(aliases[17].exportedFromNode, true)
        @Expect(aliases[17].exportedFromWeb, true)
    }
}

@Test
public class InputFileTest {
    @TestCase
    public func inputFileSourcesKeepKindValueAndFilename(): Unit {
        let pathFile = InputFile.fromPath("/tmp/photo.png")
        let urlFile = InputFile.fromUrl("https://example.test/files/report.pdf")
        let urlLikeFile = InputFile.fromUrlLike("https://grammy.dev")
        let bytesFile = InputFile.fromBytes("bytes:3", "data.bin")
        let blobFile = InputFile.fromBlob("blob:1", "blob.txt")
        let responseFile = InputFile.fromResponse("response:1", "download.bin")
        let streamFile = InputFile.fromStream("stream:1", "video.mp4")
        let iterableFile = InputFile.fromIterable("iter:1", "chunks.bin")
        let asyncIterableFile = InputFile.fromAsyncIterable("async:1", "async.bin")
        let supplierFile = InputFile.fromSupplier("supplier:1", "voice.ogg")

        @Expect(pathFile.sourceKind, "path")
        @Expect(pathFile.filename, "photo.png")
        @Expect(pathFile.source.rawContract, "deferred-file-read")
        @Expect(pathFile.source.requiresFileAdapter, true)
        @Expect(urlFile.sourceKind, "url")
        @Expect(urlFile.filename, "report.pdf")
        @Expect(urlFile.source.requiresFetchAdapter, true)
        @Expect(urlLikeFile.sourceKind, "url_like")
        @Expect(urlLikeFile.filename, "grammy.dev")
        @Expect(bytesFile.sourceValue, "bytes:3")
        @Expect(bytesFile.source.reusable, true)
        @Expect(blobFile.source.rawContract, "blob-stream")
        @Expect(responseFile.source.rawContract, "response-body")
        @Expect(streamFile.filename, "video.mp4")
        @Expect(streamFile.source.reusable, false)
        @Expect(iterableFile.source.rawContract, "iterator-as-is")
        @Expect(asyncIterableFile.source.rawContract, "async-iterator-as-is")
        @Expect(supplierFile.sourceKind, "supplier")
        @Expect(supplierFile.source.reusable, true)
    }

    @TestCase
    public func inputFileSourceKindsAndRuntimeSupportMirrorUpstreamFacades(): Unit {
        @Expect(inputFileSourceKindCount(), 10)
        @Expect(inputFileRuntimeNames().size, 3)
        @Expect(inputFileRuntimeNames()[0], "deno")
        @Expect(inputFileSourceKindNames()[0], "path")
        @Expect(inputFileSourceKindNames()[9], "supplier")
        @Expect(inputFileSourceSupportedOnRuntime("path", "deno"), true)
        @Expect(inputFileSourceSupportedOnRuntime("path", "node"), true)
        @Expect(inputFileSourceSupportedOnRuntime("path", "web"), false)
        @Expect(inputFileSourceSupportedOnRuntime("blob", "deno"), true)
        @Expect(inputFileSourceSupportedOnRuntime("blob", "node"), false)
        @Expect(inputFileSourceSupportedOnRuntime("blob", "web"), true)
        @Expect(inputFileSourceSupportedOnRuntime("response", "deno"), true)
        @Expect(inputFileSourceSupportedOnRuntime("response", "node"), false)
        @Expect(inputFileSourceSupportedOnRuntime("response", "web"), false)
        @Expect(inputFileSourceSupportedOnRuntime("supplier", "deno"), true)
        @Expect(inputFileSourceSupportedOnRuntime("supplier", "node"), true)
        @Expect(inputFileSourceSupportedOnRuntime("supplier", "web"), false)
        @Expect(inputFileSourceSupportedOnRuntime("bytes", "web"), true)
        @Expect(inputFileSourceSupportedOnRuntime("unknown", "deno"), false)
    }

    @TestCase
    public func inputFileToRawReturnsFakeContractsWithoutIo(): Unit {
        let pathFile = InputFile.fromPath("/tmp/photo.png")
        let urlFile = InputFile.fromUrl("https://example.test/files/report.pdf")
        let bytesFile = InputFile.fromBytes("bytes:3", "data.bin")

        let pathRaw = pathFile.toRaw()
        let urlRaw = urlFile.toRaw()
        let bytesRaw = bytesFile.toRaw()

        @Expect(pathRaw.contract, "deferred-file-read")
        @Expect(pathRaw.requiresFileAdapter, true)
        @Expect(pathFile.consumed, false)
        @Expect(urlRaw.contract, "deferred-fetch")
        @Expect(urlRaw.requiresFetchAdapter, true)
        @Expect(urlFile.consumed, false)
        @Expect(bytesRaw.contract, "bytes-as-is")
        @Expect(bytesRaw.reusable, true)
        @Expect(bytesRaw.summary(), "bytes:bytes-as-is:data.bin")
    }

    @TestCase
    public func inputFileToRawUsesPlatformSpecificRawContracts(): Unit {
        let denoPath = InputFile.fromPath("/tmp/photo.png").toRaw("deno")
        let nodePath = InputFile.fromPath("/tmp/photo.png").toRaw("node")
        let webUrl = InputFile.fromUrl("https://example.test/files/report.pdf").toRaw("web")
        let webBytes = InputFile.fromBytes("bytes:3", "data.bin").toRaw("web")
        let denoStreamFile = InputFile.fromStream("stream:1", "video.mp4")
        let denoStream = denoStreamFile.toRaw("deno")
        let nodeStreamFile = InputFile.fromStream("stream:2", "clip.mp4")
        let nodeStream = nodeStreamFile.toRaw("node")

        @Expect(denoPath.runtime, "deno")
        @Expect(denoPath.rawSourceKind, "path")
        @Expect(denoPath.platformContract, "deno-open-file-async-iterator")
        @Expect(denoPath.platformSummary(), "deno:path:deno-open-file-async-iterator:photo.png")
        @Expect(nodePath.platformContract, "node-create-read-stream")
        @Expect(webUrl.platformContract, "fetch-body-async-iterable")
        @Expect(webBytes.platformContract, "uint8-array-as-is")
        @Expect(denoStream.platformContract, "readable-stream-as-is")
        @Expect(denoStream.singleUseBoundary, true)
        @Expect(denoStreamFile.consumed, true)
        @Expect(nodeStream.platformContract, "node-read-stream-as-is")
        @Expect(nodeStreamFile.consumed, true)
    }

    @TestCase
    public func inputFileSupplierUnwrapsSuppliedSourceAndStaysReusable(): Unit {
        let supplierBytes = InputFile.fromSupplier("lazy-bytes", InputFileSource.bytes("bytes:5", "voice.dat"))
        let denoRaw = supplierBytes.toRaw("deno")
        let nodeRaw = supplierBytes.toRaw("node")
        let supplierStream = InputFile.fromSupplier("lazy-stream", InputFileSource.stream("stream:5", "clip.mp4"))
        let streamRaw = supplierStream.toRaw("node")

        @Expect(denoRaw.sourceKind, "supplier")
        @Expect(denoRaw.rawSourceKind, "bytes")
        @Expect(denoRaw.originalSourceKind, "supplier")
        @Expect(denoRaw.supplierLabel, "lazy-bytes")
        @Expect(denoRaw.platformContract, "uint8-array-as-is")
        @Expect(nodeRaw.platformContract, "uint8-array-as-is")
        @Expect(supplierBytes.consumed, false)
        @Expect(streamRaw.rawSourceKind, "stream")
        @Expect(streamRaw.platformContract, "node-read-stream-as-is")
        @Expect(streamRaw.singleUseBoundary, true)
        @Expect(supplierStream.consumed, false)
    }

    @TestCase
    public func inputFileRejectsUnsupportedRuntimeSources(): Unit {
        @Expect(toRawErrorMessage(InputFile.fromPath("/tmp/photo.png"), "web"), "InputFile source kind 'path' is not supported on web")
        @Expect(toRawErrorMessage(InputFile.fromBlob("blob:1", "a.txt"), "node"), "InputFile source kind 'blob' is not supported on node")
        @Expect(toRawErrorMessage(InputFile.fromResponse("response:1", "a.bin"), "node"), "InputFile source kind 'response' is not supported on node")
        @Expect(toRawErrorMessage(InputFile.fromSupplier("lazy", "a.txt"), "web"), "InputFile source kind 'supplier' is not supported on web")
        @Expect(
            toRawErrorMessage(InputFile.fromSupplier("lazy-blob", InputFileSource.blob("blob:2", "b.txt")), "node"),
            "InputFile supplier source kind 'blob' is not supported on node"
        )
    }

    @TestCase
    public func inputFileToRawMarksSingleUseSources(): Unit {
        let streamFile = InputFile.fromStream("stream:1", "video.mp4")

        @Expect(streamFile.consumed, false)
        let raw = streamFile.toRaw()
        @Expect(raw.contract, "stream-as-is")
        @Expect(streamFile.consumed, true)
        @Expect(toRawErrorMessage(streamFile), "Cannot reuse InputFile data source!")
    }

    @TestCase
    public func inputFileConsumeMarksSourceAsUsed(): Unit {
        let streamFile = InputFile.fromStream("stream:1", "video.mp4")

        streamFile.consume()
        @Expect(streamFile.consumed, true)
        @Expect(toRawErrorMessage(streamFile), "Cannot reuse InputFile data source!")
    }

    @TestCase
    public func inputFileToJsonAlwaysFails(): Unit {
        let file = InputFile.fromBytes("abc", "a.txt")

        @Expect(toJsonErrorMessage(file), "InputFile instances must be sent via grammY")
    }

    @TestCase
    public func inputFileResponseWithoutBodyFails(): Unit {
        let file = InputFile.fromResponse("empty-response", "empty.bin", false)

        @Expect(toRawErrorMessage(file), "No response body!")
    }

    @TestCase
    public func inferFilenameMatchesUpstreamUrlAndPathRules(): Unit {
        @Expect(inferFilename("file.txt"), "file.txt")
        @Expect(inferFilename("/tmp/file.txt"), "file.txt")
        @Expect(inferFilename("/tmp/"), "tmp")
        @Expect(inferFilename("https://grammy.dev/file.txt"), "file.txt")
        @Expect(inferFilename("https://grammy.dev/file.txt?download=1"), "file.txt")
        @Expect(inferFilename("https://grammy.dev"), "grammy.dev")
        @Expect(inferFilename("https://grammy.dev/"), "grammy.dev")
    }
}
