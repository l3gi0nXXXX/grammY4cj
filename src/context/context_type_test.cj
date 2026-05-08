package grammy4cj.context

import std.unittest.*
import std.regex.Regex

import grammy4cj.core.Api
import grammy4cj.types.CallbackQuery
import grammy4cj.types.Chat
import grammy4cj.types.ChosenInlineResult
import grammy4cj.types.InlineQuery
import grammy4cj.types.Message
import grammy4cj.types.MessageEntity
import grammy4cj.types.MessageReactionUpdated
import grammy4cj.types.PreCheckoutQuery
import grammy4cj.types.ReactionType
import grammy4cj.types.ShippingQuery
import grammy4cj.types.Update
import grammy4cj.types.User
import grammy4cj.types.UserFromGetMe

private func typeTestBotInfo(): UserFromGetMe {
    UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
}

private func typeTestContext(update: Update): Context {
    Context(update, Api("token"), typeTestBotInfo())
}

private func typeMatchText(value: Option<ContextMatch>): String {
    orThrow(value, "type-test").text
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
        let textMatch: String = typeMatchText(ctx.`match`)
        @Expect(textMatch, "/start payload")
        @Expect(ctx.hasCommand("start"), true)
        let commandMatch: String = typeMatchText(ctx.`match`)
        @Expect(commandMatch, "payload")
        @Expect(ctx.hasChatType("private"), true)
        @Expect(orThrow(ctx.chat, "type-test").kind, "private")

        let gameCtx = typeTestContext(Update.withCallbackQuery(
            1401,
            CallbackQuery(user, "", "game-short-name", message, "")
        ))
        @Expect(gameCtx.hasGameQuery("game-short-name"), true)
        @Expect(orThrow(gameCtx.callbackQuery, "type-test").gameShortName, "game-short-name")

        let inlineCtx = typeTestContext(Update.withInlineQuery(1402, InlineQuery(user, "inline-query")))
        @Expect(inlineCtx.hasInlineQuery("inline-query"), true)
        @Expect(orThrow(inlineCtx.inlineQuery, "type-test").query, "inline-query")
    }

    @TestCase
    public func refineHelpersExposeTypedNarrowedWrappers(): Unit {
        let chat = Chat(141, "private")
        let user = User(241, false, "Ada", "ada")
        let message = Message(541, chat, "/start payload", user)
        message.addEntity(MessageEntity("bot_command", 0, 6))
        let ctx = typeTestContext(Update.withMessage(1403, message))

        match (ctx.refineText("/start payload")) {
            case Some(narrowed) =>
                let narrowedMessage: Message = narrowed.message
                let narrowedMatch: String = narrowed.`match`.text
                @Expect(narrowedMessage.text, "/start payload")
                @Expect(narrowedMatch, "/start payload")
            case None => @Expect(false, true)
        }

        match (ctx.refineCommand("start")) {
            case Some(narrowed) =>
                let narrowedMessage: Message = narrowed.message
                let commandPayload: String = narrowed.`match`.text
                @Expect(narrowedMessage.messageId, 541)
                @Expect(commandPayload, "payload")
            case None => @Expect(false, true)
        }

        match (ctx.refineChatType("private")) {
            case Some(narrowed) =>
                let narrowedChat: Chat = narrowed.chat
                let chatType: String = narrowed.chatType
                @Expect(narrowedChat.kind, "private")
                @Expect(chatType, "private")
            case None => @Expect(false, true)
        }

        let callbackCtx = typeTestContext(Update.withCallbackQuery(
            1404,
            CallbackQuery(user, "callback-data", "", message, "")
        ))
        match (callbackCtx.refineCallbackQuery("callback-data")) {
            case Some(narrowed) =>
                let callback: CallbackQuery = narrowed.callbackQuery
                @Expect(callback.data, "callback-data")
                @Expect(narrowed.`match`.text, "callback-data")
            case None => @Expect(false, true)
        }

        let gameCtx = typeTestContext(Update.withCallbackQuery(
            1405,
            CallbackQuery(user, "", "game-short-name", message, "")
        ))
        match (gameCtx.refineGameQuery("game-short-name")) {
            case Some(narrowed) =>
                let gameCallback: CallbackQuery = narrowed.callbackQuery
                @Expect(gameCallback.gameShortName, "game-short-name")
                @Expect(narrowed.`match`.text, "game-short-name")
            case None => @Expect(false, true)
        }

        let inlineCtx = typeTestContext(Update.withInlineQuery(1406, InlineQuery(user, "inline-query")))
        match (inlineCtx.refineInlineQuery("inline-query")) {
            case Some(narrowed) =>
                let inline: InlineQuery = narrowed.inlineQuery
                @Expect(inline.query, "inline-query")
                @Expect(narrowed.`match`.text, "inline-query")
            case None => @Expect(false, true)
        }

        let chosenCtx = typeTestContext(Update.withChosenInlineResult(
            1407,
            ChosenInlineResult(user, "chosen-result", "inline-message")
        ))
        match (chosenCtx.refineChosenInlineResult("chosen-result")) {
            case Some(narrowed) =>
                let chosen: ChosenInlineResult = narrowed.chosenInlineResult
                @Expect(chosen.resultId, "chosen-result")
                @Expect(narrowed.`match`.text, "chosen-result")
            case None => @Expect(false, true)
        }

        let preCheckoutCtx = typeTestContext(Update.withPreCheckoutQuery(
            1408,
            PreCheckoutQuery(user, "pre-payload")
        ))
        match (preCheckoutCtx.refinePreCheckoutQuery("pre-payload")) {
            case Some(narrowed) =>
                let preCheckout: PreCheckoutQuery = narrowed.preCheckoutQuery
                @Expect(preCheckout.invoicePayload, "pre-payload")
                @Expect(narrowed.`match`.text, "pre-payload")
            case None => @Expect(false, true)
        }

        let shippingCtx = typeTestContext(Update.withShippingQuery(
            1409,
            ShippingQuery(user, "shipping-payload")
        ))
        match (shippingCtx.refineShippingQuery("shipping-payload")) {
            case Some(narrowed) =>
                let shipping: ShippingQuery = narrowed.shippingQuery
                @Expect(shipping.invoicePayload, "shipping-payload")
                @Expect(narrowed.`match`.text, "shipping-payload")
            case None => @Expect(false, true)
        }

        let reactionCtx = typeTestContext(Update.withMessageReaction(
            1410,
            MessageReactionUpdated(chat, user, 542, [], [ReactionType.emojiReaction("heart")])
        ))
        match (reactionCtx.refineReaction("heart")) {
            case Some(narrowed) =>
                let reaction: MessageReactionUpdated = narrowed.messageReaction
                @Expect(reaction.messageId, 542)
                @Expect(reaction.newReaction[0].emoji, "heart")
            case None => @Expect(false, true)
        }

        match (ctx.refineText("missing")) {
            case Some(_) => @Expect(false, true)
            case None => @Expect(true, true)
        }
    }

    @TestCase
    public func regexpPredicateAndRefineHelpersCompile(): Unit {
        let chat = Chat(142, "private")
        let user = User(242, false, "Grace", "grace")
        let message = Message(542, chat, "regex text", user)
        let ctx = typeTestContext(Update.withMessage(1411, message))

        @Expect(ctx.hasText(Regex("^regex")), true)
        let matchValue: String = typeMatchText(ctx.`match`)
        @Expect(matchValue, "regex")

        match (ctx.refineText(Regex("text$"))) {
            case Some(narrowed) =>
                let narrowedMessage: Message = narrowed.message
                @Expect(narrowedMessage.messageId, 542)
                @Expect(narrowed.`match`.text, "text")
            case None => @Expect(false, true)
        }

        let callbackCtx = typeTestContext(Update.withCallbackQuery(
            1412,
            CallbackQuery(user, "callback-regex", "", message, "")
        ))
        @Expect(callbackCtx.hasCallbackQuery(Regex("^callback")), true)
        match (callbackCtx.refineCallbackQuery([Regex("regex$")])) {
            case Some(narrowed) => @Expect(narrowed.`match`.text, "regex")
            case None => @Expect(false, true)
        }
    }

    @TestCase
    public func filteredContextSubstitutesExposeConcreteOptionalSurfaces(): Unit {
        let chat = Chat(143, "private")
        let user = User(243, false, "Hedy", "hedy")
        let message = Message(543, chat, "surface", user)

        match (typeTestContext(Update.withMessage(1413, message)).refineText("surface")) {
            case Some(narrowed) =>
                let narrowedContext: Context = narrowed.ctx
                let narrowedMessage: Message = narrowed.message
                let narrowedMatch: ContextMatch = narrowed.`match`
                @Expect(narrowedContext.updateId(), 1413)
                @Expect(narrowedMessage.text, "surface")
                @Expect(narrowedMatch.text, "surface")
            case None => @Expect(false, true)
        }

        let empty = typeTestContext(Update(1414))
        let maybeMessage: Option<Message> = empty.message
        let maybeChat: Option<Chat> = empty.chat
        let maybeMatch: Option<ContextMatch> = empty.`match`
        @Expect(optionPresent(maybeMessage), false)
        @Expect(optionPresent(maybeChat), false)
        @Expect(optionPresent(maybeMatch), false)
    }
}
