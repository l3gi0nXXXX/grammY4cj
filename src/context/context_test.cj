package grammy4cj.context

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
    Context(update, Api("token"), testBotInfo())
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

@Test
public class ContextGetterTest {
    @TestCase
    public func topLevelUpdateGettersMapToUpdateFields(): Unit {
        let chat = Chat(100, "private")
        let user = User(200, false, "Ada", "ada")
        let update = Update(1, "mixed")

        update.message = Message(10, chat, "message", user)
        update.editedMessage = Message(11, chat, "edited", user)
        update.channelPost = Message(12, chat, "channel", user)
        update.editedChannelPost = Message(13, chat, "edited-channel", user)
        update.businessConnection = BusinessConnection("bc-1", user, 300)
        update.businessMessage = Message(14, chat, "business", user)
        update.editedBusinessMessage = Message(15, chat, "edited-business", user)
        update.deletedBusinessMessages = BusinessMessagesDeleted(chat, "bc-deleted")
        update.messageReaction = MessageReactionUpdated(chat, user, 16, [], [ReactionType.emojiReaction("plus")])
        update.messageReactionCount = MessageReactionCountUpdated(chat, 17)
        update.inlineQuery = InlineQuery(user, "inline")
        update.chosenInlineResult = ChosenInlineResult(user, "chosen", "inline-msg-1")
        update.callbackQuery = CallbackQuery(user, "callback", Message(18, chat, "callback-message", user))
        update.shippingQuery = ShippingQuery(user, "ship")
        update.preCheckoutQuery = PreCheckoutQuery(user, "pre")
        update.poll = Poll("poll-1")
        update.pollAnswer = PollAnswer(user, "poll-2")
        update.myChatMember = ChatMemberUpdated(chat, user)
        update.chatMember = ChatMemberUpdated(chat, user)
        update.managedBot = ManagedBotUpdate(user)
        update.chatJoinRequest = ChatJoinRequest(chat, user)
        update.chatBoost = ChatBoostUpdated(chat, ChatBoost(ChatBoostSource(user)))
        update.removedChatBoost = ChatBoostRemoved(chat, ChatBoostSource(user))
        update.purchasedPaidMedia = PurchasedPaidMedia(user)

        let ctx = testContext(update)

        @Expect(ctx.message.messageId, 10)
        @Expect(ctx.editedMessage.messageId, 11)
        @Expect(ctx.channelPost.messageId, 12)
        @Expect(ctx.editedChannelPost.messageId, 13)
        @Expect(ctx.businessConnection.id, "bc-1")
        @Expect(ctx.businessMessage.messageId, 14)
        @Expect(ctx.editedBusinessMessage.messageId, 15)
        @Expect(ctx.deletedBusinessMessages.businessConnectionId, "bc-deleted")
        @Expect(ctx.messageReaction.messageId, 16)
        @Expect(ctx.messageReactionCount.messageId, 17)
        @Expect(ctx.inlineQuery.query, "inline")
        @Expect(ctx.chosenInlineResult.resultId, "chosen")
        @Expect(ctx.callbackQuery.data, "callback")
        @Expect(ctx.shippingQuery.invoicePayload, "ship")
        @Expect(ctx.preCheckoutQuery.invoicePayload, "pre")
        @Expect(ctx.poll.id, "poll-1")
        @Expect(ctx.pollAnswer.pollId, "poll-2")
        @Expect(ctx.myChatMember.chat.id, 100)
        @Expect(ctx.chatMember.user.id, 200)
        @Expect(ctx.managedBot.user.id, 200)
        @Expect(ctx.chatJoinRequest.chat.id, 100)
        @Expect(ctx.chatBoost.chat.id, 100)
        @Expect(ctx.removedChatBoost.chat.id, 100)
        @Expect(ctx.purchasedPaidMedia.user.id, 200)
    }

