package grammy4cj.context

import std.unittest.*

import grammy4cj.core.Api
import grammy4cj.types.CallbackQuery
import grammy4cj.types.Chat
import grammy4cj.types.InlineQuery
import grammy4cj.types.Message
import grammy4cj.types.MessageEntity
import grammy4cj.types.Update
import grammy4cj.types.User
import grammy4cj.types.UserFromGetMe

private func typeTestBotInfo(): UserFromGetMe {
    UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
}

private func typeTestContext(update: Update): Context {
    Context(update, Api("token"), typeTestBotInfo())
}

@Test
public class ContextTypeSurfaceTest {
    @TestCase
    public func hasChecksCompileWithMatchAndNarrowedSurfaceContract(): Unit {
        let chat = Chat(140, "private")
        let user = User(240, false, "Ada", "ada")
        let message = Message(540, chat, "/start payload", user)
        message.addEntity(MessageEntity("bot_command", 0, 6))
        let ctx = typeTestContext(Update.withMessage(1400, message))

        @Expect(ctx.hasFilter(":text"), true)
        @Expect(ctx.hasText("/start payload"), true)
        let textMatch: String = ctx.`match`
        @Expect(textMatch, "/start payload")
        @Expect(ctx.hasCommand("start"), true)
        let commandMatch: String = ctx.`match`
        @Expect(commandMatch, "payload")
        @Expect(ctx.hasChatType("private"), true)
        @Expect(ctx.chat.kind, "private")

        let gameCtx = typeTestContext(Update.withCallbackQuery(
            1401,
            CallbackQuery(user, "", "game-short-name", message, "")
        ))
        @Expect(gameCtx.hasGameQuery("game-short-name"), true)
        @Expect(gameCtx.callbackQuery.gameShortName, "game-short-name")

        let inlineCtx = typeTestContext(Update.withInlineQuery(1402, InlineQuery(user, "inline-query")))
        @Expect(inlineCtx.hasInlineQuery("inline-query"), true)
        @Expect(inlineCtx.inlineQuery.query, "inline-query")
    }
}
