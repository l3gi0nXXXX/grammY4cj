package grammy4cj.context

import std.collection.ArrayList

import grammy4cj.core.Api
import grammy4cj.core.Payload
import grammy4cj.types.BusinessConnection
import grammy4cj.types.BusinessMessagesDeleted
import grammy4cj.types.CallbackQuery
import grammy4cj.types.Chat
import grammy4cj.types.ChatBoostRemoved
import grammy4cj.types.ChatBoostUpdated
import grammy4cj.types.ChatJoinRequest
import grammy4cj.types.ChatMemberUpdated
import grammy4cj.types.ChosenInlineResult
import grammy4cj.types.InlineQuery
import grammy4cj.types.ManagedBotUpdate
import grammy4cj.types.Message
import grammy4cj.types.MessageEntityText
import grammy4cj.types.MessageReactionCountUpdated
import grammy4cj.types.MessageReactionUpdated
import grammy4cj.types.Poll
import grammy4cj.types.PollAnswer
import grammy4cj.types.PreCheckoutQuery
import grammy4cj.types.PurchasedPaidMedia
import grammy4cj.types.ReactionSummary
import grammy4cj.types.ReactionType
import grammy4cj.types.ShippingQuery
import grammy4cj.types.Update
import grammy4cj.types.User
import grammy4cj.types.UserFromGetMe

public class ContextShortcutMapping {
    public let shortcut: String
    public let apiMethod: String
    public let requiredContext: String

    public init(shortcut: String, apiMethod: String, requiredContext: String) {
        this.shortcut = shortcut
        this.apiMethod = apiMethod
        this.requiredContext = requiredContext
    }
}

public class TextTrigger {
    public let values: Array<String>

    public init(values: Array<String>) {
        this.values = values
    }

    public func matchValue(content: String): String {
        for (value in this.values) {
            if (content == value) {
                return value
            }
        }
        ""
    }
}

public class ContextHas {
    public func filterQuery(filter: String): ContextPredicate {
        ContextPredicate("filter", [filter], [])
    }

    public func filterQuery(filters: Array<String>): ContextPredicate {
        ContextPredicate("filter", filters, [])
    }

    public func text(trigger: String): ContextPredicate {
        ContextPredicate("text", toArray(trigger), [])
    }

    public func text(triggers: Array<String>): ContextPredicate {
        ContextPredicate("text", toArray(triggers), [])
    }

    public func command(command: String): ContextPredicate {
        validateCommandNames(toArray(command))
        ContextPredicate("command", toArray(command), [])
    }

    public func command(commands: Array<String>): ContextPredicate {
        validateCommandNames(toArray(commands))
        ContextPredicate("command", toArray(commands), [])
    }

    public func reaction(reaction: String): ContextPredicate {
        ContextPredicate("reaction", [], [ReactionType.emojiReaction(reaction)])
    }

    public func reaction(reactions: Array<String>): ContextPredicate {
        let normalized = ArrayList<ReactionType>()
        for (reaction in reactions) {
            normalized.add(ReactionType.emojiReaction(reaction))
        }
        ContextPredicate("reaction", [], normalized.toArray())
    }

    public func reaction(reaction: ReactionType): ContextPredicate {
        ContextPredicate("reaction", [], [reaction])
    }

    public func reaction(reactions: Array<ReactionType>): ContextPredicate {
        ContextPredicate("reaction", [], reactions)
    }

    public func chatType(chatType: String): ContextPredicate {
        ContextPredicate("chatType", toArray(chatType), [])
    }

    public func chatType(chatTypes: Array<String>): ContextPredicate {
        ContextPredicate("chatType", toArray(chatTypes), [])
    }

    public func callbackQuery(trigger: String): ContextPredicate {
        ContextPredicate("callbackQuery", toArray(trigger), [])
    }

