package grammy4cj.context

import std.regex.Regex
import std.unittest.*

import grammy4cj.core.Api
import grammy4cj.core.Payload
import grammy4cj.types.BusinessConnection
import grammy4cj.types.BusinessMessagesDeleted
import grammy4cj.types.CallbackQuery
import grammy4cj.types.Chat
import grammy4cj.types.ChatBoost
import grammy4cj.types.ChatBoostRemoved
import grammy4cj.types.ChatBoostSource
import grammy4cj.types.ChatBoostUpdated
import grammy4cj.types.ChatJoinRequest
import grammy4cj.types.ChatMemberUpdated
import grammy4cj.types.ChosenInlineResult
import grammy4cj.types.InlineQuery
import grammy4cj.types.ManagedBotUpdate
import grammy4cj.types.Message
import grammy4cj.types.MessageEntity
import grammy4cj.types.MessageReactionCountUpdated
import grammy4cj.types.MessageReactionUpdated
import grammy4cj.types.Poll
import grammy4cj.types.PollAnswer
import grammy4cj.types.PreCheckoutQuery
import grammy4cj.types.PurchasedPaidMedia
import grammy4cj.types.ReactionType
import grammy4cj.types.ShippingQuery
import grammy4cj.types.Update
import grammy4cj.types.User
import grammy4cj.types.UserFromGetMe

private func testBotInfo(): UserFromGetMe {
    UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
}

private func testContext(update: Update): Context {
    Context(update, Api.trace("token"), testBotInfo())
}

private func methodName(payload: Payload): String {
    for (field in payload.fields) {
        if (field.key == "__method") {
            return field.value
        }
    }
    ""
}

private func payloadBody(payload: Payload): String {
    for (field in payload.fields) {
        if (field.key == "__payload") {
            return field.value
        }
    }
    ""
}

private func throwsException(action: () -> Unit): Bool {
    try {
        action()
        false
    } catch (_: Exception) {
        true
    }
}

private func exceptionMessage(action: () -> Unit): String {
    try {
        action()
        ""
    } catch (err: Exception) {
        err.message
    }
}

private func matchText(value: Option<ContextMatch>): String {
    orThrow(value, "test").text
}

@Test
public class ContextGetterTest {
    @TestCase
    public func basicPropertiesExposeUpdateApiAndBotInfo(): Unit {
        let update = Update(120, "basic")
        let api = Api("token")
        let me = testBotInfo()
        let ctx = Context(update, api, me)
        @Expect(ctx.update.updateId, 120)
        @Expect(ctx.api.endpointFor("getMe"), api.endpointFor("getMe"))
        @Expect(ctx.me.id, 42)
        @Expect(ctx.updateId(), 120)
        @Expect(ctx.botInfoUsername(), "grammy4cj_bot")
    }

    @TestCase
    public func emptyUpdateReturnsNoneRatherThanSentinels(): Unit {
        let ctx = testContext(Update(2))
        @Expect(optionPresent(ctx.message), false)
        @Expect(optionPresent(ctx.chat), false)
        @Expect(optionPresent(ctx.msg), false)
        @Expect(optionPresent(ctx.from), false)
        @Expect(optionPresent(ctx.msgId), false)
        @Expect(optionPresent(ctx.chatId), false)
        @Expect(optionPresent(ctx.inlineMessageId), false)
        @Expect(optionPresent(ctx.businessConnectionId), false)
        @Expect(optionPresent(ctx.`match`), false)
        @Expect(throwsException({ => orThrow(ctx.chatId, "sendMessage") }), true)
        @Expect(ctx.entities().size, 0)
        @Expect(ctx.reactions().emoji.size, 0)
    }

    @TestCase
    public func aggregateGettersKeepGrammYPriorityWithOptions(): Unit {
        let chatA = Chat(101, "private")
        let chatB = Chat(102, "group")
        let userA = User(201, false, "Ada", "ada")
        let userB = User(202, false, "Grace", "grace")
        let update = Update(3, "mixed")
        let message = Message(21, chatA, "message", userA)
        message.senderChat = Chat(103, "channel")
        message.businessConnectionId = "bc-from-message"
        update.message = message
        update.editedMessage = Message(22, chatB, "edited", userB)
        update.messageReaction = MessageReactionUpdated(chatB, userB, 99, [], [])
        update.businessConnection = BusinessConnection("bc-from-update", userB, 999)
        update.deletedBusinessMessages = BusinessMessagesDeleted(chatB, "bc-deleted")
        update.callbackQuery = CallbackQuery(userB, "data", "", Message(23, chatB, "callback-message", userB), "inline-callback")
        update.chosenInlineResult = ChosenInlineResult(userA, "chosen", "inline-chosen")
        let ctx = testContext(update)
        @Expect(orThrow(ctx.msg, "test").messageId, 21)
        @Expect(orThrow(ctx.chat, "test").id, 101)
        @Expect(orThrow(ctx.senderChat, "test").id, 103)
        @Expect(orThrow(ctx.from, "test").id, 202)
        @Expect(orThrow(ctx.msgId, "test"), 21)
        @Expect(orThrow(ctx.chatId, "test"), 101)
        @Expect(orThrow(ctx.inlineMessageId, "test"), "inline-callback")
        @Expect(orThrow(ctx.businessConnectionId, "test"), "bc-from-message")
    }

