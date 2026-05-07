package grammy4cj.bot

import std.unittest.*

@Test
public class BotTest {
    @TestCase
    public func botOwnsTokenAndApiFacade(): Unit {
        let bot = Bot("fake-token")

        @Expect(bot.token, "fake-token")
        @Expect(bot.api.token, "fake-token")
        @Expect(bot.isInited(), false)
    }

    @TestCase
    public func botInitializationStateIsExplicit(): Unit {
        let bot = Bot("fake-token")
        bot.markInitialized()

        @Expect(bot.isInited(), true)
    }
}
