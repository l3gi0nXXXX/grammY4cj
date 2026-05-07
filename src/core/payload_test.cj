package grammy4cj.core

import grammy4cj.types.InputFile
import std.collection.ArrayList
import std.unittest.*

private func ignorePayloadStreamError(_err: Exception): Unit {}

@Test
public class PayloadTest {
    @TestCase
    public func jsonPayloadSkipsNullAndEscapesStrings(): Unit {
        let payload = Payload("")
        payload.addValue("chat_id", "42")
        payload.addNull("parse_mode")
        payload.addValue("text", "say \"hi\"")

        let req = createJsonPayload(payload)

        @Expect(req.method, "POST")
        @Expect(req.headers, "content-type=application/json;connection=keep-alive")
        @Expect(req.body, "{\"chat_id\":\"42\",\"text\":\"say \\\"hi\\\"\"}")
        @Expect(requiresFormDataUpload(payload), false)
    }

    @TestCase
    public func jsonPayloadSkipsNullishButKeepsFalseZeroAndEmptyString(): Unit {
        let payload = Payload("")
        payload.addBool("disable_notification", false)
        payload.addInt("message_thread_id", 0)
        payload.addValue("caption", "")
        payload.addUndefined("reply_markup")
        let nested = payload.addObject("options")
        nested.addNull("drop")
        nested.addBool("keep", false)

        let req = createJsonPayload(payload)

        @Expect(req.body, "{\"disable_notification\":false,\"message_thread_id\":0,\"caption\":\"\",\"options\":{\"keep\":false}}")
    }

    @TestCase
    public func formDataUploadDetectsInputFileFields(): Unit {
        let payload = Payload("")
        payload.addValue("chat_id", "42")
        payload.addFile("document", InputFile.fromBytes("abc", "my-file"))

        @Expect(requiresFormDataUpload(payload), true)
    }

    @TestCase
    public func formDataUploadDetectionRecursesThroughArraysAndObjects(): Unit {
        let jsonOnly = Payload("")
        let nested = jsonOnly.addObject("reply_markup")
        let rows = nested.addArray("inline_keyboard")
        let row = rows.addObjectItem()
        row.addValue("text", "ok")

        let withFile = Payload("")
        let media = withFile.addArray("media")
        let item = media.addObjectItem()
        item.addValue("type", "photo")
        item.addFile("media", InputFile.fromBytes("photo-bytes", ""))

        @Expect(requiresFormDataUpload(jsonOnly), false)
        @Expect(requiresFormDataUpload(withFile), true)
    }

    @TestCase
    public func multipartPayloadBuildsAttachProtocol(): Unit {
        let payload = Payload("")
        payload.addValue("chat_id", "42")
        payload.addFile("document", InputFile.fromBytes("abc", "my-file"))

        let req = createFormDataPayload(payload, "boundary", "attach")

        @Expect(req.method, "POST")
        @Expect(req.headers, "content-type=multipart/form-data; boundary=boundary;connection=keep-alive")
        @Expect(req.body.contains("name=\"chat_id\"\r\n\r\n42"), true)
        @Expect(req.body.contains("name=\"document\"\r\n\r\nattach://attach0"), true)
        @Expect(req.body.contains("name=\"attach0\";filename=my-file"), true)
        @Expect(req.body.contains("abc\r\n--boundary--"), true)
        @Expect(req.bodyKind, "stream")
        @Expect(req.stream.chunkCount() > 0, true)
    }

    @TestCase
    public func multipartPayloadDefaultEntryCreatesBoundaryAndRandomAttachIds(): Unit {
        let payload = Payload("")
        payload.addValue("chat_id", "42")
        payload.addFile("document", InputFile.fromBytes("abc", "my-file"))

        let req = createFormDataPayload(payload, ignorePayloadStreamError)

        @Expect(req.method, "POST")
        @Expect(req.headers.contains("content-type=multipart/form-data; boundary=----------"), true)
        @Expect(req.body.startsWith("------------"), true)
        @Expect(req.body.contains("name=\"document\"\r\n\r\nattach://"), true)
        @Expect(req.body.contains("filename=my-file"), true)
        @Expect(req.body.contains("abc\r\n--"), true)
        @Expect(req.bodyKind, "stream")
    }