    public func callbackQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("callbackQuery", toArray(triggers), [])
    }

    public func inlineQuery(trigger: String): ContextPredicate {
        ContextPredicate("inlineQuery", toArray(trigger), [])
    }

    public func inlineQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("inlineQuery", toArray(triggers), [])
    }

    public func chosenInlineResult(trigger: String): ContextPredicate {
        ContextPredicate("chosenInlineResult", toArray(trigger), [])
    }

    public func chosenInlineResult(triggers: Array<String>): ContextPredicate {
        ContextPredicate("chosenInlineResult", toArray(triggers), [])
    }

    public func preCheckoutQuery(trigger: String): ContextPredicate {
        ContextPredicate("preCheckoutQuery", toArray(trigger), [])
    }

    public func preCheckoutQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("preCheckoutQuery", toArray(triggers), [])
    }

    public func shippingQuery(trigger: String): ContextPredicate {
        ContextPredicate("shippingQuery", toArray(trigger), [])
    }

    public func shippingQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("shippingQuery", toArray(triggers), [])
    }
}

public class ContextPredicate {
    public let kind: String
    public let values: Array<String>
    public let reactions: Array<ReactionType>

    public init(kind: String, values: Array<String>, reactions: Array<ReactionType>) {
        this.kind = kind
        this.values = values
        this.reactions = reactions
    }

    public func matches(ctx: Context): Bool {
        if (this.kind == "filter") {
            for (query in this.values) {
                if (matchesFilterQuery(ctx, query)) {
                    return true
                }
            }
            return false
        }
        if (this.kind == "text") {
            return matchesText(ctx, TextTrigger(this.values))
        }
        if (this.kind == "command") {
            return matchesCommand(ctx, this.values)
        }
        if (this.kind == "reaction") {
            return matchesReaction(ctx, this.reactions)
        }
        if (this.kind == "chatType") {
            return ctx.chat.isPresent && containsString(this.values, ctx.chat.kind)
        }
        if (this.kind == "callbackQuery") {
            return ctx.callbackQuery.isPresent && matchAndStore(ctx, ctx.callbackQuery.data, TextTrigger(this.values))
        }
        if (this.kind == "inlineQuery") {
            return ctx.inlineQuery.isPresent && matchAndStore(ctx, ctx.inlineQuery.query, TextTrigger(this.values))
        }
        if (this.kind == "chosenInlineResult") {
            return ctx.chosenInlineResult.isPresent && matchAndStore(ctx, ctx.chosenInlineResult.resultId, TextTrigger(this.values))
        }
        if (this.kind == "preCheckoutQuery") {
            return ctx.preCheckoutQuery.isPresent && matchAndStore(ctx, ctx.preCheckoutQuery.invoicePayload, TextTrigger(this.values))
        }
        if (this.kind == "shippingQuery") {
            return ctx.shippingQuery.isPresent && matchAndStore(ctx, ctx.shippingQuery.invoicePayload, TextTrigger(this.values))
        }
        false
    }
}

public class Context {
    public static let has = ContextHas()

    public let update: Update
    public let api: Api
    public let me: UserFromGetMe
    public var `match`: String = ""

    public init(update: Update, api: Api, me: UserFromGetMe) {
        this.update = update
        this.api = api
        this.me = me
    }

    public func updateId(): Int64 {
        this.update.updateId
    }

    public func botInfoUsername(): String {
        this.me.username
    }

    public prop message: Message {
        get() { this.update.message }
    }

    public prop editedMessage: Message {
        get() { this.update.editedMessage }
    }

    public prop channelPost: Message {
        get() { this.update.channelPost }
    }

    public prop editedChannelPost: Message {
        get() { this.update.editedChannelPost }
    }

    public prop businessConnection: BusinessConnection {
        get() { this.update.businessConnection }
    }

    public prop businessMessage: Message {
        get() { this.update.businessMessage }
    }

    public prop editedBusinessMessage: Message {
        get() { this.update.editedBusinessMessage }
    }