    @TestCase
    public func emptyUpdateReturnsEmptySentinelsAndOrThrowErrors(): Unit {
        let ctx = testContext(Update(2))
        var threw = false

        try {
            orThrow(ctx.chatId, "sendMessage")
        } catch (_: Exception) {
            threw = true
        }

        @Expect(ctx.message.isPresent, false)
        @Expect(ctx.editedMessage.isPresent, false)
        @Expect(ctx.channelPost.isPresent, false)
        @Expect(ctx.editedChannelPost.isPresent, false)
        @Expect(ctx.businessConnection.isPresent, false)
        @Expect(ctx.businessMessage.isPresent, false)
        @Expect(ctx.editedBusinessMessage.isPresent, false)
        @Expect(ctx.deletedBusinessMessages.isPresent, false)
        @Expect(ctx.messageReaction.isPresent, false)
        @Expect(ctx.messageReactionCount.isPresent, false)
        @Expect(ctx.inlineQuery.isPresent, false)
        @Expect(ctx.chosenInlineResult.isPresent, false)
        @Expect(ctx.callbackQuery.isPresent, false)
        @Expect(ctx.shippingQuery.isPresent, false)
        @Expect(ctx.preCheckoutQuery.isPresent, false)
        @Expect(ctx.poll.isPresent, false)
        @Expect(ctx.pollAnswer.isPresent, false)
        @Expect(ctx.myChatMember.isPresent, false)
        @Expect(ctx.chatMember.isPresent, false)
        @Expect(ctx.managedBot.isPresent, false)
        @Expect(ctx.chatJoinRequest.isPresent, false)
        @Expect(ctx.chatBoost.isPresent, false)
        @Expect(ctx.removedChatBoost.isPresent, false)
        @Expect(ctx.purchasedPaidMedia.isPresent, false)
        @Expect(ctx.msg.isPresent, false)
        @Expect(ctx.chat.isPresent, false)
        @Expect(ctx.senderChat.isPresent, false)
        @Expect(ctx.from.isPresent, false)
        @Expect(ctx.msgId, 0)
        @Expect(ctx.chatId, 0)
        @Expect(ctx.inlineMessageId, "")
        @Expect(ctx.businessConnectionId, "")
        @Expect(ctx.entities().size, 0)
        @Expect(ctx.reactions().emoji.size, 0)
        @Expect(threw, true)
    }

    @TestCase
    public func aggregateGettersKeepGrammYPriority(): Unit {
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

        @Expect(ctx.msg.messageId, 21)
        @Expect(ctx.chat.id, 101)
        @Expect(ctx.senderChat.id, 103)
        @Expect(ctx.from.id, 202)
        @Expect(ctx.msgId, 21)
        @Expect(ctx.chatId, 101)
        @Expect(ctx.inlineMessageId, "inline-callback")
        @Expect(ctx.businessConnectionId, "bc-from-message")
    }