    @TestCase
    public func multipartPayloadReadsFileContentThroughInputFileRaw(): Unit {
        let payload = Payload("")
        payload.addFile("document", InputFile.fromIterable("iterable-bytes", "iter.txt"))

        let req = createFormDataPayload(payload, "boundary", "attach")

        @Expect(req.body.contains("name=\"attach0\";filename=iter.txt"), true)
        @Expect(req.body.contains("iterable-bytes\r\n--boundary--"), true)
    }

    @TestCase
    public func multipartPayloadUsesInputFileRawFilenameInference(): Unit {
        let payload = Payload("")
        payload.addFile("photo", InputFile.fromPath("/tmp/images/photo.png"))

        let req = createFormDataPayload(payload, "boundary", "attach")

        @Expect(req.body.contains("name=\"attach0\";filename=photo.png"), true)
        @Expect(req.body.contains("/tmp/images/photo.png\r\n--boundary--"), true)
    }

    @TestCase
    public func multipartPayloadUsesUrlAndAsyncIterableRawSources(): Unit {
        let payload = Payload("")
        payload.addFile("document", InputFile.fromUrl("https://example.test/files/report.pdf?download=1"))
        payload.addFile("voice", InputFile.fromAsyncIterable("async-bytes", "voice.ogg"))

        let req = createFormDataPayload(payload, "boundary", "attach")

        @Expect(req.body.contains("name=\"attach0\";filename=report.pdf"), true)
        @Expect(req.body.contains("https://example.test/files/report.pdf?download=1"), true)
        @Expect(req.body.contains("name=\"attach1\";filename=voice.ogg"), true)
        @Expect(req.body.contains("async-bytes\r\n--boundary--"), true)
    }

    @TestCase
    public func multipartPayloadUsesDefaultExtensions(): Unit {
        @Expect(defaultFileExtension("certificate"), "pem")
        @Expect(defaultFileExtension("photo"), "jpg")
        @Expect(defaultFileExtension("thumbnail"), "jpg")
        @Expect(defaultFileExtension("voice"), "ogg")
        @Expect(defaultFileExtension("audio"), "mp3")
        @Expect(defaultFileExtension("video"), "mp4")
        @Expect(defaultFileExtension("video_note"), "mp4")
        @Expect(defaultFileExtension("sticker"), "webp")
        @Expect(defaultFileExtension("unknown"), "dat")
    }

    @TestCase
    public func recursiveJsonPayloadSkipsObjectNullsAndKeepsArrayNulls(): Unit {
        let payload = Payload("")
        payload.addInt("chat_id", 42)
        payload.addUndefined("disable_notification")
        let options = payload.addObject("options")
        options.addValue("parse_mode", "MarkdownV2")
        options.addNull("unused")
        options.addNone("also_unused")
        options.addFloat("latitude", 54.5)
        let flags = options.addArray("flags")
        flags.addBoolItem(true).addNullItem().addUndefinedItem().addNumberItem(7)

        @Expect(createJsonPayload(payload).body, "{\"chat_id\":42,\"options\":{\"parse_mode\":\"MarkdownV2\",\"latitude\":54.500000,\"flags\":[true,null,null,7]}}")
    }

    @TestCase
    public func recursiveMultipartPayloadFindsNestedFiles(): Unit {
        let payload = Payload("")
        let media = payload.addArray("media")
        let item = media.addObjectItem()
        item.addValue("type", "photo")
        item.addFile("media", InputFile.fromBytes("abc", ""))

        let req = createFormDataPayload(payload, "boundary", "attach")

        @Expect(requiresFormDataUpload(payload), true)
        @Expect(req.body.contains("\"media\":\"attach://attach0\""), true)
        @Expect(req.body.contains("name=\"attach0\";filename=photo.jpg"), true)
    }