    public prop deletedBusinessMessages: BusinessMessagesDeleted {
        get() { this.update.deletedBusinessMessages }
    }

    public prop messageReaction: MessageReactionUpdated {
        get() { this.update.messageReaction }
    }

    public prop messageReactionCount: MessageReactionCountUpdated {
        get() { this.update.messageReactionCount }
    }

    public prop inlineQuery: InlineQuery {
        get() { this.update.inlineQuery }
    }

    public prop chosenInlineResult: ChosenInlineResult {
        get() { this.update.chosenInlineResult }
    }

    public prop callbackQuery: CallbackQuery {
        get() { this.update.callbackQuery }
    }

    public prop shippingQuery: ShippingQuery {
        get() { this.update.shippingQuery }
    }

    public prop preCheckoutQuery: PreCheckoutQuery {
        get() { this.update.preCheckoutQuery }
    }

    public prop poll: Poll {
        get() { this.update.poll }
    }

    public prop pollAnswer: PollAnswer {
        get() { this.update.pollAnswer }
    }

    public prop myChatMember: ChatMemberUpdated {
        get() { this.update.myChatMember }
    }

    public prop chatMember: ChatMemberUpdated {
        get() { this.update.chatMember }
    }

    public prop managedBot: ManagedBotUpdate {
        get() { this.update.managedBot }
    }

    public prop chatJoinRequest: ChatJoinRequest {
        get() { this.update.chatJoinRequest }
    }

    public prop chatBoost: ChatBoostUpdated {
        get() { this.update.chatBoost }
    }

    public prop removedChatBoost: ChatBoostRemoved {
        get() { this.update.removedChatBoost }
    }

    public prop purchasedPaidMedia: PurchasedPaidMedia {
        get() { this.update.purchasedPaidMedia }
    }

    public prop msg: Message {
        get() {
            if (this.message.isPresent) { return this.message }
            if (this.editedMessage.isPresent) { return this.editedMessage }
            if (this.channelPost.isPresent) { return this.channelPost }
            if (this.editedChannelPost.isPresent) { return this.editedChannelPost }
            if (this.businessMessage.isPresent) { return this.businessMessage }
            if (this.editedBusinessMessage.isPresent) { return this.editedBusinessMessage }
            if (this.callbackQuery.isPresent && this.callbackQuery.message.isPresent) { return this.callbackQuery.message }
            Message()
        }
    }

    public prop chat: Chat {
        get() {
            let message = this.msg
            if (message.isPresent && message.chat.isPresent) { return message.chat }
            if (this.deletedBusinessMessages.isPresent) { return this.deletedBusinessMessages.chat }
            if (this.messageReaction.isPresent) { return this.messageReaction.chat }
            if (this.messageReactionCount.isPresent) { return this.messageReactionCount.chat }
            if (this.myChatMember.isPresent) { return this.myChatMember.chat }
            if (this.chatMember.isPresent) { return this.chatMember.chat }
            if (this.chatJoinRequest.isPresent) { return this.chatJoinRequest.chat }
            if (this.chatBoost.isPresent) { return this.chatBoost.chat }
            if (this.removedChatBoost.isPresent) { return this.removedChatBoost.chat }
            Chat()
        }
    }

    public prop senderChat: Chat {
        get() {
            let message = this.msg
            if (message.isPresent && message.senderChat.isPresent) {
                return message.senderChat
            }
            Chat()
        }
    }