    @TestCase
    public func topLevelAndAggregateOptionsExposePresentValues(): Unit {
        let chat = Chat(121, "private")
        let user = User(221, false, "Ada", "ada")
        let message = Message(321, chat, "message", user)
        message.businessConnectionId = "bc-message"
        let ctx = testContext(Update.withMessage(31, message))
        @Expect(orThrow(ctx.message, "test").messageId, 321)
        @Expect(orThrow(ctx.msg, "test").messageId, 321)
        @Expect(orThrow(ctx.chatId, "test"), 121)
        @Expect(orThrow(ctx.from, "test").id, 221)
        @Expect(orThrow(ctx.businessConnectionId, "test"), "bc-message")
        let callback = CallbackQuery(user, "callback-data", "", message, "inline-callback")
        @Expect(orThrow(testContext(Update.withCallbackQuery(38, callback)).inlineMessageId, "test"), "inline-callback")
    }

    @TestCase
    public func entitiesAndReactionsMirrorContextHelpers(): Unit {
        let chat = Chat(111, "private")
        let user = User(222, false, "Ada", "ada")
        let message = Message(31, chat, "hello link", user)
        message.addEntity(MessageEntity("bold", 0, 5))
        message.addEntity(MessageEntity("url", 6, 4))
        let ctx = testContext(Update.withMessage(4, message))
        @Expect(ctx.entities().size, 2)
        @Expect(ctx.entities("url")[0].text, "link")
        let reactionUpdate = Update.withMessageReaction(7, MessageReactionUpdated(chat, user, 32, [ReactionType.emojiReaction("plus"), ReactionType.customEmojiReaction("custom-old")], [ReactionType.emojiReaction("plus"), ReactionType.emojiReaction("heart"), ReactionType.paidReaction()]))
        let summary = testContext(reactionUpdate).reactions()
        @Expect(summary.emoji[0], "plus")
        @Expect(summary.emojiAdded[0], "heart")
        @Expect(summary.customEmojiRemoved[0], "custom-old")
        @Expect(summary.paid, true)
    }
}

@Test
public class ContextHasTest {
    @TestCase
    public func staticAndInstanceTextCommandChatCallbackAndReactionProbesWork(): Unit {
        let chat = Chat(123, "private")
        let user = User(456, false, "Ada", "ada")
        let message = Message(41, chat, "/start payload", user)
        message.addEntity(MessageEntity("bot_command", 0, 6))
        let ctx = testContext(Update.withMessage(6, message))

        @Expect(Context.has.filterQuery(":text").matches(ctx), true)
        @Expect(Context.has.text("/start payload").matches(ctx), true)
        @Expect(matchText(ctx.`match`), "/start payload")
        @Expect(ctx.hasCommand("start"), true)
        @Expect(matchText(ctx.`match`), "payload")
        @Expect(ctx.hasChatType("private"), true)
        @Expect(ctx.hasFilter("message"), true)
        @Expect(ctx.hasText("missing"), false)

        let callbackCtx = testContext(Update.withCallbackQuery(7, CallbackQuery(user, "clicked", Message(42, chat, "button", user))))
        @Expect(Context.has.callbackQuery("clicked").matches(callbackCtx), true)
        @Expect(callbackCtx.hasCallbackQuery("clicked"), true)
        @Expect(matchText(callbackCtx.`match`), "clicked")

        let reactionCtx = testContext(Update.withMessageReaction(
            8,
            MessageReactionUpdated(chat, user, 43, [], [ReactionType.emojiReaction("heart")])
        ))
        @Expect(Context.has.reaction("heart").matches(reactionCtx), true)
        @Expect(reactionCtx.hasReaction("heart"), true)
        @Expect(reactionCtx.hasReaction("plus"), false)
    }

    @TestCase
    public func filterQueryUsesSharedParserAndObjectMatcher(): Unit {
        let chat = Chat(125, "private")
        let user = User(458, false, "Lin", "lin")
        let message = Message(45, chat, "visit https://example.test", user)
        message.addEntity(MessageEntity("url", 6, 20))
        let ctx = testContext(Update.withMessage(9, message))

        @Expect(Context.has.filterQuery("::url").matches(ctx), true)
        @Expect(ctx.hasFilter("message::email"), false)

        let emptyMessage = Message()
        emptyMessage.messageId = 46
        emptyMessage.chat = chat
        emptyMessage.isPresent = true
        let emptyMessageCtx = testContext(Update.withMessage(10, emptyMessage))
        @Expect(Context.has.filterQuery(":text").matches(emptyMessageCtx), false)
        @Expect(Context.has.filterQuery(":caption").matches(emptyMessageCtx), false)
    }

    @TestCase
    public func staticAndInstanceTriggerArraysCoverQueryKinds(): Unit {
        let chat = Chat(124, "group")
        let user = User(457, false, "Grace", "grace")
        let message = Message(44, chat, "payload", user)

        let gameCtx = testContext(Update.withCallbackQuery(10, CallbackQuery(user, "", "game-a", message, "")))
        @Expect(Context.has.gameQuery(["missing", "game-a"]).matches(gameCtx), true)
        @Expect(gameCtx.hasGameQuery(["missing", "game-a"]), true)
        @Expect(matchText(gameCtx.`match`), "game-a")

        let inlineCtx = testContext(Update.withInlineQuery(11, InlineQuery(user, "inline-a")))
        @Expect(Context.has.inlineQuery(["missing", "inline-a"]).matches(inlineCtx), true)
        @Expect(inlineCtx.hasInlineQuery(["missing", "inline-a"]), true)
        @Expect(matchText(inlineCtx.`match`), "inline-a")

        let chosenCtx = testContext(Update.withChosenInlineResult(12, ChosenInlineResult(user, "chosen-a", "inline-message")))
        @Expect(Context.has.chosenInlineResult(["missing", "chosen-a"]).matches(chosenCtx), true)
        @Expect(chosenCtx.hasChosenInlineResult(["missing", "chosen-a"]), true)
        @Expect(matchText(chosenCtx.`match`), "chosen-a")

        let preCheckoutCtx = testContext(Update.withPreCheckoutQuery(13, PreCheckoutQuery(user, "pre-a")))
        @Expect(Context.has.preCheckoutQuery(["missing", "pre-a"]).matches(preCheckoutCtx), true)
        @Expect(preCheckoutCtx.hasPreCheckoutQuery(["missing", "pre-a"]), true)
        @Expect(matchText(preCheckoutCtx.`match`), "pre-a")

        let shippingCtx = testContext(Update.withShippingQuery(14, ShippingQuery(user, "ship-a")))
        @Expect(Context.has.shippingQuery(["missing", "ship-a"]).matches(shippingCtx), true)
        @Expect(shippingCtx.hasShippingQuery(["missing", "ship-a"]), true)
        @Expect(matchText(shippingCtx.`match`), "ship-a")
    }