    @TestCase
    public func aggregateGetterMatrixCoversMultipleSourcesAndSentinels(): Unit {
        let chatA = Chat(121, "private")
        let chatB = Chat(122, "supergroup")
        let chatC = Chat(123, "channel")
        let userA = User(221, false, "Ada", "ada")
        let userB = User(222, false, "Grace", "grace")
        let empty = testContext(Update(30))

        let message = Message(321, chatA, "message", userA)
        message.senderChat = chatC
        message.businessConnectionId = "bc-message"
        @Expect(testContext(Update.withMessage(31, message)).msg.messageId, 321)
        @Expect(testContext(Update.withMessage(32, message)).chat.id, 121)
        @Expect(testContext(Update.withMessage(33, message)).senderChat.id, 123)
        @Expect(testContext(Update.withMessage(34, message)).from.id, 221)
        @Expect(testContext(Update.withMessage(35, message)).msgId, 321)
        @Expect(testContext(Update.withMessage(36, message)).chatId, 121)
        @Expect(testContext(Update.withMessage(37, message)).businessConnectionId, "bc-message")

        let callbackMessage = Message(322, chatB, "callback-message", userB)
        callbackMessage.senderChat = chatC
        let callback = CallbackQuery(userB, "callback-data", "", callbackMessage, "inline-callback")
        @Expect(testContext(Update.withCallbackQuery(38, callback)).msg.messageId, 322)
        @Expect(testContext(Update.withCallbackQuery(39, callback)).chat.id, 122)
        @Expect(testContext(Update.withCallbackQuery(40, callback)).senderChat.id, 123)
        @Expect(testContext(Update.withCallbackQuery(41, callback)).from.id, 222)
        @Expect(testContext(Update.withCallbackQuery(42, callback)).inlineMessageId, "inline-callback")

        let reaction = MessageReactionUpdated(chatB, userB, 323, [], [])
        @Expect(testContext(Update.withMessageReaction(43, reaction)).chat.id, 122)
        @Expect(testContext(Update.withMessageReaction(44, reaction)).from.id, 222)
        @Expect(testContext(Update.withMessageReaction(45, reaction)).msgId, 323)
        @Expect(testContext(Update.withMessageReaction(46, reaction)).chatId, 122)

        let business = BusinessConnection("bc-update", userB, 4242)
        @Expect(testContext(Update.withBusinessConnection(47, business)).from.id, 222)
        @Expect(testContext(Update.withBusinessConnection(48, business)).chatId, 4242)
        @Expect(testContext(Update.withBusinessConnection(49, business)).businessConnectionId, "bc-update")

        let chosen = ChosenInlineResult(userA, "chosen-result", "inline-chosen")
        @Expect(testContext(Update.withChosenInlineResult(50, chosen)).inlineMessageId, "inline-chosen")
        let deleted = BusinessMessagesDeleted(chatB, "bc-deleted")
        @Expect(testContext(Update.withDeletedBusinessMessages(51, deleted)).businessConnectionId, "bc-deleted")

        @Expect(empty.msg.isPresent, false)
        @Expect(empty.chat.isPresent, false)
        @Expect(empty.senderChat.isPresent, false)
        @Expect(empty.from.isPresent, false)
        @Expect(empty.msgId, 0)
        @Expect(empty.chatId, 0)
        @Expect(empty.inlineMessageId, "")
        @Expect(empty.businessConnectionId, "")
    }

    @TestCase
    public func entitiesAndReactionsMirrorContextHelpers(): Unit {
        let chat = Chat(111, "private")
        let user = User(222, false, "Ada", "ada")
        let message = Message(31, chat, "hello link", user)
        message.addEntity(MessageEntity("bold", 0, 5))
        message.addEntity(MessageEntity("url", 6, 4))

        let update = Update.withMessage(4, message)
        let ctx = testContext(update)

        @Expect(ctx.entities().size, 2)
        @Expect(ctx.entities("url")[0].text, "link")
        @Expect(ctx.entities(["bold"])[0].text, "hello")

        let captionMessage = Message(33, chat, "")
        captionMessage.caption = "caption link"
        captionMessage.addCaptionEntity(MessageEntity("url", 8, 4))
        let captionCtx = testContext(Update.withMessage(6, captionMessage))
        @Expect(captionCtx.entities().size, 1)
        @Expect(captionCtx.entities("url")[0].text, "link")

        let reactionUpdate = Update.withMessageReaction(
            7,
            MessageReactionUpdated(
                chat,
                user,
                32,
                [ReactionType.emojiReaction("plus"), ReactionType.customEmojiReaction("custom-old")],
                [ReactionType.emojiReaction("plus"), ReactionType.emojiReaction("heart"), ReactionType.paidReaction()]
            )
        )
        let summary = testContext(reactionUpdate).reactions()

        @Expect(summary.emoji[0], "plus")
        @Expect(summary.emojiAdded[0], "heart")
        @Expect(summary.emojiKept[0], "plus")
        @Expect(summary.customEmojiRemoved[0], "custom-old")
        @Expect(summary.paid, true)
        @Expect(summary.paidAdded, true)
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
        @Expect(ctx.`match`, "/start payload")
        @Expect(ctx.hasCommand("start"), true)
        @Expect(ctx.`match`, "payload")
        @Expect(ctx.hasChatType("private"), true)
        @Expect(ctx.hasFilter("message"), true)
        @Expect(ctx.hasText("missing"), false)

        let callbackCtx = testContext(Update.withCallbackQuery(7, CallbackQuery(user, "clicked", Message(42, chat, "button", user))))
        @Expect(Context.has.callbackQuery("clicked").matches(callbackCtx), true)
        @Expect(callbackCtx.hasCallbackQuery("clicked"), true)
        @Expect(callbackCtx.`match`, "clicked")

        let reactionCtx = testContext(Update.withMessageReaction(
            8,
            MessageReactionUpdated(chat, user, 43, [], [ReactionType.emojiReaction("heart")])
        ))
        @Expect(Context.has.reaction("heart").matches(reactionCtx), true)
        @Expect(reactionCtx.hasReaction("heart"), true)
        @Expect(reactionCtx.hasReaction("plus"), false)
    }