    public prop from: User {
        get() {
            if (this.businessConnection.isPresent) { return this.businessConnection.user }
            if (this.messageReaction.isPresent) { return this.messageReaction.user }
            if (this.managedBot.isPresent) { return this.managedBot.user }
            if (this.chatBoost.isPresent && this.chatBoost.boost.source.user.isPresent) { return this.chatBoost.boost.source.user }
            if (this.removedChatBoost.isPresent && this.removedChatBoost.source.user.isPresent) { return this.removedChatBoost.source.user }
            if (this.callbackQuery.isPresent) { return this.callbackQuery.user }
            if (this.msg.isPresent && this.msg.user.isPresent) { return this.msg.user }
            if (this.inlineQuery.isPresent) { return this.inlineQuery.user }
            if (this.chosenInlineResult.isPresent) { return this.chosenInlineResult.user }
            if (this.shippingQuery.isPresent) { return this.shippingQuery.user }
            if (this.preCheckoutQuery.isPresent) { return this.preCheckoutQuery.user }
            if (this.myChatMember.isPresent) { return this.myChatMember.user }
            if (this.chatMember.isPresent) { return this.chatMember.user }
            if (this.chatJoinRequest.isPresent) { return this.chatJoinRequest.user }
            if (this.purchasedPaidMedia.isPresent) { return this.purchasedPaidMedia.user }
            User()
        }
    }

    public prop msgId: Int64 {
        get() {
            if (this.msg.isPresent) { return this.msg.messageId }
            if (this.messageReaction.isPresent) { return this.messageReaction.messageId }
            if (this.messageReactionCount.isPresent) { return this.messageReactionCount.messageId }
            0
        }
    }

    public prop chatId: Int64 {
        get() {
            if (this.chat.isPresent) { return this.chat.id }
            if (this.businessConnection.isPresent) { return this.businessConnection.userChatId }
            0
        }
    }

    public prop inlineMessageId: String {
        get() {
            if (this.callbackQuery.isPresent && !this.callbackQuery.inlineMessageId.isEmpty()) {
                return this.callbackQuery.inlineMessageId
            }
            if (this.chosenInlineResult.isPresent) {
                return this.chosenInlineResult.inlineMessageId
            }
            ""
        }
    }

    public prop businessConnectionId: String {
        get() {
            if (this.msg.isPresent && !this.msg.businessConnectionId.isEmpty()) {
                return this.msg.businessConnectionId
            }
            if (this.businessConnection.isPresent) {
                return this.businessConnection.id
            }
            if (this.deletedBusinessMessages.isPresent) {
                return this.deletedBusinessMessages.businessConnectionId
            }
            ""
        }
    }

    public func entities(): Array<MessageEntityText> {
        collectEntities(this.msg, [])
    }

    public func entities(kind: String): Array<MessageEntityText> {
        collectEntities(this.msg, [kind])
    }

    public func entities(kinds: Array<String>): Array<MessageEntityText> {
        collectEntities(this.msg, kinds)
    }

    public func reactions(): ReactionSummary {
        reactionSummary(this.messageReaction)
    }

    public func hasFilter(filter: String): Bool {
        Context.has.filterQuery(filter).matches(this)
    }

    public func hasFilter(filters: Array<String>): Bool {
        Context.has.filterQuery(filters).matches(this)
    }

    public func hasText(trigger: String): Bool {
        Context.has.text(trigger).matches(this)
    }

    public func hasText(triggers: Array<String>): Bool {
        Context.has.text(triggers).matches(this)
    }

    public func hasCommand(command: String): Bool {
        Context.has.command(command).matches(this)
    }

    public func hasCommand(commands: Array<String>): Bool {
        Context.has.command(commands).matches(this)
    }

    public func hasReaction(reaction: String): Bool {
        Context.has.reaction(reaction).matches(this)
    }

    public func hasReaction(reaction: ReactionType): Bool {
        Context.has.reaction(reaction).matches(this)
    }

    public func hasChatType(chatType: String): Bool {
        Context.has.chatType(chatType).matches(this)
    }

    public func hasCallbackQuery(trigger: String): Bool {
        Context.has.callbackQuery(trigger).matches(this)
    }

    public func hasInlineQuery(trigger: String): Bool {
        Context.has.inlineQuery(trigger).matches(this)
    }

    public func hasChosenInlineResult(trigger: String): Bool {
        Context.has.chosenInlineResult(trigger).matches(this)
    }