    @TestCase
    public func regexpTriggersMirrorUpstreamContextHasAndInstancePredicates(): Unit {
        let chat = Chat(127, "private")
        let user = User(460, false, "Margaret", "margaret")

        let textCtx = testContext(Update.withMessage(166, Message(466, chat, "hello regex", user)))
        @Expect(Context.has.text(Regex("^hello")).matches(textCtx), true)
        @Expect(matchText(textCtx.`match`), "hello")
        @Expect(textCtx.hasText(Regex("h(ello) (regex)")), true)
        let captured = orThrow(textCtx.`match`, "test")
        @Expect(captured.isRegex, true)
        @Expect(captured.values.size, 3)
        @Expect(captured.values[0], "hello regex")
        @Expect(captured.values[1], "ello")
        @Expect(captured.values[2], "regex")
        @Expect(textCtx.hasText(Regex("regex$")), true)
        @Expect(matchText(textCtx.`match`), "regex")
        @Expect(textCtx.hasText([Regex("^missing"), Regex("llo")]), true)
        @Expect(matchText(textCtx.`match`), "llo")
        @Expect(textCtx.hasText(Regex("^missing")), false)
        @Expect(matchText(textCtx.`match`), "llo")

        let callbackCtx = testContext(Update.withCallbackQuery(167, CallbackQuery(user, "clicked", Message(467, chat, "button", user))))
        @Expect(Context.has.callbackQuery(Regex("^cl.ck")).matches(callbackCtx), true)
        @Expect(matchText(callbackCtx.`match`), "click")
        @Expect(callbackCtx.hasCallbackQuery(Regex("ked$")), true)
        @Expect(matchText(callbackCtx.`match`), "ked")
        @Expect(callbackCtx.hasCallbackQuery([Regex("^missing"), Regex("ick")]), true)
        @Expect(matchText(callbackCtx.`match`), "ick")

        let gameCtx = testContext(Update.withCallbackQuery(168, CallbackQuery(user, "", "game-a", Message(468, chat, "game", user), "")))
        @Expect(Context.has.gameQuery(Regex("^game")).matches(gameCtx), true)
        @Expect(matchText(gameCtx.`match`), "game")
        @Expect(gameCtx.hasGameQuery([Regex("^missing"), Regex("a$")]), true)
        @Expect(matchText(gameCtx.`match`), "a")

        let inlineCtx = testContext(Update.withInlineQuery(169, InlineQuery(user, "inline-a")))
        @Expect(Context.has.inlineQuery(Regex("^in")).matches(inlineCtx), true)
        @Expect(matchText(inlineCtx.`match`), "in")
        @Expect(inlineCtx.hasInlineQuery([Regex("^missing"), Regex("line")]), true)
        @Expect(matchText(inlineCtx.`match`), "line")

        let chosenCtx = testContext(Update.withChosenInlineResult(170, ChosenInlineResult(user, "chosen-a", "inline-message")))
        @Expect(Context.has.chosenInlineResult(Regex("^cho")).matches(chosenCtx), true)
        @Expect(matchText(chosenCtx.`match`), "cho")
        @Expect(chosenCtx.hasChosenInlineResult([Regex("^missing"), Regex("sen")]), true)
        @Expect(matchText(chosenCtx.`match`), "sen")

        let preCheckoutCtx = testContext(Update.withPreCheckoutQuery(171, PreCheckoutQuery(user, "pre-a")))
        @Expect(Context.has.preCheckoutQuery(Regex("^pre")).matches(preCheckoutCtx), true)
        @Expect(matchText(preCheckoutCtx.`match`), "pre")
        @Expect(preCheckoutCtx.hasPreCheckoutQuery([Regex("^missing"), Regex("e-a$")]), true)
        @Expect(matchText(preCheckoutCtx.`match`), "e-a")

        let shippingCtx = testContext(Update.withShippingQuery(172, ShippingQuery(user, "ship-a")))
        @Expect(Context.has.shippingQuery(Regex("^ship")).matches(shippingCtx), true)
        @Expect(matchText(shippingCtx.`match`), "ship")
        @Expect(shippingCtx.hasShippingQuery([Regex("^missing"), Regex("ip-a$")]), true)
        @Expect(matchText(shippingCtx.`match`), "ip-a")

        match (callbackCtx.refineCallbackQuery(Regex("^cli"))) {
            case Some(narrowed) => @Expect(matchText(narrowed.`match`), "cli")
            case None => @Expect(false, true)
        }
    }