    @TestCase
    public func staticAndInstanceTriggerArraysCoverQueryKinds(): Unit {
        let chat = Chat(124, "group")
        let user = User(457, false, "Grace", "grace")
        let message = Message(44, chat, "payload", user)

        let gameCtx = testContext(Update.withCallbackQuery(10, CallbackQuery(user, "", "game-a", message, "")))
        @Expect(Context.has.gameQuery(["missing", "game-a"]).matches(gameCtx), true)
        @Expect(gameCtx.hasGameQuery(["missing", "game-a"]), true)
        @Expect(gameCtx.`match`, "game-a")

        let inlineCtx = testContext(Update.withInlineQuery(11, InlineQuery(user, "inline-a")))
        @Expect(Context.has.inlineQuery(["missing", "inline-a"]).matches(inlineCtx), true)
        @Expect(inlineCtx.hasInlineQuery(["missing", "inline-a"]), true)
        @Expect(inlineCtx.`match`, "inline-a")

        let chosenCtx = testContext(Update.withChosenInlineResult(12, ChosenInlineResult(user, "chosen-a", "inline-message")))
        @Expect(Context.has.chosenInlineResult(["missing", "chosen-a"]).matches(chosenCtx), true)
        @Expect(chosenCtx.hasChosenInlineResult(["missing", "chosen-a"]), true)
        @Expect(chosenCtx.`match`, "chosen-a")

        let preCheckoutCtx = testContext(Update.withPreCheckoutQuery(13, PreCheckoutQuery(user, "pre-a")))
        @Expect(Context.has.preCheckoutQuery(["missing", "pre-a"]).matches(preCheckoutCtx), true)
        @Expect(preCheckoutCtx.hasPreCheckoutQuery(["missing", "pre-a"]), true)
        @Expect(preCheckoutCtx.`match`, "pre-a")

        let shippingCtx = testContext(Update.withShippingQuery(14, ShippingQuery(user, "ship-a")))
        @Expect(Context.has.shippingQuery(["missing", "ship-a"]).matches(shippingCtx), true)
        @Expect(shippingCtx.hasShippingQuery(["missing", "ship-a"]), true)
        @Expect(shippingCtx.`match`, "ship-a")
    }

    @TestCase
    public func textTriggerObjectsAreRegexpFunctionAlternative(): Unit {
        let chat = Chat(128, "private")
        let user = User(461, false, "Alonzo", "alonzo")
        let ctx = testContext(Update.withMessage(18, Message(48, chat, "alpha beta", user)))

        @Expect(ctx.hasText(TextTrigger.contains("pha")), true)
        @Expect(ctx.`match`, "pha")
        @Expect(ctx.hasText(TextTrigger.prefix("alpha")), true)
        @Expect(ctx.`match`, "alpha")
        @Expect(ctx.hasText(TextTrigger.suffix("beta")), true)
        @Expect(ctx.`match`, "beta")
        @Expect(ctx.hasText(TextTrigger.contains("gamma")), false)
        @Expect(ctx.`match`, "beta")

        let inlineCtx = testContext(Update.withInlineQuery(19, InlineQuery(user, "inline-value")))
        @Expect(Context.has.inlineQuery(TextTrigger.contains("line")).matches(inlineCtx), true)
        @Expect(inlineCtx.`match`, "line")

        @Expect(triggerFn("exact").matchValue("exact"), "exact")
        @Expect(triggerFn(["missing", "array"]).matchValue("array"), "array")
        @Expect(triggerFn(TextTrigger.prefix("pre")).matchValue("prefix"), "pre")
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
        @Expect(ctx.`match`, "alpha")
        @Expect(ctx.hasText("beta"), false)
        @Expect(ctx.`match`, "alpha")
    }

