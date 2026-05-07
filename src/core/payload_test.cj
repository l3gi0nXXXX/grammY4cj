package grammy4cj.core

import grammy4cj.types.InputFile
import std.collection.ArrayList
import std.unittest.*

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
    public func formDataUploadDetectsInputFileFields(): Unit {
        let payload = Payload("")
        payload.addValue("chat_id", "42")
        payload.addFile("document", InputFile.fromBytes("abc", "my-file"))

        @Expect(requiresFormDataUpload(payload), true)
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