    @TestCase
    public func textTriggerObjectsAreRegexpFunctionAlternative(): Unit {
        let chat = Chat(128, "private")
        let user = User(461, false, "Alonzo", "alonzo")
        let ctx = testContext(Update.withMessage(18, Message(48, chat, "alpha beta", user)))

        @Expect(ctx.hasText(TextTrigger.contains("pha")), true)
        @Expect(matchText(ctx.`match`), "pha")
        @Expect(ctx.hasText(TextTrigger.prefix("alpha")), true)
        @Expect(matchText(ctx.`match`), "alpha")
        @Expect(ctx.hasText(TextTrigger.suffix("beta")), true)
        @Expect(matchText(ctx.`match`), "beta")
        @Expect(ctx.hasText(TextTrigger.contains("gamma")), false)
        @Expect(matchText(ctx.`match`), "beta")

        let inlineCtx = testContext(Update.withInlineQuery(19, InlineQuery(user, "inline-value")))
        @Expect(Context.has.inlineQuery(TextTrigger.contains("line")).matches(inlineCtx), true)
        @Expect(matchText(inlineCtx.`match`), "line")

        @Expect(triggerFn("exact").matchValue("exact"), "exact")
        @Expect(triggerFn(["missing", "array"]).matchValue("array"), "array")
        @Expect(triggerFn(TextTrigger.prefix("pre")).matchValue("prefix"), "pre")
        @Expect(triggerFn(Regex("^ex")).matchValue("exact"), "ex")
        @Expect(triggerFn([Regex("^missing"), Regex("act$")]).matchValue("exact"), "act")
        @Expect(toArray("single").size, 1)
        @Expect(toArray(["one", "two"]).size, 2)
    }

    @TestCase
    public func matchIsWrittenOnlyBySuccessfulTriggerProbes(): Unit {
        let chat = Chat(125, "private")
        let user = User(458, false, "Lin", "lin")
        let message = Message(45, chat, "alpha", user)
        let ctx = testContext(Update.withMessage(15, message))

        @Expect(ctx.hasText("alpha"), true)
        @Expect(matchText(ctx.`match`), "alpha")
        @Expect(ctx.hasText("beta"), false)
        @Expect(matchText(ctx.`match`), "alpha")

        let emptyMatchCtx = testContext(Update.withMessage(16, Message(46, chat, "gamma", user)))
        @Expect(optionPresent(emptyMatchCtx.`match`), false)
        @Expect(emptyMatchCtx.hasText("delta"), false)
        @Expect(optionPresent(emptyMatchCtx.`match`), false)
    }

    @TestCase
    public func emptyStringAndEmptyRegexTriggersMirrorUpstreamMatchTruthiness(): Unit {
        let chat = Chat(134, "private")
        let user = User(465, false, "Hedy", "hedy")

        let emptyTextCtx = testContext(Update.withMessage(173, Message(473, chat, "", user)))
        @Expect(emptyTextCtx.hasText(""), false)
        @Expect(optionPresent(emptyTextCtx.`match`), false)
        @Expect(emptyTextCtx.hasText(Regex("^")), true)
        let emptyRegexMatch = orThrow(emptyTextCtx.`match`, "test")
        @Expect(emptyRegexMatch.isRegex, true)
        @Expect(emptyRegexMatch.text, "")

        let callbackCtx = testContext(Update.withCallbackQuery(174, CallbackQuery(user, "", Message(474, chat, "button", user))))
        @Expect(callbackCtx.hasCallbackQuery(""), false)
        @Expect(callbackCtx.hasCallbackQuery(Regex("^")), false)
        @Expect(optionPresent(callbackCtx.`match`), false)
    }

    @TestCase
    public func failedTriggerProbesDoNotOverwriteExistingMatchAcrossKinds(): Unit {
        let chat = Chat(131, "private")
        let user = User(463, false, "Evelyn", "evelyn")

        let emptyText = testContext(Update.withMessage(151, Message(451, chat, "", user)))
        emptyText.`match` = Some(ContextMatch.string("seed"))
        @Expect(emptyText.hasText(""), false)
        @Expect(matchText(emptyText.`match`), "seed")

        let commandMessage = Message(452, chat, "/start payload", user)
        commandMessage.addEntity(MessageEntity("bot_command", 0, 6))
        let commandCtx = testContext(Update.withMessage(152, commandMessage))
        commandCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(commandCtx.hasCommand("help"), false)
        @Expect(matchText(commandCtx.`match`), "seed")

        let callbackCtx = testContext(Update.withCallbackQuery(153, CallbackQuery(user, "clicked", Message(453, chat, "button", user))))
        callbackCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(callbackCtx.hasCallbackQuery("missing"), false)
        @Expect(matchText(callbackCtx.`match`), "seed")

        let gameCtx = testContext(Update.withCallbackQuery(154, CallbackQuery(user, "", "game-a", Message(454, chat, "game", user), "")))
        gameCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(gameCtx.hasGameQuery("missing"), false)
        @Expect(matchText(gameCtx.`match`), "seed")

        let inlineCtx = testContext(Update.withInlineQuery(155, InlineQuery(user, "inline-a")))
        inlineCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(inlineCtx.hasInlineQuery("missing"), false)
        @Expect(matchText(inlineCtx.`match`), "seed")

        let chosenCtx = testContext(Update.withChosenInlineResult(156, ChosenInlineResult(user, "chosen-a", "inline-message")))
        chosenCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(chosenCtx.hasChosenInlineResult("missing"), false)
        @Expect(matchText(chosenCtx.`match`), "seed")

        let preCheckoutCtx = testContext(Update.withPreCheckoutQuery(157, PreCheckoutQuery(user, "pre-a")))
        preCheckoutCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(preCheckoutCtx.hasPreCheckoutQuery("missing"), false)
        @Expect(matchText(preCheckoutCtx.`match`), "seed")

        let shippingCtx = testContext(Update.withShippingQuery(158, ShippingQuery(user, "ship-a")))
        shippingCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(shippingCtx.hasShippingQuery("missing"), false)
        @Expect(matchText(shippingCtx.`match`), "seed")

        let missingCtx = testContext(Update(159))
        missingCtx.`match` = Some(ContextMatch.string("seed"))
        @Expect(missingCtx.hasText("anything"), false)
        @Expect(missingCtx.hasCallbackQuery("anything"), false)
        @Expect(missingCtx.hasReaction("heart"), false)
        @Expect(matchText(missingCtx.`match`), "seed")
    }

