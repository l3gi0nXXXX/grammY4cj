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
}
