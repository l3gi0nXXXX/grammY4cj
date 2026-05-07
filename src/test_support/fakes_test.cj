package grammy4cj.test_support

import grammy4cj.core.Payload
import std.unittest.*

@Test
public class TestSupportFakesTest {
    @TestCase
    public func fakeHttpRecordsMethodUrlHeadersAndBody(): Unit {
        let http = FakeHttp()
        let recorded = http.request("POST", "https://api.telegram.org/botT/sendMessage", "content-type=json", "{\"text\":\"hi\"}")

        @Expect(http.called, true)
        @Expect(recorded.method, "POST")
        @Expect(recorded.url, "https://api.telegram.org/botT/sendMessage")
        @Expect(recorded.headers, "content-type=json")
        @Expect(recorded.body, "{\"text\":\"hi\"}")
    }

    @TestCase
    public func fakeApiRecordsMethodAndPayload(): Unit {
        let api = FakeApi()
        let response = api.call("sendMessage", Payload("{\"chat_id\":1}"))

        @Expect(response, "{}")
        @Expect(api.called, true)
        @Expect(api.method, "sendMessage")
        @Expect(api.payloadBody, "{\"chat_id\":1}")
    }

    @TestCase
    public func fakeClockAdvancesWithoutSleeping(): Unit {
        let clock = FakeClock()
        clock.sleep(1500)
        clock.sleep(500)

        @Expect(clock.nowMillis, 2000)
    }

    @TestCase
    public func fakeUpdateMessageFixtureHasChatFromMessageId(): Unit {
        let message = fakeMessage(7, "hello")
        let update = fakeMessageUpdate(9)
        let me = fakeBotInfo()

        @Expect(message.messageId, 7)
        @Expect(message.chat.id, 123456)
        @Expect(update.updateId, 9)
        @Expect(me.username, "grammy4cj_bot")
    }

    @TestCase
    public func fakeLoggerAndStorageCaptureStateOnlyInMemory(): Unit {
        let logger = FakeLogger()
        let storage = FakeStorage()

        logger.debug("debug one")
        logger.warn("warn one")
        logger.error("error one")
        storage.write("session:1", "value")

        @Expect(logger.debugCount, 1)
        @Expect(logger.warnCount, 1)
        @Expect(logger.errorCount, 1)
        @Expect(logger.lastMessage, "error one")
        @Expect(storage.read("session:1"), "value")
        @Expect(storage.read("session:2"), "")
    }

    @TestCase
    public func payloadAssertionChecksBodyWithoutNetwork(): Unit {
        @Expect(payloadBodyEquals(Payload("{\"ok\":true}"), "{\"ok\":true}"), true)
        @Expect(payloadBodyEquals(Payload("{\"ok\":false}"), "{\"ok\":true}"), false)
    }
}