    @TestCase
    public func commandProbeMatchesOnlyTargetedBotMentions(): Unit {
        let chat = Chat(126, "private")
        let user = User(459, false, "Edsger", "edsger")

        let targeted = Message(46, chat, "/start@GrAmMy4Cj_BoT payload", user)
        targeted.addEntity(MessageEntity("bot_command", 0, 20))
        let targetedCtx = testContext(Update.withMessage(16, targeted))
        @Expect(targetedCtx.hasCommand("start"), true)
        @Expect(matchText(targetedCtx.`match`), "payload")

        let otherBot = Message(47, chat, "/start@other_bot payload", user)
        otherBot.addEntity(MessageEntity("bot_command", 0, 16))
        let otherBotCtx = testContext(Update.withMessage(17, otherBot))
        @Expect(otherBotCtx.hasCommand("start"), false)
    }

    @TestCase
    public func commandProbeReadsChannelPostsLikeMessages(): Unit {
        let chat = Chat(132, "channel")
        let channelPost = Message(461, chat, "/publish payload")
        channelPost.addEntity(MessageEntity("bot_command", 0, 8))
        let ctx = testContext(Update.withChannelPost(160, channelPost))

        @Expect(ctx.hasText("/publish payload"), true)
        @Expect(matchText(ctx.`match`), "/publish payload")
        @Expect(ctx.hasCommand("publish"), true)
        @Expect(matchText(ctx.`match`), "payload")
    }

    @TestCase
    public func commandProbeRejectsSlashPrefix(): Unit {
        @Expect(
            exceptionMessage({ => Context.has.command("/start") }),
            "Do not include '/' when registering command handlers (use 'start' not '/start')"
        )
        @Expect(
            exceptionMessage({ => Context.has.command(["help", "/start"]) }),
            "Do not include '/' when registering command handlers (use 'start' not '/start')"
        )
    }

    @TestCase
    public func reactionProbeMatchesOnlyNewWantedReactionsAndUnsupportedKinds(): Unit {
        let chat = Chat(133, "private")
        let user = User(464, false, "Katherine", "katherine")

        let customNew = testContext(Update.withMessageReaction(
            161,
            MessageReactionUpdated(chat, user, 461, [], [ReactionType.customEmojiReaction("custom-1")])
        ))
        @Expect(customNew.hasReaction(ReactionType.customEmojiReaction("custom-1")), true)

        let customKept = testContext(Update.withMessageReaction(
            162,
            MessageReactionUpdated(
                chat,
                user,
                462,
                [ReactionType.customEmojiReaction("custom-1")],
                [ReactionType.customEmojiReaction("custom-1")]
            )
        ))
        @Expect(customKept.hasReaction(ReactionType.customEmojiReaction("custom-1")), false)

        let paidNew = testContext(Update.withMessageReaction(
            163,
            MessageReactionUpdated(chat, user, 463, [], [ReactionType.paidReaction()])
        ))
        @Expect(paidNew.hasReaction(ReactionType.paidReaction()), true)

        let paidKept = testContext(Update.withMessageReaction(
            164,
            MessageReactionUpdated(chat, user, 464, [ReactionType.paidReaction()], [ReactionType.paidReaction()])
        ))
        @Expect(paidKept.hasReaction(ReactionType.paidReaction()), false)

        let unsupported = testContext(Update.withMessageReaction(
            165,
            MessageReactionUpdated(chat, user, 465, [], [ReactionType("unsupported", "", "")])
        ))
        @Expect(unsupported.hasReaction("heart"), true)
    }

    @TestCase
    public func orThrowAcceptsValuesAndRejectsSentinels(): Unit {
        let chat = Chat(129, "private")
        let user = User(462, false, "Barbara", "barbara")
        let message = Message(49, chat, "payload", user)

        @Expect(orThrow(1, "int"), 1)
        @Expect(orThrow("value", "string"), "value")
        @Expect(orThrow(user, "user").id, 462)
        @Expect(orThrow(message, "message").messageId, 49)
        @Expect(throwsException({ => orThrow(0, "int") }), true)
        @Expect(throwsException({ => orThrow("", "string") }), true)
        @Expect(throwsException({ => orThrow(User(), "user") }), true)
        @Expect(throwsException({ => orThrow(Message(), "message") }), true)
    }
}

@Test
public class ContextShortcutTest {
    @TestCase
    public func shortcutMappingTableCoversAvailableApiWrapperSkeleton(): Unit {
        let mappings = contextShortcutMappings()

        @Expect(mappings.size, 136)
        @Expect(contextShortcutApiTargets().size, 136)
        @Expect(mappings[0].shortcut, "answerCallbackQuery")
        @Expect(mappings[0].apiMethod, "answerCallbackQuery")
        @Expect(contextShortcutRequiredContext("answerCallbackQuery"), "callback_query_id")
        @Expect(contextShortcutRequiredContext("setChatMenuButton"), "none")
        @Expect(contextShortcutRequiredContext("editMessageTextInline"), "inline_message_id")
    }

