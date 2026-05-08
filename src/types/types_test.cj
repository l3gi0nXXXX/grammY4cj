package grammy4cj.types

import std.unittest.*

private class FakeInputFileRawAdapter {
    public var fileReadCount: Int64 = 0
    public var urlFetchCount: Int64 = 0
    public var streamConsumeCount: Int64 = 0
    public var lastSummary: String = ""

    public init() {}

    public func consume(raw: InputFileRawData): String {
        if (raw.requiresFileAdapter) {
            this.fileReadCount += 1
        }
        if (raw.requiresFetchAdapter) {
            this.urlFetchCount += 1
        }
        if (raw.singleUseBoundary) {
            this.streamConsumeCount += 1
        }
        this.lastSummary = raw.consume()
        this.lastSummary
    }
}

private class FakeFileAdapter <: InputFileFileAdapter {
    public var readCount: Int64 = 0
    public var lastPath: String = ""

    public init() {}

    public func read(path: String): Array<Byte> {
        this.readCount += 1
        this.lastPath = path
        ("file:" + path).toArray()
    }
}

private class FakeFetchAdapter <: InputFileFetchAdapter {
    public var fetchCount: Int64 = 0
    public var lastUrl: String = ""
    public var responseBody: Array<Byte> = "fetch-body".toArray()
    public var hasBody: Bool = true

    public init() {}

    public func fetch(url: String): InputFileFetchResult {
        this.fetchCount += 1
        this.lastUrl = url
        if (!this.hasBody) {
            return InputFileFetchResult.noBody(url)
        }
        InputFileFetchResult(url, this.responseBody)
    }
}

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

private func rawConsumeErrorMessage(raw: InputFileRawData): String {
    var message = ""
    try {
        raw.consume()
    } catch (e: Exception) {
        message = e.message
    }
    message
}