    public func hasPreCheckoutQuery(trigger: String): Bool {
        Context.has.preCheckoutQuery(trigger).matches(this)
    }

    public func hasShippingQuery(trigger: String): Bool {
        Context.has.shippingQuery(trigger).matches(this)
    }

    public func reply(text: String): Payload {
        let payload = defaultReplyPayload("sendMessage")
        payload.addValue("text", text)
        this.api.sendMessage(payload)
    }

    public func replyWithDraft(text: String): Payload {
        let payload = defaultReplyPayload("sendMessageDraft")
        payload.addValue("update_id", this.update.updateId.toString())
        payload.addValue("text", text)
        this.api.sendMessageDraft(payload)
    }

    public func forwardMessage(chatId: Int64): Payload {
        let payload = Payload("")
        payload.addValue("chat_id", chatId.toString())
        payload.addValue("from_chat_id", orThrow(this.chatId, "forwardMessage").toString())
        payload.addValue("message_id", orThrow(this.msgId, "forwardMessage").toString())
        this.api.forwardMessage(payload)
    }

    public func forwardMessages(chatId: Int64, messageIds: String): Payload {
        let payload = Payload("")
        payload.addValue("chat_id", chatId.toString())
        payload.addValue("from_chat_id", orThrow(this.chatId, "forwardMessages").toString())
        payload.addValue("message_ids", messageIds)
        this.api.forwardMessages(payload)
    }

    public func copyMessage(chatId: Int64): Payload {
        let payload = Payload("")
        payload.addValue("chat_id", chatId.toString())
        payload.addValue("from_chat_id", orThrow(this.chatId, "copyMessage").toString())
        payload.addValue("message_id", orThrow(this.msgId, "copyMessage").toString())
        this.api.copyMessage(payload)
    }

    public func copyMessages(chatId: Int64, messageIds: String): Payload {
        let payload = Payload("")
        payload.addValue("chat_id", chatId.toString())
        payload.addValue("from_chat_id", orThrow(this.chatId, "copyMessages").toString())
        payload.addValue("message_ids", messageIds)
        this.api.copyMessages(payload)
    }

    public func replyWithPhoto(photo: String): Payload {
        replyWithSingleMedia("sendPhoto", "photo", photo)
    }

    public func replyWithAudio(audio: String): Payload {
        replyWithSingleMedia("sendAudio", "audio", audio)
    }

    public func replyWithDocument(document: String): Payload {
        replyWithSingleMedia("sendDocument", "document", document)
    }

    public func replyWithVideo(video: String): Payload {
        replyWithSingleMedia("sendVideo", "video", video)
    }

    public func replyWithAnimation(animation: String): Payload {
        replyWithSingleMedia("sendAnimation", "animation", animation)
    }

    public func replyWithVoice(voice: String): Payload {
        replyWithSingleMedia("sendVoice", "voice", voice)
    }

    public func replyWithVideoNote(videoNote: String): Payload {
        replyWithSingleMedia("sendVideoNote", "video_note", videoNote)
    }

    public func replyWithMediaGroup(media: String): Payload {
        let payload = defaultReplyPayload("sendMediaGroup")
        payload.addValue("media", media)
        this.api.sendMediaGroup(payload)
    }

    public func replyWithLocation(latitude: String, longitude: String): Payload {
        let payload = defaultReplyPayload("sendLocation")
        payload.addValue("latitude", latitude)
        payload.addValue("longitude", longitude)
        this.api.sendLocation(payload)
    }

    private func defaultReplyPayload(method: String): Payload {
        let payload = Payload("")
        payload.addValue("chat_id", orThrow(this.chatId, method).toString())
        if (!this.businessConnectionId.isEmpty()) {
            payload.addValue("business_connection_id", this.businessConnectionId)
        }
        if (this.msg.isTopicMessage) {
            payload.addValue("message_thread_id", this.msg.messageThreadId.toString())
        }
        if (this.msg.directMessagesTopicId != 0) {
            payload.addValue("direct_messages_topic_id", this.msg.directMessagesTopicId.toString())
        }
        payload
    }