    @TestCase
    public func contextSourceDriftGateLocksUpstreamContextSurfaceCounts(): Unit {
        let rows = contextSourceDriftGate()

        @Expect(rows.size, 5)
        @Expect(contextSourceDriftGateOk(), true)
        @Expect(contextUpdateShortcutNames().size, 24)
        @Expect(contextAggregateShortcutNames().size, 8)
        @Expect(contextHasPredicateFamilies().size, 11)
        @Expect(contextMatchWriterFamilies().size, 8)
        @Expect(contextShortcutApiTargets().size, 136)
        @Expect(rows[0].upstreamAnchor, "src/context.ts update shortcuts")
        @Expect(rows[4].contract, "Context typed API shortcut targets")
    }

    @TestCase
    public func replyBuildsRunnablePayloadThroughApiWrapperSkeleton(): Unit {
        let chat = Chat(777, "private")
        let user = User(888, false, "Ada", "ada")
        let message = Message(51, chat, "incoming", user)
        let ctx = testContext(Update.withMessage(9, message))

        let payload = ctx.reply("pong")

        @Expect(methodName(payload), "sendMessage")
        @Expect(payloadBody(payload).contains("\"chat_id\":777"), true)
        @Expect(payloadBody(payload).contains("\"text\":\"pong\""), true)
    }

    @TestCase
    public func replyFamilyPrefillsChatBusinessThreadAndChatActionTopic(): Unit {
        let chat = Chat(701, "supergroup")
        let user = User(801, false, "Ada", "ada")
        let message = Message(901, chat, "incoming", user)
        message.businessConnectionId = "bc-701"
        message.isTopicMessage = true
        message.messageThreadId = 77
        message.directMessagesTopicId = 88
        let ctx = testContext(Update.withMessage(101, message))

        let payload = ctx.replyWithChatAction("typing")

        @Expect(methodName(payload), "sendChatAction")
        @Expect(payloadBody(payload).contains("\"chat_id\":701"), true)
        @Expect(payloadBody(payload).contains("\"business_connection_id\":\"bc-701\""), true)
        @Expect(payloadBody(payload).contains("\"message_thread_id\":77"), true)
        @Expect(payloadBody(payload).contains("\"direct_messages_topic_id\""), false)
        @Expect(payloadBody(payload).contains("\"action\":\"typing\""), true)
    }

    @TestCase
    public func replyFamilyDirectTopicMatrixMatchesUpstreamShortcuts(): Unit {
        let chat = Chat(707, "supergroup")
        let user = User(807, false, "Ada", "ada")
        let message = Message(907, chat, "incoming", user)
        message.businessConnectionId = "bc-707"
        message.isTopicMessage = true
        message.messageThreadId = 71
        message.directMessagesTopicId = 72
        let ctx = testContext(Update.withMessage(112, message))

        let reply = ctx.reply("pong")
        @Expect(methodName(reply), "sendMessage")
        @Expect(payloadBody(reply).contains("\"business_connection_id\":\"bc-707\""), true)
        @Expect(payloadBody(reply).contains("\"message_thread_id\":71"), true)
        @Expect(payloadBody(reply).contains("\"direct_messages_topic_id\":72"), true)

        let draft = ctx.replyWithDraft("draft")
        @Expect(methodName(draft), "sendMessageDraft")
        @Expect(payloadBody(draft).contains("\"update_id\":112"), true)
        @Expect(payloadBody(draft).contains("\"message_thread_id\":71"), true)
        @Expect(payloadBody(draft).contains("\"business_connection_id\""), false)
        @Expect(payloadBody(draft).contains("\"direct_messages_topic_id\""), false)

        let poll = ctx.replyWithPoll("question", "[\"yes\",\"no\"]")
        @Expect(methodName(poll), "sendPoll")
        @Expect(payloadBody(poll).contains("\"business_connection_id\":\"bc-707\""), true)
        @Expect(payloadBody(poll).contains("\"message_thread_id\":71"), true)
        @Expect(payloadBody(poll).contains("\"direct_messages_topic_id\""), false)

        let game = ctx.replyWithGame("short-game")
        @Expect(methodName(game), "sendGame")
        @Expect(payloadBody(game).contains("\"business_connection_id\":\"bc-707\""), true)
        @Expect(payloadBody(game).contains("\"message_thread_id\":71"), true)
        @Expect(payloadBody(game).contains("\"direct_messages_topic_id\""), false)

        let invoice = ctx.replyWithInvoice("title", "description", "invoice-payload", "USD", "[{\"label\":\"price\",\"amount\":100}]")
        @Expect(methodName(invoice), "sendInvoice")
        @Expect(payloadBody(invoice).contains("\"message_thread_id\":71"), true)
        @Expect(payloadBody(invoice).contains("\"direct_messages_topic_id\":72"), true)
        @Expect(payloadBody(invoice).contains("\"business_connection_id\""), false)
    }