private func rawCollectErrorMessage(raw: InputFileRawData): String {
    var message = ""
    try {
        raw.collectBytes()
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

    @TestCase
    public func telegramTypeManifestPinsUpstreamTypeSourcesAndExports(): Unit {
        let baseline = telegramTypePackageBaseline()
        let sendPhoto = telegramApiMethodManifestFor("sendPhoto")
        let getMe = telegramApiMethodManifestFor("getMe")
        let inputMedia = telegramInputFileBoundAliasFor("InputMedia")

        @Expect(baseline.version, "3.26.0")
        @Expect(baseline.denoSpecifier, "https://deno.land/x/grammy_types@v3.26.0/mod.ts")
        @Expect(baseline.nodeSpecifier, "@grammyjs/types")
        @Expect(telegramTypeFacadeDriftCheck(
            "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
            "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
            "@grammyjs/types",
            "@grammyjs/types",
            "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
            "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
            "./types.deno.ts"
        ), true)
        @Expect(telegramTypeFacadeDriftCheck(
            "https://deno.land/x/grammy_types@v3.27.0/mod.ts",
            "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
            "@grammyjs/types",
            "@grammyjs/types",
            "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
            "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
            "./types.deno.ts"
        ), false)
        @Expect(telegramTypeExportModuleCount(), 13)
        @Expect(telegramTypeExportManifestCount(), 306)
        @Expect(telegramTypeExportExists("Message"), true)
        @Expect(telegramTypeExportModuleFor("InputStoryContentVideo"), "methods")
        @Expect(telegramApiMethodManifestCount(), 169)
        @Expect(telegramApiMethodExists("sendPhoto"), true)
        @Expect(telegramApiMethodExists("missingMethod"), false)
        @Expect(sendPhoto.hasPayload, true)
        @Expect(sendPhoto.usesInputFile, true)
        @Expect(getMe.hasPayload, false)
        @Expect(inputMedia.constructible, true)
        @Expect(inputMedia.inputFileReplacementPoint, "media and thumbnail")
        @Expect(telegramInputFileBoundAliasManifestCount(), 18)
        @Expect(telegramTypeGateRequiresCompleteManifest(), true)
    }

    @TestCase
    public func telegramTypeModelManifestCoversAllUpstreamExports(): Unit {
        let update = telegramTypeModelDescriptorFor("Update")
        let message = telegramTypeModelDescriptorFor("Message")
        let inputMedia = telegramTypeModelDescriptorFor("InputMedia")
        let missing = telegramTypeModelDescriptorFor("MissingType")

        @Expect(telegramTypeUpstreamSourceAnchors().size, 19)
        @Expect(telegramTypeModelManifestCount(), 306)
        @Expect(telegramTypeModelManifestCount(), telegramTypeExportManifestCount())
        @Expect(telegramTypeModelCompletenessGate(), true)
        @Expect(telegramTypeModelCompletenessGateWithRemovedExport("Message"), false)
        @Expect(update.generatedFromUpstream, true)
        @Expect(update.fieldCount(), 25)
        @Expect(update.hasField("update_id"), true)
        @Expect(update.hasField("callback_query"), true)
        @Expect(message.hasField("message_id"), true)
        @Expect(message.hasField("entities"), true)
        @Expect(inputMedia.declarationKind, "union")
        @Expect(inputMedia.unionMemberCount(), 5)
        @Expect(inputMedia.inputFileReplacementPoint, "media and thumbnail")
        @Expect(missing.constructible, false)
    }

    @TestCase
    public func telegramTypeIRCoversExportIntegrityFieldsAndUnions(): Unit {
        let integrity = telegramTypeExportIntegrityReport()
        let update = telegramTypeIRFor("Update")
        let message = telegramTypeIRFor("Message")
        let inputMedia = telegramTypeIRFor("InputMedia")
        let inputMediaVideo = telegramTypeIRFor("InputMediaVideo")
        let missing = telegramTypeIRFor("MissingType")

        @Expect(telegramTypeExportNames().size, 306)
        @Expect(telegramTypeExportNames()[0], "ApiError")
        @Expect(integrity.ok(), true)
        @Expect(integrity.expectedExportCount, 306)
        @Expect(integrity.actualExportCount, 306)
        @Expect(integrity.duplicateExportCount, 0)
        @Expect(integrity.missingModelCount, 0)
        @Expect(telegramTypeIRManifestCount(), 306)
        @Expect(telegramTypeIRCompletenessGate(), true)
        @Expect(update.publicExport, true)
        @Expect(update.generatedFromUpstream, true)
        @Expect(update.fieldCount(), 25)
        @Expect(update.fields[0].jsonKey, "update_id")
        @Expect(update.fields[0].cangjieFieldName, "updateId")
        @Expect(update.fields[1].optional(), true)
        @Expect(message.hasField("message_id"), true)
        @Expect(message.fields[0].cangjieFieldName, "messageId")
        @Expect(inputMedia.declarationKind, "union")
        @Expect(inputMedia.unionMemberCount(), 5)
        @Expect(inputMedia.hasUnionMember("InputMediaVideo"), true)
        @Expect(inputMediaVideo.fields[1].usesInputFile(), true)
        @Expect(missing.publicExport, false)
    }

    @TestCase
    public func telegramTypeFieldManifestRecordsJsonKeysOptionalityArraysAndApiLinks(): Unit {
        let updateFields = telegramTypeFieldManifestFor("Update")
        let messageFields = telegramTypeFieldManifestFor("Message")
        let inputMediaVideo = telegramTypeFieldManifestFor("InputMediaVideo")

        @Expect(updateFields.size, 25)
        @Expect(updateFields[0].objectName, "Update")
        @Expect(updateFields[0].fieldName, "update_id")
        @Expect(updateFields[0].jsonKey, "update_id")
        @Expect(updateFields[0].required, true)
        @Expect(updateFields[1].fieldName, "message")
        @Expect(updateFields[1].optional(), true)
        @Expect(updateFields[1].apiMethod, "getUpdates,setWebhook")
        @Expect(messageFields[8].fieldName, "entities")
        @Expect(messageFields[8].arrayDepth, "1")
        @Expect(inputMediaVideo[1].fieldName, "media")
        @Expect(inputMediaVideo[1].inputFileReplacementPoint, "media and thumbnail")
        @Expect(inputMediaVideo[2].fieldName, "thumbnail")
    }

    @TestCase
    public func telegramInputFileBoundAliasDriftGateDetectsDeletedAlias(): Unit {
        let aliases = [
            "ApiMethods", "Opts", "InputSticker", "InputMedia", "InputMediaPhoto", "InputMediaVideo",
            "InputMediaAnimation", "InputMediaAudio", "InputMediaDocument", "InputPaidMedia",
            "InputPaidMediaPhoto", "InputPaidMediaVideo", "InputProfilePhoto", "InputProfilePhotoStatic",
            "InputProfilePhotoAnimated", "InputStoryContent", "InputStoryContentPhoto", "InputStoryContentVideo"
        ]
        let missingOne = [
            "ApiMethods", "Opts", "InputSticker", "InputMedia", "InputMediaPhoto", "InputMediaVideo",
            "InputMediaAnimation", "InputMediaAudio", "InputMediaDocument", "InputPaidMedia",
            "InputPaidMediaPhoto", "InputPaidMediaVideo", "InputProfilePhoto", "InputProfilePhotoStatic",
            "InputProfilePhotoAnimated", "InputStoryContent", "InputStoryContentPhoto"
        ]

        @Expect(telegramTypeFacadeAliasDriftCheck(aliases), true)
        @Expect(telegramTypeFacadeAliasDriftCheck(missingOne), false)
        @Expect(telegramInputFileBoundAliasFor("ApiMethods").upstreamGeneric, "ApiMethodsF<InputFile>")
        @Expect(telegramTypeModelDescriptorFor("ApiMethods").associatedApiMethods, "all ApiMethods payload positions")
        @Expect(telegramTypeModelDescriptorFor("InputStoryContentVideo").inputFileReplacementPoint, "video")
    }

    @TestCase
    public func telegramTypeBusExposesApiAndContextIntegrationTrace(): Unit {
        let sendPhoto = telegramTypeModelDescriptorFor("Message")
        let updateFields = telegramTypeContextGetterTrace()
        let bus = telegramTypeBus()
        let sendPhotoMapping = telegramTypeApiMappingFor("sendPhoto")
        let inlineMapping = telegramTypeApiMappingFor("editMessageMediaInline")
        let getMeMapping = telegramTypeApiMappingFor("getMe")
        let callbackContext = telegramTypeContextMappingFor("callback_query")
        let updateIdContext = telegramTypeContextMappingFor("update_id")

        @Expect(telegramTypeApiWrapperIntegrationCount(), 180)
        @Expect(telegramTypeContextGetterTraceCount(), 25)
        @Expect(sendPhoto.associatedApiMethods.contains("sendPhoto"), true)
        @Expect(updateFields[0].fieldName, "update_id")
        @Expect(updateFields[11].fieldName, "inline_query")
        @Expect(updateFields[12].fieldName, "chosen_inline_result")
        @Expect(updateFields[13].fieldName, "callback_query")
        @Expect(telegramTypeApiMappingCount(), 180)
        @Expect(telegramTypeContextMappingCount(), 25)
        @Expect(bus.complete(), true)
        @Expect(bus.irNodes.size, 306)
        @Expect(bus.apiMappings.size, 180)
        @Expect(bus.contextMappings.size, 25)
        @Expect(sendPhotoMapping.payloadTypeName, "Opts<sendPhoto>")
        @Expect(sendPhotoMapping.resultTypeName, "Message")
        @Expect(sendPhotoMapping.usesInputFile, true)
        @Expect(inlineMapping.payloadTypeName, "Opts<editMessageMedia>")
        @Expect(inlineMapping.hasCangjieWrapper, true)
        @Expect(getMeMapping.payloadTypeName, "{}")
        @Expect(getMeMapping.resultTypeName, "UserFromGetMe")
        @Expect(callbackContext.contextPropertyName, "callbackQuery")
        @Expect(callbackContext.contextAccessorName, "callbackQuery")
        @Expect(callbackContext.resultTypeName, "CallbackQuery")
        @Expect(callbackContext.optional(), true)
        @Expect(updateIdContext.contextAccessorName, "updateId()")
        @Expect(updateIdContext.required, true)
        @Expect(telegramObjectSubsetTraceAcceptedAsGate(), false)
    }

    @TestCase
    public func telegramTypeBusExposesTypedBuilderMappings(): Unit {
        let keyboardText = telegramTypeBuilderMappingFor("Keyboard", "textButton")
        let inlineUrl = telegramTypeBuilderMappingFor("InlineKeyboard", "urlButton")
        let inlinePhoto = telegramTypeBuilderMappingFor("InlineQueryResultBuilder", "photo")
        let mediaVideo = telegramTypeBuilderMappingFor("InputMediaBuilder", "video")

        @Expect(telegramTypeBuilderMappingCount(), 15)
        @Expect(keyboardText.returnTypeName, "KeyboardButton.CommonButton")
        @Expect(keyboardText.requiredFields, "text")
        @Expect(inlineUrl.returnTypeName, "InlineKeyboardButton.UrlButton")
        @Expect(inlinePhoto.returnTypeName, "InlineQueryResultPhoto")
        @Expect(inlinePhoto.requiredFields.contains("thumbnail_url"), true)
        @Expect(mediaVideo.returnTypeName, "InputMediaVideo")
        @Expect(mediaVideo.inputFileFields, "media|thumbnail|cover")
        @Expect(mediaVideo.usesInputFile(), true)
        @Expect(telegramTypeBuilderMappingFor("Missing", "missing").returnTypeName, "")
    }

    @TestCase
    public func telegramTypeDryRunDiffReportsFieldAndUnionChanges(): Unit {
        let oldFields = [
            TelegramTypeFieldModel("Fixture", "id", "id", true, "0", "", "", ""),
            TelegramTypeFieldModel("Fixture", "username", "username", false, "0", "", "", "")
        ]
        let newFields = [
            TelegramTypeFieldModel("Fixture", "id", "id", true, "0", "", "", ""),
            TelegramTypeFieldModel("Fixture", "language_code", "language_code", false, "0", "", "", "")
        ]
        let diffs = telegramTypeDryRunDiff(oldFields, newFields, "A|B", "A|C")
        let report = telegramTypeDryRunReport(diffs)

        @Expect(diffs.size, 4)
        @Expect(diffs[0].changeKind, "field_added")
        @Expect(diffs[0].memberName, "language_code")
        @Expect(diffs[1].changeKind, "field_removed")
        @Expect(diffs[1].memberName, "username")
        @Expect(report.contains("union_member_added:union.C"), true)
        @Expect(report.contains("union_member_removed:union.B"), true)
    }

    @TestCase
    public func telegramTypeDryRunImpactReportNamesAffectedApiBuilderAndContext(): Unit {
        let oldFields = telegramTypeFieldManifestFor("InputMediaVideo")
        let newFields = [
            TelegramTypeFieldModel("InputMediaVideo", "type", "type", true, "0", "", "", ""),
            TelegramTypeFieldModel("InputMediaVideo", "media", "media", true, "0", "", "media and thumbnail", ""),
            TelegramTypeFieldModel("InputMediaVideo", "caption", "caption", false, "0", "", "", "")
        ]
        let diffs = telegramTypeDryRunDiff(oldFields, newFields, "InputMediaPhoto|InputMediaVideo", "InputMediaPhoto")
        let report = telegramTypeDryRunImpactReport(diffs)

        @Expect(report.contains("field_removed:InputMediaVideo.thumbnail"), true)
        @Expect(report.contains("union_member_removed:union.InputMediaVideo"), true)
        @Expect(report.contains("impact:type.InputMediaVideo"), true)
        @Expect(report.contains("impact:api.sendMediaGroup"), true)
        @Expect(report.contains("impact:builder.InputMediaBuilder.video"), true)
    }

    @TestCase
    public func telegramTypeDryRunImpactReportNamesContextForUpdateChanges(): Unit {
        let oldFields = telegramTypeFieldManifestFor("Update")
        let newFields = [
            TelegramTypeFieldModel("Update", "update_id", "update_id", true, "0", "", "", "")
        ]
        let report = telegramTypeDryRunImpactReport(telegramTypeDryRunDiff(oldFields, newFields, "", ""))

        @Expect(report.contains("field_removed:Update.message"), true)
        @Expect(report.contains("impact:api.getUpdates"), true)
        @Expect(report.contains("impact:context.updateId()"), true)
    }

    @TestCase
    public func telegramTypeSnapshotDriftCheckReportsManifestCountChanges(): Unit {
        let current = telegramTypeCurrentManifestSnapshot()
        let drifted = TelegramTypeManifestSnapshot(
            current.version,
            current.exportCount - 1,
            current.exportModuleCount,
            current.apiMethodCount,
            current.inputFileAliasCount,
            current.irNodeCount,
            current.apiMappingCount,
            current.contextMappingCount,
            current.rootFacade
        )
        let ok = telegramTypeSnapshotDriftCheck(current)
        let drift = telegramTypeSnapshotDriftCheck(drifted)

        @Expect(current.exportCount, 306)
        @Expect(current.irNodeCount, 306)
        @Expect(current.apiMappingCount, 180)
        @Expect(current.contextMappingCount, 25)
        @Expect(ok.ok, true)
        @Expect(ok.diffCount(), 0)
        @Expect(drift.ok, false)
        @Expect(drift.diffCount(), 1)
        @Expect(drift.report.contains("count_changed:telegram_types.export_count"), true)
    }

    @TestCase
    public func typeSourceMatrixCoversUpstreamFacadesAndGenericAliases(): Unit {
        let matrix = typeSourceMatrix()
        let deno = typeSourceMatrixFor("src/types.deno.ts")
        let node = typeSourceMatrixFor("src/types.node.ts")
        let web = typeSourceMatrixFor("src/types.web.ts")
        let root = typeSourceMatrixFor("src/types.ts")

        @Expect(typeSourceMatrixCount(), 4)
        @Expect(matrix.size, 4)
        @Expect(deno.coversApiMethods, true)
        @Expect(deno.coversOpts, true)
        @Expect(deno.coversInputFileGenericAliases, true)
        @Expect(deno.inputFileSourceApi.contains("response"), true)
        @Expect(node.inputFileSourceApi.contains("blob"), false)
        @Expect(web.inputFileSourceApi.contains("supplier"), false)
        @Expect(root.coversTelegramObjectSubset, true)
        @Expect(typeSourceMatrixFor("src/missing.ts").coversApiMethods, false)
    }

    @TestCase
    public func telegramObjectSubsetTraceCoversGateOneRuntimeModels(): Unit {
        let subset = telegramObjectSubsetTrace()

        @Expect(telegramObjectSubsetTraceCount(), 9)
        @Expect(telegramObjectSubsetTraceAcceptedAsGate(), false)
        @Expect(subset[0].objectName, "ResponseParameters")
        @Expect(subset[3].objectName, "User")
        @Expect(subset[8].objectName, "Update")
        @Expect(subset[8].cangjieType, "Update")
        @Expect(subset[8].historicalOnly, true)
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
        @Expect(inputFileSourceMatrixCount(), 10)
        @Expect(inputFileRuntimeNames().size, 3)
        @Expect(inputFileRuntimeNames()[0], "deno")
        @Expect(inputFileSourceKindNames()[0], "path")
        @Expect(inputFileSourceKindNames()[9], "supplier")
        @Expect(inputFileSourceMatrixFor("path").upstreamDeno, true)
        @Expect(inputFileSourceMatrixFor("path").upstreamWeb, false)
        @Expect(inputFileSourceMatrixFor("stream").singleUse, true)
        @Expect(inputFileSourceMatrixFor("bytes").filenameInference, "explicit filename")
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
    public func inputFileToRawReturnsRealRawSourcesWithoutEagerIo(): Unit {
        let pathFile = InputFile.fromPath("/tmp/photo.png")
        let urlFile = InputFile.fromUrl("https://example.test/files/report.pdf")
        let bytesFile = InputFile.fromBytes("bytes:3", "data.bin")

        let pathRaw = pathFile.toRaw()
        let urlRaw = urlFile.toRaw()
        let bytesRaw = bytesFile.toRaw()

        @Expect(pathRaw.contract, "deferred-file-read")
        @Expect(pathRaw.requiresFileAdapter, true)
        @Expect(pathRaw.isFakeContract, false)
        @Expect(pathRaw.rawKind, "path")
        @Expect(pathFile.consumed, false)
        @Expect(urlRaw.contract, "deferred-fetch")
        @Expect(urlRaw.requiresFetchAdapter, true)
        @Expect(urlRaw.isFakeContract, false)
        @Expect(urlFile.consumed, false)
        @Expect(bytesRaw.contract, "bytes-as-is")
        @Expect(bytesRaw.reusable, true)
        @Expect(bytesRaw.summary(), "bytes:bytes-as-is:data.bin")
        @Expect(bytesRaw.collectString(), "bytes:3")
        @Expect(bytesRaw.collectString(), "bytes:3")
    }

    @TestCase
    public func inputFileToRawDefaultUsesDenoFacadeAndInjectedAdapter(): Unit {
        let fileAdapter = FakeFileAdapter()
        let adapter = InputFileRawAdapter(fileAdapter, FakeFetchAdapter())

        let raw = InputFile.fromPath("/tmp/default.txt").toRaw(adapter)

        @Expect(raw.runtime, "deno")
        @Expect(raw.platformContract, "deno-open-file-async-iterator")
        @Expect(raw.requiresFileAdapter, true)
        @Expect(raw.collectString(), "file:/tmp/default.txt")
        @Expect(fileAdapter.readCount, 1)
        @Expect(fileAdapter.lastPath, "/tmp/default.txt")
    }

    @TestCase
    public func inputFileRawCollectsBytesThroughInjectedAdapters(): Unit {
        let fileAdapter = FakeFileAdapter()
        let fetchAdapter = FakeFetchAdapter()
        let adapter = InputFileRawAdapter(fileAdapter, fetchAdapter)
        let pathRaw = InputFile.fromPath("/tmp/photo.png").toRaw("deno", adapter)
        let urlRaw = InputFile.fromUrlLike("https://example.test/files/report.pdf").toRaw("web", adapter)

        @Expect(pathRaw.collectString(), "file:/tmp/photo.png")
        @Expect(fileAdapter.readCount, 1)
        @Expect(fileAdapter.lastPath, "/tmp/photo.png")
        @Expect(urlRaw.collectString(), "fetch-body")
        @Expect(fetchAdapter.fetchCount, 1)
        @Expect(fetchAdapter.lastUrl, "https://example.test/files/report.pdf")
    }

    @TestCase
    public func inputFileRawDistinguishesResponseAndFetchMissingBodies(): Unit {
        let fetchAdapter = FakeFetchAdapter()
        fetchAdapter.hasBody = false
        let adapter = InputFileRawAdapter(FakeFileAdapter(), fetchAdapter)
        let urlRaw = InputFile.fromUrl("https://example.test/no-body").toRaw("deno", adapter)

        @Expect(toRawErrorMessage(InputFile.fromResponse("empty-response", "empty.bin", false)), "No response body!")
        @Expect(rawCollectErrorMessage(urlRaw), "Download failed, no response body from 'https://example.test/no-body'")
    }

    @TestCase
    public func inputFileRawCollectsBlobResponseIterableAndAsyncIterableSources(): Unit {
        let blobRaw = InputFile.fromBlob("ABCD", "blob.txt").toRaw("deno")
        let responseRaw = InputFile.fromResponse("EFGH", "download.bin").toRaw("deno")
        let iterableRaw = InputFile.fromIterable("IJ", "chunks.bin").toRaw("deno")
        let asyncIterableRaw = InputFile.fromAsyncIterable("KL", "async.bin").toRaw("web")

        @Expect(blobRaw.rawSourceKind, "blob")
        @Expect(blobRaw.collectString(), "ABCD")
        @Expect(responseRaw.rawSourceKind, "response")
        @Expect(responseRaw.collectString(), "EFGH")
        @Expect(iterableRaw.rawSourceKind, "iterable")
        @Expect(iterableRaw.collectString(), "IJ")
        @Expect(rawCollectErrorMessage(iterableRaw), "Cannot reuse InputFile data source!")
        @Expect(asyncIterableRaw.rawSourceKind, "async_iterable")
        @Expect(asyncIterableRaw.collectString(), "KL")
    }

    @TestCase
    public func inputFileRawPreservesIterableChunkOrder(): Unit {
        let raw = InputFile.fromIterable("AA|BB|CC", "chunks.bin").toRaw("deno")
        let chunks = raw.collectChunks()

        @Expect(chunks.size, 3)
        @Expect(String.fromUtf8(chunks[0]), "AA")
        @Expect(String.fromUtf8(chunks[1]), "BB")
        @Expect(String.fromUtf8(chunks[2]), "CC")
    }

    @TestCase
    public func inputFileRawDataIsConsumableWithoutRealFileOrNetwork(): Unit {
        let fake = FakeInputFileRawAdapter()
        let pathRaw = InputFile.fromPath("/tmp/photo.png").toRaw("deno")
        let urlRaw = InputFile.fromUrlLike("https://example.test/files/report.pdf").toRaw("web")
        let streamRaw = InputFile.fromStream("stream:3", "video.mp4").toRaw("node")

        @Expect(fake.consume(pathRaw), "deno:path:deno-open-file-async-iterator:photo.png")
        @Expect(fake.consume(urlRaw), "web:url_like:fetch-body-async-iterable:report.pdf")
        @Expect(fake.consume(streamRaw), "node:stream:node-read-stream-as-is:video.mp4")
        @Expect(fake.fileReadCount, 1)
        @Expect(fake.urlFetchCount, 1)
        @Expect(fake.streamConsumeCount, 1)
        @Expect(pathRaw.rawConsumed(), false)
        @Expect(rawConsumeErrorMessage(streamRaw), "Cannot reuse InputFile data source!")
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
        let fake = FakeInputFileRawAdapter()

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
        @Expect(fake.consume(streamRaw), "node:stream:node-read-stream-as-is:clip.mp4")
        @Expect(rawCollectErrorMessage(streamRaw), "Cannot reuse InputFile data source!")
        @Expect(fake.streamConsumeCount, 1)
    }

    @TestCase
    public func inputFileSupplierUnwrapsPathUrlAndPropagatesSupplierErrors(): Unit {
        let fileAdapter = FakeFileAdapter()
        let fetchAdapter = FakeFetchAdapter()
        fetchAdapter.responseBody = "remote:bytes".toArray()
        let adapter = InputFileRawAdapter(fileAdapter, fetchAdapter)
        let pathRaw = InputFile.fromSupplier("lazy-path", InputFileSource.path("/tmp/lazy.txt")).toRaw("node", adapter)
        let urlRaw = InputFile.fromSupplier("lazy-url", InputFileSource.url("https://example.test/lazy.bin")).toRaw("node", adapter)
        let failure = InputFile.fromSupplierFailure("lazy-fail", "fail.bin", "supplier exploded")

        @Expect(pathRaw.rawSourceKind, "path")
        @Expect(pathRaw.supplierLabel, "lazy-path")
        @Expect(pathRaw.collectString(), "file:/tmp/lazy.txt")
        @Expect(fileAdapter.lastPath, "/tmp/lazy.txt")
        @Expect(urlRaw.rawSourceKind, "url")
        @Expect(urlRaw.collectString(), "remote:bytes")
        @Expect(fetchAdapter.lastUrl, "https://example.test/lazy.bin")
        @Expect(toRawErrorMessage(failure, "deno"), "supplier exploded")
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
        @Expect(raw.collectString(), "stream:1")
        @Expect(rawCollectErrorMessage(raw), "Cannot reuse InputFile data source!")
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
        let explicit = InputFile(InputFileSource.path("/tmp/photo.png"), "explicit.jpg")
        let explicitRaw = explicit.toRaw("node")

        @Expect(explicit.filename, "explicit.jpg")
        @Expect(explicitRaw.filename, "explicit.jpg")
        @Expect(inferFilename("file.txt"), "file.txt")
        @Expect(inferFilename("/tmp/file.txt"), "file.txt")
        @Expect(inferFilename("/tmp/"), "tmp")
        @Expect(inferFilename("https://grammy.dev/file.txt"), "file.txt")
        @Expect(inferFilename("https://grammy.dev/file.txt?download=1"), "file.txt")
        @Expect(inferFilename("https://grammy.dev"), "grammy.dev")
        @Expect(inferFilename("https://grammy.dev/"), "grammy.dev")
        @Expect(inputFilePathLooksLikeRemoteUrlWarning("https://grammy.dev").contains("local file path"), true)
        @Expect(inputFilePathLooksLikeRemoteUrlWarning("/tmp/file.txt"), "")
    }
}
