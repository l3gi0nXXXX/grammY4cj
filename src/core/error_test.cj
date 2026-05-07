package grammy4cj.core

import grammy4cj.types.ResponseParameters
import std.unittest.*

@Test
public class CoreErrorTest {
    @TestCase
    public func grammyErrorKeepsTelegramErrorFields(): Unit {
        let err = GrammyError("sendMessage", "{\"chat_id\":1}", 400, "Bad Request", ResponseParameters(0, 0))

        @Expect(err.method, "sendMessage")
        @Expect(err.payload, "{\"chat_id\":1}")
        @Expect(err.errorCode, 400)
        @Expect(err.description, "Bad Request")
        @Expect(err.parameters.retryAfter, 0)
    }

    @TestCase
    public func httpErrorKeepsTransportFields(): Unit {
        let err = HttpError("network failed", 599, "POST", "https://api.telegram.org/botT/getMe")

        @Expect(err.status, 599)
        @Expect(err.method, "POST")
        @Expect(err.url, "https://api.telegram.org/botT/getMe")
    }

    @TestCase
    public func toHttpErrorHidesSensitiveMessagesByDefault(): Unit {
        let err = toHttpError("getMe", false, Exception("secret-token leaked"))

        @Expect(err.message, "Network request for 'getMe' failed!")
        @Expect(err.error, "secret-token leaked")
    }

    @TestCase
    public func toHttpErrorIncludesSensitiveMessagesWhenEnabled(): Unit {
        let err = toHttpError("getMe", true, Exception("debug detail"))

        @Expect(err.message, "Network request for 'getMe' failed! debug detail")
    }

    @TestCase
    public func toHttpErrorIncludesTelegramStatusInfo(): Unit {
        let err = toHttpError("getMe", false, 502, "Bad Gateway", "upstream failed")

        @Expect(err.message, "Network request for 'getMe' failed! (502: Bad Gateway)")
        @Expect(err.status, 502)
        @Expect(err.statusText, "Bad Gateway")
    }
}