    @TestCase
    public func forwardCopyDeleteAndReactionShortcutsUseTypedPayloads(): Unit {
        let chat = Chat(706, "private")
        let user = User(806, false, "Donald", "donald")
        let message = Message(906, chat, "incoming", user)
        message.directMessagesTopicId = 73
        let ctx = testContext(Update.withMessage(111, message))

        let forward = ctx.forwardMessage(9001)
        @Expect(methodName(forward), "forwardMessage")
        @Expect(payloadBody(forward).contains("\"chat_id\":9001"), true)
        @Expect(payloadBody(forward).contains("\"from_chat_id\":706"), true)
        @Expect(payloadBody(forward).contains("\"message_id\":906"), true)
        @Expect(payloadBody(forward).contains("\"direct_messages_topic_id\":73"), true)

        let forwardMany = ctx.forwardMessages(9002, [906, 907])
        @Expect(methodName(forwardMany), "forwardMessages")
        @Expect(payloadBody(forwardMany).contains("\"message_ids\":[906,907]"), true)
        @Expect(payloadBody(forwardMany).contains("\"direct_messages_topic_id\":73"), true)

        let copy = ctx.copyMessage(9003)
        @Expect(methodName(copy), "copyMessage")
        @Expect(payloadBody(copy).contains("\"from_chat_id\":706"), true)
        @Expect(payloadBody(copy).contains("\"message_id\":906"), true)
        @Expect(payloadBody(copy).contains("\"direct_messages_topic_id\":73"), true)

        let copyMany = ctx.copyMessages(9004, [908, 909])
        @Expect(methodName(copyMany), "copyMessages")
        @Expect(payloadBody(copyMany).contains("\"message_ids\":[908,909]"), true)
        @Expect(payloadBody(copyMany).contains("\"direct_messages_topic_id\":73"), true)

        let deleteMany = ctx.deleteMessages([906, 907])
        @Expect(methodName(deleteMany), "deleteMessages")
        @Expect(payloadBody(deleteMany).contains("\"message_ids\":[906,907]"), true)

        let reaction = ctx.react([ReactionType.emojiReaction("heart"), ReactionType.customEmojiReaction("custom-1")])
        @Expect(methodName(reaction), "setMessageReaction")
        @Expect(payloadBody(reaction).contains("\"reaction\":[{\"type\":\"emoji\",\"emoji\":\"heart\"},{\"type\":\"custom_emoji\",\"custom_emoji_id\":\"custom-1\"}]"), true)
    }

    @TestCase
    public func editShortcutsSelectMessageOrInlineTarget(): Unit {
        let chat = Chat(702, "private")
        let user = User(802, false, "Grace", "grace")
        let messageCtx = testContext(Update.withMessage(102, Message(902, chat, "incoming", user)))

        let messagePayload = messageCtx.editMessageText("edited")

        @Expect(methodName(messagePayload), "editMessageText")
        @Expect(payloadBody(messagePayload).contains("\"chat_id\":702"), true)
        @Expect(payloadBody(messagePayload).contains("\"message_id\":902"), true)
        @Expect(payloadBody(messagePayload).contains("\"text\":\"edited\""), true)

        let inlineCtx = testContext(Update.withCallbackQuery(
            103,
            CallbackQuery(user, "callback-id", "", Message(), "inline-902")
        ))
        let inlinePayload = inlineCtx.editMessageText("inline-edited")

        @Expect(methodName(inlinePayload), "editMessageText")
        @Expect(payloadBody(inlinePayload).contains("\"inline_message_id\":\"inline-902\""), true)
        @Expect(payloadBody(inlinePayload).contains("\"text\":\"inline-edited\""), true)
    }

    @TestCase
    public func adminMemberAndForumShortcutsPrefillContextTargets(): Unit {
        let chat = Chat(703, "supergroup")
        let user = User(803, false, "Lin", "lin")
        let message = Message(903, chat, "topic", user)
        message.isTopicMessage = true
        message.messageThreadId = 33
        let ctx = testContext(Update.withMessage(104, message))

        let ban = ctx.banAuthor()
        @Expect(methodName(ban), "banChatMember")
        @Expect(payloadBody(ban).contains("\"chat_id\":703"), true)
        @Expect(payloadBody(ban).contains("\"user_id\":803"), true)

        let restrict = ctx.restrictChatMember(804, "{\"can_send_messages\":false}")
        @Expect(methodName(restrict), "restrictChatMember")
        @Expect(payloadBody(restrict).contains("\"user_id\":804"), true)
        @Expect(payloadBody(restrict).contains("\"permissions\":{\"can_send_messages\":false}"), true)

        let forum = ctx.closeForumTopic()
        @Expect(methodName(forum), "closeForumTopic")
        @Expect(payloadBody(forum).contains("\"chat_id\":703"), true)
        @Expect(payloadBody(forum).contains("\"message_thread_id\":33"), true)
    }

    @TestCase
    public func businessGiftStoryAndReadShortcutsPrefillBusinessConnection(): Unit {
        let chat = Chat(704, "private")
        let user = User(804, false, "Edsger", "edsger")
        let message = Message(904, chat, "business", user)
        message.businessConnectionId = "bc-704"
        let ctx = testContext(Update.withMessage(105, message))

        let name = ctx.setBusinessAccountName("NewName")
        @Expect(methodName(name), "setBusinessAccountName")
        @Expect(payloadBody(name).contains("\"business_connection_id\":\"bc-704\""), true)
        @Expect(payloadBody(name).contains("\"first_name\":\"NewName\""), true)

        let checklist = ctx.replyWithChecklist("{\"title\":\"todo\"}")
        @Expect(methodName(checklist), "sendChecklist")
        @Expect(payloadBody(checklist).contains("\"chat_id\":704"), true)
        @Expect(payloadBody(checklist).contains("\"checklist\":{\"title\":\"todo\"}"), true)

        let story = ctx.postStory("{\"type\":\"photo\"}", 86400)
        @Expect(methodName(story), "postStory")
        @Expect(payloadBody(story).contains("\"active_period\":86400"), true)

        let read = ctx.readBusinessMessage()
        @Expect(methodName(read), "readBusinessMessage")
        @Expect(payloadBody(read).contains("\"message_id\":904"), true)

        let deleted = ctx.deleteBusinessMessages([904, 905])
        @Expect(methodName(deleted), "deleteBusinessMessages")
        @Expect(payloadBody(deleted).contains("\"message_ids\":[904,905]"), true)
    }