    private func replyWithSingleMedia(method: String, key: String, value: String): Payload {
        let payload = defaultReplyPayload(method)
        payload.addValue(key, value)
        if (method == "sendPhoto") { return this.api.sendPhoto(payload) }
        if (method == "sendAudio") { return this.api.sendAudio(payload) }
        if (method == "sendDocument") { return this.api.sendDocument(payload) }
        if (method == "sendVideo") { return this.api.sendVideo(payload) }
        if (method == "sendAnimation") { return this.api.sendAnimation(payload) }
        if (method == "sendVoice") { return this.api.sendVoice(payload) }
        if (method == "sendVideoNote") { return this.api.sendVideoNote(payload) }
        this.api.call(method, payload)
    }
}

public func contextShortcutMappings(): Array<ContextShortcutMapping> {
    [
        ContextShortcutMapping("reply", "sendMessage", "chat_id"),
        ContextShortcutMapping("replyWithDraft", "sendMessageDraft", "chat_id, update_id"),
        ContextShortcutMapping("forwardMessage", "forwardMessage", "chat_id, from_chat_id, message_id"),
        ContextShortcutMapping("forwardMessages", "forwardMessages", "chat_id, from_chat_id, message_ids"),
        ContextShortcutMapping("copyMessage", "copyMessage", "chat_id, from_chat_id, message_id"),
        ContextShortcutMapping("copyMessages", "copyMessages", "chat_id, from_chat_id, message_ids"),
        ContextShortcutMapping("replyWithPhoto", "sendPhoto", "chat_id, photo"),
        ContextShortcutMapping("replyWithAudio", "sendAudio", "chat_id, audio"),
        ContextShortcutMapping("replyWithDocument", "sendDocument", "chat_id, document"),
        ContextShortcutMapping("replyWithVideo", "sendVideo", "chat_id, video"),
        ContextShortcutMapping("replyWithAnimation", "sendAnimation", "chat_id, animation"),
        ContextShortcutMapping("replyWithVoice", "sendVoice", "chat_id, voice"),
        ContextShortcutMapping("replyWithVideoNote", "sendVideoNote", "chat_id, video_note"),
        ContextShortcutMapping("replyWithMediaGroup", "sendMediaGroup", "chat_id, media"),
        ContextShortcutMapping("replyWithLocation", "sendLocation", "chat_id, latitude, longitude")
    ]
}

public func orThrow(value: Int64, method: String): Int64 {
    if (value == 0) {
        throw Exception("Missing information for API call to " + method)
    }
    value
}

public func orThrow(value: String, method: String): String {
    if (value.isEmpty()) {
        throw Exception("Missing information for API call to " + method)
    }
    value
}

public func toArray(value: String): Array<String> {
    [value]
}

public func toArray(values: Array<String>): Array<String> {
    values
}

public func triggerFn(trigger: String): TextTrigger {
    TextTrigger(toArray(trigger))
}

public func triggerFn(triggers: Array<String>): TextTrigger {
    TextTrigger(toArray(triggers))
}

private func validateCommandNames(commands: Array<String>): Unit {
    for (command in commands) {
        if (command.startsWith("/")) {
            throw Exception("Do not include '/' when registering command handlers.")
        }
    }
}

