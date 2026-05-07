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

        let reactionUpdate = Update.withMessageReaction(
            5,
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
    public func commandProbeRejectsSlashPrefix(): Unit {
        var threw = false

        try {
            Context.has.command("/start")
        } catch (_: Exception) {
            threw = true
        }

        @Expect(threw, true)
    }
}

@Test
public class ContextShortcutTest {
    @TestCase
    public func shortcutMappingTableCoversAvailableApiWrapperSkeleton(): Unit {
        let mappings = contextShortcutMappings()

        @Expect(mappings.size, 15)
        @Expect(mappings[0].shortcut, "reply")
        @Expect(mappings[0].apiMethod, "sendMessage")
        @Expect(mappings[14].shortcut, "replyWithLocation")
        @Expect(mappings[14].apiMethod, "sendLocation")
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
}