    @TestCase
    public func queryPaymentFileAndMenuShortcutsBuildPayloads(): Unit {
        let chat = Chat(705, "private")
        let user = User(805, false, "Barbara", "barbara")

        let callbackCtx = testContext(Update.withCallbackQuery(106, CallbackQuery(user, "callback-id", Message(905, chat, "cb", user))))
        let callback = callbackCtx.answerCallbackQuery("ok")
        @Expect(methodName(callback), "answerCallbackQuery")
        @Expect(payloadBody(callback).contains("\"callback_query_id\":\"callback-id\""), true)
        let callbackWithoutText = callbackCtx.answerCallbackQuery()
        @Expect(methodName(callbackWithoutText), "answerCallbackQuery")
        @Expect(payloadBody(callbackWithoutText).contains("\"text\""), false)

        let inlineCtx = testContext(Update.withInlineQuery(107, InlineQuery(user, "inline-id")))
        let inline = inlineCtx.answerInlineQuery("[{\"type\":\"article\",\"id\":\"1\"}]")
        @Expect(methodName(inline), "answerInlineQuery")
        @Expect(payloadBody(inline).contains("\"inline_query_id\":\"inline-id\""), true)
        @Expect(payloadBody(inline).contains("\"results\":[{\"type\":\"article\",\"id\":\"1\"}]"), true)

        let shippingCtx = testContext(Update.withShippingQuery(108, ShippingQuery(user, "shipping-id")))
        let shipping = shippingCtx.answerShippingQuery(true)
        @Expect(methodName(shipping), "answerShippingQuery")
        @Expect(payloadBody(shipping).contains("\"shipping_query_id\":\"shipping-id\""), true)

        let preCheckoutCtx = testContext(Update.withPreCheckoutQuery(108, PreCheckoutQuery(user, "pre-checkout-id")))
        let preCheckout = preCheckoutCtx.answerPreCheckoutQuery(false, "sold out")
        @Expect(methodName(preCheckout), "answerPreCheckoutQuery")
        @Expect(payloadBody(preCheckout).contains("\"pre_checkout_query_id\":\"pre-checkout-id\""), true)
        @Expect(payloadBody(preCheckout).contains("\"error_message\":\"sold out\""), true)

        let profileCtx = testContext(Update.withMessage(109, Message(906, chat, "pay", user)))
        let profile = profileCtx.getUserProfilePhotos()
        @Expect(methodName(profile), "getUserProfilePhotos")
        @Expect(payloadBody(profile).contains("\"user_id\":805"), true)

        let file = profileCtx.getFile("file-805")
        @Expect(methodName(file), "getFile")
        @Expect(payloadBody(file).contains("\"file_id\":\"file-805\""), true)

        let menu = profileCtx.setChatMenuButton()
        @Expect(methodName(menu), "setChatMenuButton")
        @Expect(payloadBody(menu), "{}")

        let gift = profileCtx.replyWithGift("gift-1")
        @Expect(methodName(gift), "sendGift")
        @Expect(payloadBody(gift).contains("\"user_id\":805"), true)
        @Expect(payloadBody(gift).contains("\"gift_id\":\"gift-1\""), true)

        let premium = profileCtx.giftPremiumSubscription(3, 1000)
        @Expect(methodName(premium), "giftPremiumSubscription")
        @Expect(payloadBody(premium).contains("\"month_count\":3"), true)
        @Expect(payloadBody(premium).contains("\"star_count\":1000"), true)

        let refund = profileCtx.refundStarPayment("charge-805")
        @Expect(methodName(refund), "refundStarPayment")
        @Expect(payloadBody(refund).contains("\"telegram_payment_charge_id\":\"charge-805\""), true)
    }

    @TestCase
    public func missingRequiredContextThrowsForEachShortcutFamily(): Unit {
        let empty = testContext(Update(110))

        @Expect(throwsException({ => empty.reply("no chat") }), true)
        @Expect(throwsException({ => empty.forwardMessage(1) }), true)
        @Expect(throwsException({ => empty.copyMessage(1) }), true)
        @Expect(throwsException({ => empty.deleteMessage() }), true)
        @Expect(throwsException({ => empty.react("heart") }), true)
        @Expect(throwsException({ => empty.banAuthor() }), true)
        @Expect(throwsException({ => empty.getAuthor() }), true)
        @Expect(throwsException({ => empty.closeForumTopic() }), true)
        @Expect(throwsException({ => empty.getBusinessConnection() }), true)
        @Expect(throwsException({ => empty.deleteBusinessMessages([1]) }), true)
        @Expect(throwsException({ => empty.postStory("{\"type\":\"photo\"}", 86400) }), true)
        @Expect(throwsException({ => empty.answerInlineQuery("[]") }), true)
        @Expect(throwsException({ => empty.answerCallbackQuery("missing") }), true)
        @Expect(throwsException({ => empty.answerShippingQuery(true) }), true)
        @Expect(throwsException({ => empty.answerPreCheckoutQuery(true) }), true)
        @Expect(throwsException({ => empty.getUserProfilePhotos() }), true)
        @Expect(throwsException({ => empty.replyWithGift("gift") }), true)
        @Expect(throwsException({ => empty.refundStarPayment("charge") }), true)
        @Expect(throwsException({ => empty.readBusinessMessage() }), true)
    }

    @TestCase
    public func missingContextErrorMethodNamesMirrorUpstreamAliasImplementations(): Unit {
        let empty = testContext(Update(113))

        @Expect(exceptionMessage({ => empty.setAuthorTag("tag") }), "Missing information for API call to setChatMemberTag")
        @Expect(exceptionMessage({ => empty.revokeChatInviteLink("invite") }), "Missing information for API call to editChatInviteLink")
        @Expect(exceptionMessage({ => empty.replaceManagedBotToken() }), "Missing information for API call to getManagedBotToken")
    }
}