    @TestCase
    public func commandProbeMatchesOnlyTargetedBotMentions(): Unit {
        let chat = Chat(126, "private")
        let user = User(459, false, "Edsger", "edsger")

        let targeted = Message(46, chat, "/start@GrAmMy4Cj_BoT payload", user)
        targeted.addEntity(MessageEntity("bot_command", 0, 20))
        let targetedCtx = testContext(Update.withMessage(16, targeted))
        @Expect(targetedCtx.hasCommand("start"), true)
        @Expect(targetedCtx.`match`, "payload")

        let otherBot = Message(47, chat, "/start@other_bot payload", user)
        otherBot.addEntity(MessageEntity("bot_command", 0, 16))
        let otherBotCtx = testContext(Update.withMessage(17, otherBot))
        @Expect(otherBotCtx.hasCommand("start"), false)
    }

    @TestCase
    public func commandProbeRejectsSlashPrefix(): Unit {
        var threw = false

        try {
            Context.has.command("/start")
        } catch (_: Exception) {
            threw = true
        }

        @Expect(threw, true)
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
    public func replyBuildsRunnablePayloadThroughApiWrapperSkeleton(): Unit {
        let chat = Chat(777, "private")
        let user = User(888, false, "Ada", "ada")
        let message = Message(51, chat, "incoming", user)
        let ctx = testContext(Update.withMessage(9, message))

        let payload = ctx.reply("pong")

        @Expect(methodName(payload), "sendMessage")
        @Expect(payloadBody(payload).contains("\"chat_id\":\"777\""), true)
        @Expect(payloadBody(payload).contains("\"text\":\"pong\""), true)
    }

    @TestCase
    public func replyFamilyPrefillsChatBusinessThreadAndDirectTopic(): Unit {
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
        @Expect(payloadBody(payload).contains("\"chat_id\":\"701\""), true)
        @Expect(payloadBody(payload).contains("\"business_connection_id\":\"bc-701\""), true)
        @Expect(payloadBody(payload).contains("\"message_thread_id\":\"77\""), true)
        @Expect(payloadBody(payload).contains("\"direct_messages_topic_id\":\"88\""), true)
        @Expect(payloadBody(payload).contains("\"action\":\"typing\""), true)
    }

    @TestCase
    public func forwardCopyDeleteAndReactionShortcutsUseTypedPayloads(): Unit {
        let chat = Chat(706, "private")
        let user = User(806, false, "Donald", "donald")
        let message = Message(906, chat, "incoming", user)
        let ctx = testContext(Update.withMessage(111, message))

        let forward = ctx.forwardMessage(9001)
        @Expect(methodName(forward), "forwardMessage")
        @Expect(payloadBody(forward).contains("\"chat_id\":9001"), true)
        @Expect(payloadBody(forward).contains("\"from_chat_id\":706"), true)
        @Expect(payloadBody(forward).contains("\"message_id\":906"), true)

        let forwardMany = ctx.forwardMessages(9002, [906, 907])
        @Expect(methodName(forwardMany), "forwardMessages")
        @Expect(payloadBody(forwardMany).contains("\"message_ids\":[906,907]"), true)

        let copy = ctx.copyMessage(9003)
        @Expect(methodName(copy), "copyMessage")
        @Expect(payloadBody(copy).contains("\"from_chat_id\":706"), true)
        @Expect(payloadBody(copy).contains("\"message_id\":906"), true)

        let copyMany = ctx.copyMessages(9004, [908, 909])
        @Expect(methodName(copyMany), "copyMessages")
        @Expect(payloadBody(copyMany).contains("\"message_ids\":[908,909]"), true)

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
}