    @TestCase
    public func recursiveMultipartPayloadFindsFilesInNestedArraysAndObjects(): Unit {
        let payload = Payload("")
        payload.addInt("chat_id", 42)
        let media = payload.addArray("media")
        let first = media.addObjectItem()
        first.addValue("type", "photo")
        first.addFile("media", InputFile.fromBytes("photo-bytes", ""))
        let second = media.addObjectItem()
        second.addValue("type", "video")
        second.addFile("thumbnail", InputFile.fromBytes("thumb-bytes", ""))
        let meta = payload.addObject("meta")
        let files = meta.addArray("files")
        files.addFileItem(InputFile.fromBytes("document-bytes", "doc.txt"))

        let req = createFormDataPayload(payload, "boundary", "attach")

        @Expect(requiresFormDataUpload(payload), true)
        @Expect(req.body.contains("\"media\":\"attach://attach0\""), true)
        @Expect(req.body.contains("\"thumbnail\":\"attach://attach1\""), true)
        @Expect(req.body.contains("\"files\":[\"attach://attach2\"]"), true)
        @Expect(req.body.contains("name=\"attach0\";filename=photo.jpg"), true)
        @Expect(req.body.contains("name=\"attach1\";filename=thumbnail.jpg"), true)
        @Expect(req.body.contains("name=\"attach2\";filename=doc.txt"), true)
    }

    @TestCase
    public func multipartPayloadRejectsCrLfFilenamesWithOriginInMessage(): Unit {
        let payload = Payload("")
        payload.addFile("document", InputFile.fromBytes("abc", "bad\nname.txt"))

        try {
            createFormDataPayload(payload, "boundary", "attach")
            @Expect(true, false)
        } catch (err: Exception) {
            @Expect(err.message.contains("File paths cannot contain carriage-return (\\r) or newline (\\n) characters!"), true)
            @Expect(err.message.contains("Filename for property 'document' was:"), true)
            @Expect(err.message.contains("bad\nname.txt"), true)
        }
    }

    @TestCase
    public func multipartPayloadRejectsCrLfOriginsFromMediaType(): Unit {
        let payload = Payload("")
        let media = payload.addArray("media")
        let item = media.addObjectItem()
        item.addValue("type", "bad\nphoto")
        item.addFile("media", InputFile.fromBytes("abc", ""))

        try {
            createFormDataPayload(payload, "boundary", "attach")
            @Expect(true, false)
        } catch (err: Exception) {
            @Expect(err.message.contains("File paths cannot contain carriage-return (\\r) or newline (\\n) characters!"), true)
            @Expect(err.message.contains("Filename for property 'bad\nphoto' was:"), true)
        }
    }

    @TestCase
    public func multipartPayloadCanBeBuiltRepeatedly(): Unit {
        let payload = Payload("")
        payload.addValue("chat_id", "42")
        payload.addFile("document", InputFile.fromBytes("abc", "my-file"))

        let first = createFormDataPayload(payload, "boundary", "attach")
        let second = createFormDataPayload(payload, "boundary", "attach")

        @Expect(first.body, second.body)
    }

    @TestCase
    public func multipartStreamInvokesErrorCallbackWhenDrained(): Unit {
        let errors = ArrayList<String>()
        let payload = Payload("")
        payload.addFile("document", InputFile("stream_error", "stream exploded", "a.txt"))

        let req = createFormDataPayload(payload, "boundary", "attach", { err: Exception =>
            errors.add(err.message)
        })

        try {
            req.stream.drain()
            @Expect(true, false)
        } catch (err: Exception) {
            @Expect(err.message, "stream exploded")
            @Expect(errors.size, 1)
            @Expect(errors[0], "stream exploded")
        }
    }
}