private func matchesFilterQuery(ctx: Context, query: String): Bool {
    if (query == ":text") {
        return ctx.msg.isPresent && !messageContent(ctx.msg).isEmpty()
    }
    if (query == ":caption") {
        return ctx.msg.isPresent && !ctx.msg.caption.isEmpty()
    }
    if (query == ":entities:bot_command") {
        return hasBotCommandEntity(ctx.msg)
    }
    if (query == "callback_query:data") {
        return ctx.callbackQuery.isPresent && !ctx.callbackQuery.data.isEmpty()
    }
    if (query == "callback_query:game_short_name") {
        return ctx.callbackQuery.isPresent && !ctx.callbackQuery.gameShortName.isEmpty()
    }
    if (query == "message_reaction") { return ctx.messageReaction.isPresent }
    if (query == "inline_query") { return ctx.inlineQuery.isPresent }
    if (query == "chosen_inline_result") { return ctx.chosenInlineResult.isPresent }
    if (query == "pre_checkout_query") { return ctx.preCheckoutQuery.isPresent }
    if (query == "shipping_query") { return ctx.shippingQuery.isPresent }
    if (query == "message") { return ctx.message.isPresent }
    if (query == "edited_message") { return ctx.editedMessage.isPresent }
    if (query == "channel_post") { return ctx.channelPost.isPresent }
    if (query == "edited_channel_post") { return ctx.editedChannelPost.isPresent }
    if (query == "business_connection") { return ctx.businessConnection.isPresent }
    if (query == "business_message") { return ctx.businessMessage.isPresent }
    if (query == "edited_business_message") { return ctx.editedBusinessMessage.isPresent }
    if (query == "deleted_business_messages") { return ctx.deletedBusinessMessages.isPresent }
    if (query == "message_reaction_count") { return ctx.messageReactionCount.isPresent }
    if (query == "poll") { return ctx.poll.isPresent }
    if (query == "poll_answer") { return ctx.pollAnswer.isPresent }
    if (query == "my_chat_member") { return ctx.myChatMember.isPresent }
    if (query == "chat_member") { return ctx.chatMember.isPresent }
    if (query == "managed_bot") { return ctx.managedBot.isPresent }
    if (query == "chat_join_request") { return ctx.chatJoinRequest.isPresent }
    if (query == "chat_boost") { return ctx.chatBoost.isPresent }
    if (query == "removed_chat_boost") { return ctx.removedChatBoost.isPresent }
    if (query == "purchased_paid_media") { return ctx.purchasedPaidMedia.isPresent }
    !query.isEmpty() && query == ctx.update.kind
}

private func matchesText(ctx: Context, trigger: TextTrigger): Bool {
    if (!ctx.msg.isPresent) {
        return false
    }
    matchAndStore(ctx, messageContent(ctx.msg), trigger)
}

private func matchAndStore(ctx: Context, content: String, trigger: TextTrigger): Bool {
    let result = trigger.matchValue(content)
    if (!result.isEmpty()) {
        ctx.`match` = result
        return true
    }
    false
}

private func matchesCommand(ctx: Context, commands: Array<String>): Bool {
    let message = ctx.msg
    if (!message.isPresent || !hasBotCommandEntity(message)) {
        return false
    }
    let text = messageContent(message)
    for (entity in message.entities) {
        if (entity.kind != "bot_command" || entity.offset != 0 || entity.length <= 1 || entity.length > text.size) {
            continue
        }
        let raw = text[1..entity.length]
        let command = commandNameWithoutBot(raw)
        if (containsString(commands, raw) || containsString(commands, command)) {
            ctx.`match` = text[entity.length..].trimAsciiStart()
            return true
        }
    }
    false
}

private func commandNameWithoutBot(raw: String): String {
    match (raw.indexOf("@")) {
        case Some(index) => raw[0..index]
        case None => raw
    }
}

private func matchesReaction(ctx: Context, wanted: Array<ReactionType>): Bool {
    if (!ctx.messageReaction.isPresent) {
        return false
    }
    for (reaction in ctx.messageReaction.newReaction) {
        if (reactionExists(ctx.messageReaction.oldReaction, reaction)) {
            continue
        }
        for (candidate in wanted) {
            if (sameReaction(reaction, candidate)) {
                return true
            }
        }
    }
    false
}

