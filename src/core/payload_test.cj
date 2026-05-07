package grammy4cj.core

import grammy4cj.types.InputFile
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
        @Expect(req.headers, "content-type=multipart/form-data;boundary=boundary;connection=keep-alive")
        @Expect(req.body.contains("name=\"chat_id\"\r\n\r\n42"), true)
        @Expect(req.body.contains("name=\"document\"\r\n\r\nattach://attach0"), true)
        @Expect(req.body.contains("name=\"attach0\";filename=my-file"), true)
        @Expect(req.body.contains("abc\r\n--boundary--"), true)
    }

    @TestCase
    public func multipartPayloadUsesDefaultExtensions(): Unit {
        @Expect(defaultFileExtension("certificate"), "pem")
        @Expect(defaultFileExtension("photo"), "jpg")
        @Expect(defaultFileExtension("voice"), "ogg")
        @Expect(defaultFileExtension("video"), "mp4")
        @Expect(defaultFileExtension("unknown"), "dat")
    }
}