private func collectEntities(message: Message, kinds: Array<String>): Array<MessageEntityText> {
    let result = ArrayList<MessageEntityText>()
    if (!message.isPresent) {
        return result.toArray()
    }
    let text = messageContent(message)
    if (text.isEmpty()) {
        return result.toArray()
    }
    let entities = if (!message.text.isEmpty()) { message.entities } else { message.captionEntities }
    for (entity in entities) {
        if (kinds.size > 0 && !containsString(kinds, entity.kind)) {
            continue
        }
        if (entity.offset < 0 || entity.length <= 0 || entity.offset >= text.size) {
            continue
        }
        let end = if (entity.offset + entity.length > text.size) { text.size } else { entity.offset + entity.length }
        result.add(MessageEntityText(entity, text[entity.offset..end]))
    }
    result.toArray()
}

private func reactionSummary(update: MessageReactionUpdated): ReactionSummary {
    let summary = ReactionSummary()
    if (!update.isPresent) {
        return summary
    }
    let emoji = ArrayList<String>()
    let emojiAdded = ArrayList<String>()
    let emojiKept = ArrayList<String>()
    let emojiRemoved = ArrayList<String>()
    let customEmoji = ArrayList<String>()
    let customEmojiAdded = ArrayList<String>()
    let customEmojiKept = ArrayList<String>()
    let customEmojiRemoved = ArrayList<String>()

    for (reaction in update.newReaction) {
        if (reaction.kind == "emoji") {
            emoji.add(reaction.emoji)
            if (reactionExists(update.oldReaction, reaction)) { emojiKept.add(reaction.emoji) } else { emojiAdded.add(reaction.emoji) }
        } else if (reaction.kind == "custom_emoji") {
            customEmoji.add(reaction.customEmojiId)
            if (reactionExists(update.oldReaction, reaction)) { customEmojiKept.add(reaction.customEmojiId) } else { customEmojiAdded.add(reaction.customEmojiId) }
        } else if (reaction.kind == "paid") {
            summary.paid = true
            summary.paidAdded = !reactionExists(update.oldReaction, reaction)
        }
    }
    for (reaction in update.oldReaction) {
        if (!reactionExists(update.newReaction, reaction)) {
            if (reaction.kind == "emoji") {
                emojiRemoved.add(reaction.emoji)
            } else if (reaction.kind == "custom_emoji") {
                customEmojiRemoved.add(reaction.customEmojiId)
            }
        }
    }
    summary.emoji = emoji.toArray()
    summary.emojiAdded = emojiAdded.toArray()
    summary.emojiKept = emojiKept.toArray()
    summary.emojiRemoved = emojiRemoved.toArray()
    summary.customEmoji = customEmoji.toArray()
    summary.customEmojiAdded = customEmojiAdded.toArray()
    summary.customEmojiKept = customEmojiKept.toArray()
    summary.customEmojiRemoved = customEmojiRemoved.toArray()
    summary
}

private func hasBotCommandEntity(message: Message): Bool {
    if (!message.isPresent) {
        return false
    }
    for (entity in message.entities) {
        if (entity.kind == "bot_command") {
            return true
        }
    }
    false
}

private func messageContent(message: Message): String {
    if (!message.text.isEmpty()) {
        return message.text
    }
    message.caption
}

private func containsString(values: Array<String>, value: String): Bool {
    for (item in values) {
        if (item == value) {
            return true
        }
    }
    false
}

private func reactionExists(values: Array<ReactionType>, reaction: ReactionType): Bool {
    for (value in values) {
        if (sameReaction(value, reaction)) {
            return true
        }
    }
    false
}

private func sameReaction(left: ReactionType, right: ReactionType): Bool {
    if (left.kind != right.kind) {
        return false
    }
    if (left.kind == "emoji") {
        return left.emoji == right.emoji
    }
    if (left.kind == "custom_emoji") {
        return left.customEmojiId == right.customEmojiId
    }
    if (left.kind == "paid") {
        return true
    }
    false
}
