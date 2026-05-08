package grammy4cj.context

import std.collection.ArrayList
import std.regex.Regex

import grammy4cj.core.Api
import grammy4cj.core.Payload
import grammy4cj.filter.FilterContextView
import grammy4cj.filter.matchFilter
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

public class ContextSourceDriftRow {
    public let upstreamAnchor: String
    public let contract: String
    public let expectedCount: Int64
    public let actualCount: Int64

    public init(upstreamAnchor: String, contract: String, expectedCount: Int64, actualCount: Int64) {
        this.upstreamAnchor = upstreamAnchor
        this.contract = contract
        this.expectedCount = expectedCount
        this.actualCount = actualCount
    }

    public prop ok: Bool {
        get() { this.expectedCount == this.actualCount }
    }
}

public class TextTrigger {
    public let values: Array<String>
    public let mode: String
    public let regexes: Array<Regex>

    public init(values: Array<String>) {
        this.values = values
        this.mode = "exact"
        this.regexes = []
    }

    public init(values: Array<String>, mode: String) {
        this.values = values
        this.mode = mode
        this.regexes = []
    }

    public init(regex: Regex) {
        this.values = []
        this.mode = "regex"
        this.regexes = [regex]
    }

    public init(regexes: Array<Regex>) {
        this.values = []
        this.mode = "regex"
        this.regexes = regexes
    }

    public static func exact(value: String): TextTrigger {
        TextTrigger([value], "exact")
    }

    public static func exact(values: Array<String>): TextTrigger {
        TextTrigger(values, "exact")
    }

    public static func contains(value: String): TextTrigger {
        TextTrigger([value], "contains")
    }

    public static func contains(values: Array<String>): TextTrigger {
        TextTrigger(values, "contains")
    }

    public static func prefix(value: String): TextTrigger {
        TextTrigger([value], "prefix")
    }

    public static func prefix(values: Array<String>): TextTrigger {
        TextTrigger(values, "prefix")
    }

    public static func suffix(value: String): TextTrigger {
        TextTrigger([value], "suffix")
    }

    public static func suffix(values: Array<String>): TextTrigger {
        TextTrigger(values, "suffix")
    }

    public static func regex(pattern: String): TextTrigger {
        TextTrigger(Regex(pattern))
    }

    public static func regex(patterns: Array<String>): TextTrigger {
        let regexes = ArrayList<Regex>()
        for (pattern in patterns) {
            regexes.add(Regex(pattern))
        }
        TextTrigger(regexes.toArray())
    }

    public static func regex(regex: Regex): TextTrigger {
        TextTrigger(regex)
    }

    public static func regex(regexes: Array<Regex>): TextTrigger {
        TextTrigger(regexes)
    }

    public func matchValue(content: String): String {
        match (this.matchResult(content)) {
            case Some(value) => return value.text
            case None => return ""
        }
    }

    public func matchResult(content: String): Option<ContextMatch> {
        if (this.mode == "regex") {
            for (regex in this.regexes) {
                match (firstRegexMatch(regex, content)) {
                    case Some(value) => return Some(value)
                    case None => ()
                }
            }
            return None<ContextMatch>
        }
        for (value in this.values) {
            if (value.isEmpty()) {
                continue
            }
            if (this.mode == "exact" && content == value) {
                return Some(ContextMatch.string(value))
            }
            if (this.mode == "contains" && content.contains(value)) {
                return Some(ContextMatch.string(value))
            }
            if (this.mode == "prefix" && content.startsWith(value)) {
                return Some(ContextMatch.string(value))
            }
            if (this.mode == "suffix" && content.endsWith(value)) {
                return Some(ContextMatch.string(value))
            }
        }
        None<ContextMatch>
    }
}

public class ContextMatch {
    public let kind: String
    public let values: Array<String>

    public init(kind: String, values: Array<String>) {
        this.kind = kind
        this.values = values
    }

    public static func string(value: String): ContextMatch {
        ContextMatch("string", [value])
    }

    public static func regex(values: Array<String>): ContextMatch {
        ContextMatch("regex", values)
    }

    public prop text: String {
        get() {
            if (this.values.size == 0) {
                return ""
            }
            this.values[0]
        }
    }

    public prop isString: Bool {
        get() { this.kind == "string" }
    }

    public prop isRegex: Bool {
        get() { this.kind == "regex" }
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

    public func text(trigger: TextTrigger): ContextPredicate {
        ContextPredicate("text", trigger, [])
    }

    public func text(trigger: Regex): ContextPredicate {
        ContextPredicate("text", TextTrigger.regex(trigger), [])
    }

    public func text(triggers: Array<Regex>): ContextPredicate {
        ContextPredicate("text", TextTrigger.regex(triggers), [])
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

    public func callbackQuery(trigger: TextTrigger): ContextPredicate {
        ContextPredicate("callbackQuery", trigger, [])
    }

    public func callbackQuery(trigger: Regex): ContextPredicate {
        ContextPredicate("callbackQuery", TextTrigger.regex(trigger), [])
    }

    public func callbackQuery(triggers: Array<Regex>): ContextPredicate {
        ContextPredicate("callbackQuery", TextTrigger.regex(triggers), [])
    }

    public func gameQuery(trigger: String): ContextPredicate {
        ContextPredicate("gameQuery", toArray(trigger), [])
    }

    public func gameQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("gameQuery", toArray(triggers), [])
    }

    public func gameQuery(trigger: TextTrigger): ContextPredicate {
        ContextPredicate("gameQuery", trigger, [])
    }

    public func gameQuery(trigger: Regex): ContextPredicate {
        ContextPredicate("gameQuery", TextTrigger.regex(trigger), [])
    }

    public func gameQuery(triggers: Array<Regex>): ContextPredicate {
        ContextPredicate("gameQuery", TextTrigger.regex(triggers), [])
    }

    public func inlineQuery(trigger: String): ContextPredicate {
        ContextPredicate("inlineQuery", toArray(trigger), [])
    }

    public func inlineQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("inlineQuery", toArray(triggers), [])
    }

    public func inlineQuery(trigger: TextTrigger): ContextPredicate {
        ContextPredicate("inlineQuery", trigger, [])
    }

    public func inlineQuery(trigger: Regex): ContextPredicate {
        ContextPredicate("inlineQuery", TextTrigger.regex(trigger), [])
    }

    public func inlineQuery(triggers: Array<Regex>): ContextPredicate {
        ContextPredicate("inlineQuery", TextTrigger.regex(triggers), [])
    }

    public func chosenInlineResult(trigger: String): ContextPredicate {
        ContextPredicate("chosenInlineResult", toArray(trigger), [])
    }

    public func chosenInlineResult(triggers: Array<String>): ContextPredicate {
        ContextPredicate("chosenInlineResult", toArray(triggers), [])
    }

    public func chosenInlineResult(trigger: TextTrigger): ContextPredicate {
        ContextPredicate("chosenInlineResult", trigger, [])
    }

    public func chosenInlineResult(trigger: Regex): ContextPredicate {
        ContextPredicate("chosenInlineResult", TextTrigger.regex(trigger), [])
    }

    public func chosenInlineResult(triggers: Array<Regex>): ContextPredicate {
        ContextPredicate("chosenInlineResult", TextTrigger.regex(triggers), [])
    }

    public func preCheckoutQuery(trigger: String): ContextPredicate {
        ContextPredicate("preCheckoutQuery", toArray(trigger), [])
    }

    public func preCheckoutQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("preCheckoutQuery", toArray(triggers), [])
    }

    public func preCheckoutQuery(trigger: TextTrigger): ContextPredicate {
        ContextPredicate("preCheckoutQuery", trigger, [])
    }

    public func preCheckoutQuery(trigger: Regex): ContextPredicate {
        ContextPredicate("preCheckoutQuery", TextTrigger.regex(trigger), [])
    }

    public func preCheckoutQuery(triggers: Array<Regex>): ContextPredicate {
        ContextPredicate("preCheckoutQuery", TextTrigger.regex(triggers), [])
    }

    public func shippingQuery(trigger: String): ContextPredicate {
        ContextPredicate("shippingQuery", toArray(trigger), [])
    }

    public func shippingQuery(triggers: Array<String>): ContextPredicate {
        ContextPredicate("shippingQuery", toArray(triggers), [])
    }

    public func shippingQuery(trigger: TextTrigger): ContextPredicate {
        ContextPredicate("shippingQuery", trigger, [])
    }

    public func shippingQuery(trigger: Regex): ContextPredicate {
        ContextPredicate("shippingQuery", TextTrigger.regex(trigger), [])
    }

    public func shippingQuery(triggers: Array<Regex>): ContextPredicate {
        ContextPredicate("shippingQuery", TextTrigger.regex(triggers), [])
    }
}

public class ContextPredicate {
    public let kind: String
    public let values: Array<String>
    public let trigger: TextTrigger
    public let reactions: Array<ReactionType>

    public init(kind: String, values: Array<String>, reactions: Array<ReactionType>) {
        this.kind = kind
        this.values = values
        this.trigger = TextTrigger(values)
        this.reactions = reactions
    }

    public init(kind: String, trigger: TextTrigger, reactions: Array<ReactionType>) {
        this.kind = kind
        this.values = trigger.values
        this.trigger = trigger
        this.reactions = reactions
    }

    public func matches(ctx: Context): Bool {
        if (this.kind == "filter") {
            return matchFilter(this.values, ctx)
        }
        if (this.kind == "text") {
            return matchesText(ctx, this.trigger)
        }
        if (this.kind == "command") {
            return matchesCommand(ctx, this.values)
        }
        if (this.kind == "reaction") {
            return matchesReaction(ctx, this.reactions)
        }
        if (this.kind == "chatType") {
            match (ctx.chat) {
                case Some(chat) => return containsString(this.values, chat.kind)
                case None => return false
            }
        }
        if (this.kind == "callbackQuery") {
            match (ctx.callbackQuery) {
                case Some(callbackQuery) => return !callbackQuery.data.isEmpty() && matchAndStore(ctx, callbackQuery.data, this.trigger)
                case None => return false
            }
        }
        if (this.kind == "gameQuery") {
            match (ctx.callbackQuery) {
                case Some(callbackQuery) => return !callbackQuery.gameShortName.isEmpty() && matchAndStore(ctx, callbackQuery.gameShortName, this.trigger)
                case None => return false
            }
        }
        if (this.kind == "inlineQuery") {
            match (ctx.inlineQuery) {
                case Some(inlineQuery) => return matchAndStore(ctx, inlineQuery.query, this.trigger)
                case None => return false
            }
        }
        if (this.kind == "chosenInlineResult") {
            match (ctx.chosenInlineResult) {
                case Some(chosenInlineResult) => return matchAndStore(ctx, chosenInlineResult.resultId, this.trigger)
                case None => return false
            }
        }
        if (this.kind == "preCheckoutQuery") {
            match (ctx.preCheckoutQuery) {
                case Some(preCheckoutQuery) => return matchAndStore(ctx, preCheckoutQuery.invoicePayload, this.trigger)
                case None => return false
            }
        }
        if (this.kind == "shippingQuery") {
            match (ctx.shippingQuery) {
                case Some(shippingQuery) => return matchAndStore(ctx, shippingQuery.invoicePayload, this.trigger)
                case None => return false
            }
        }
        false
    }
}

public class HearsContext {
    public let ctx: Context
    public let message: Message
    public let `match`: ContextMatch

    public init(ctx: Context, message: Message, `match`: ContextMatch) {
        this.ctx = ctx
        this.message = message
        this.`match` = `match`
    }
}

public class CommandContext {
    public let ctx: Context
    public let message: Message
    public let `match`: ContextMatch

    public init(ctx: Context, message: Message, `match`: ContextMatch) {
        this.ctx = ctx
        this.message = message
        this.`match` = `match`
    }
}

public class ChatTypeContext {
    public let ctx: Context
    public let chat: Chat
    public let chatType: String

    public init(ctx: Context, chat: Chat, chatType: String) {
        this.ctx = ctx
        this.chat = chat
        this.chatType = chatType
    }
}

public class CallbackQueryContext {
    public let ctx: Context
    public let callbackQuery: CallbackQuery
    public let `match`: ContextMatch

    public init(ctx: Context, callbackQuery: CallbackQuery, `match`: ContextMatch) {
        this.ctx = ctx
        this.callbackQuery = callbackQuery
        this.`match` = `match`
    }
}

public class GameQueryContext {
    public let ctx: Context
    public let callbackQuery: CallbackQuery
    public let `match`: ContextMatch

    public init(ctx: Context, callbackQuery: CallbackQuery, `match`: ContextMatch) {
        this.ctx = ctx
        this.callbackQuery = callbackQuery
        this.`match` = `match`
    }
}

public class InlineQueryContext {
    public let ctx: Context
    public let inlineQuery: InlineQuery
    public let `match`: ContextMatch

    public init(ctx: Context, inlineQuery: InlineQuery, `match`: ContextMatch) {
        this.ctx = ctx
        this.inlineQuery = inlineQuery
        this.`match` = `match`
    }
}

public class ChosenInlineResultContext {
    public let ctx: Context
    public let chosenInlineResult: ChosenInlineResult
    public let `match`: ContextMatch

    public init(ctx: Context, chosenInlineResult: ChosenInlineResult, `match`: ContextMatch) {
        this.ctx = ctx
        this.chosenInlineResult = chosenInlineResult
        this.`match` = `match`
    }
}

public class PreCheckoutQueryContext {
    public let ctx: Context
    public let preCheckoutQuery: PreCheckoutQuery
    public let `match`: ContextMatch

    public init(ctx: Context, preCheckoutQuery: PreCheckoutQuery, `match`: ContextMatch) {
        this.ctx = ctx
        this.preCheckoutQuery = preCheckoutQuery
        this.`match` = `match`
    }
}

public class ShippingQueryContext {
    public let ctx: Context
    public let shippingQuery: ShippingQuery
    public let `match`: ContextMatch

    public init(ctx: Context, shippingQuery: ShippingQuery, `match`: ContextMatch) {
        this.ctx = ctx
        this.shippingQuery = shippingQuery
        this.`match` = `match`
    }
}

public class ReactionContext {
    public let ctx: Context
    public let messageReaction: MessageReactionUpdated

    public init(ctx: Context, messageReaction: MessageReactionUpdated) {
        this.ctx = ctx
        this.messageReaction = messageReaction
    }
}

public class Context <: FilterContextView {
    public static let has = ContextHas()

    public let update: Update
    public let api: Api
    public let me: UserFromGetMe
    public var `match`: Option<ContextMatch> = None<ContextMatch>

    public init(update: Update, api: Api, me: UserFromGetMe) {
        this.update = update
        this.api = api
        this.me = me
    }

    public func updateId(): Int64 {
        this.update.updateId
    }

    public func filterUpdate(): Update {
        this.update
    }

    public func filterBotUser(): UserFromGetMe {
        this.me
    }

    public func botInfoUsername(): String {
        this.me.username
    }

    public prop message: Option<Message> { get() { maybeMessage(this.update.message) } }
    public prop editedMessage: Option<Message> { get() { maybeMessage(this.update.editedMessage) } }
    public prop channelPost: Option<Message> { get() { maybeMessage(this.update.channelPost) } }
    public prop editedChannelPost: Option<Message> { get() { maybeMessage(this.update.editedChannelPost) } }
    public prop businessConnection: Option<BusinessConnection> { get() { maybeBusinessConnection(this.update.businessConnection) } }
    public prop businessMessage: Option<Message> { get() { maybeMessage(this.update.businessMessage) } }
    public prop editedBusinessMessage: Option<Message> { get() { maybeMessage(this.update.editedBusinessMessage) } }
    public prop deletedBusinessMessages: Option<BusinessMessagesDeleted> { get() { maybeBusinessMessagesDeleted(this.update.deletedBusinessMessages) } }
    public prop messageReaction: Option<MessageReactionUpdated> { get() { maybeMessageReactionUpdated(this.update.messageReaction) } }
    public prop messageReactionCount: Option<MessageReactionCountUpdated> { get() { maybeMessageReactionCountUpdated(this.update.messageReactionCount) } }
    public prop inlineQuery: Option<InlineQuery> { get() { maybeInlineQuery(this.update.inlineQuery) } }
    public prop chosenInlineResult: Option<ChosenInlineResult> { get() { maybeChosenInlineResult(this.update.chosenInlineResult) } }
    public prop callbackQuery: Option<CallbackQuery> { get() { maybeCallbackQuery(this.update.callbackQuery) } }
    public prop shippingQuery: Option<ShippingQuery> { get() { maybeShippingQuery(this.update.shippingQuery) } }
    public prop preCheckoutQuery: Option<PreCheckoutQuery> { get() { maybePreCheckoutQuery(this.update.preCheckoutQuery) } }
    public prop poll: Option<Poll> { get() { maybePoll(this.update.poll) } }
    public prop pollAnswer: Option<PollAnswer> { get() { maybePollAnswer(this.update.pollAnswer) } }
    public prop myChatMember: Option<ChatMemberUpdated> { get() { maybeChatMemberUpdated(this.update.myChatMember) } }
    public prop chatMember: Option<ChatMemberUpdated> { get() { maybeChatMemberUpdated(this.update.chatMember) } }
    public prop managedBot: Option<ManagedBotUpdate> { get() { maybeManagedBotUpdate(this.update.managedBot) } }
    public prop chatJoinRequest: Option<ChatJoinRequest> { get() { maybeChatJoinRequest(this.update.chatJoinRequest) } }
    public prop chatBoost: Option<ChatBoostUpdated> { get() { maybeChatBoostUpdated(this.update.chatBoost) } }
    public prop removedChatBoost: Option<ChatBoostRemoved> { get() { maybeChatBoostRemoved(this.update.removedChatBoost) } }
    public prop purchasedPaidMedia: Option<PurchasedPaidMedia> { get() { maybePurchasedPaidMedia(this.update.purchasedPaidMedia) } }

    public prop msg: Option<Message> {
        get() {
            match (this.message) { case Some(value) => return Some(value); case None => () }
            match (this.editedMessage) { case Some(value) => return Some(value); case None => () }
            match (this.channelPost) { case Some(value) => return Some(value); case None => () }
            match (this.editedChannelPost) { case Some(value) => return Some(value); case None => () }
            match (this.businessMessage) { case Some(value) => return Some(value); case None => () }
            match (this.editedBusinessMessage) { case Some(value) => return Some(value); case None => () }
            match (this.callbackQuery) { case Some(value) => return maybeMessage(value.message); case None => () }
            None<Message>
        }
    }

    public prop chat: Option<Chat> {
        get() {
            match (this.msg) { case Some(value) => match (maybeChat(value.chat)) { case Some(chat) => return Some(chat); case None => () }; case None => () }
            match (this.deletedBusinessMessages) { case Some(value) => return maybeChat(value.chat); case None => () }
            match (this.messageReaction) { case Some(value) => return maybeChat(value.chat); case None => () }
            match (this.messageReactionCount) { case Some(value) => return maybeChat(value.chat); case None => () }
            match (this.myChatMember) { case Some(value) => return maybeChat(value.chat); case None => () }
            match (this.chatMember) { case Some(value) => return maybeChat(value.chat); case None => () }
            match (this.chatJoinRequest) { case Some(value) => return maybeChat(value.chat); case None => () }
            match (this.chatBoost) { case Some(value) => return maybeChat(value.chat); case None => () }
            match (this.removedChatBoost) { case Some(value) => return maybeChat(value.chat); case None => () }
            None<Chat>
        }
    }

    public prop senderChat: Option<Chat> {
        get() {
            match (this.msg) {
                case Some(message) => return maybeChat(message.senderChat)
                case None => return None<Chat>
            }
        }
    }

    public prop from: Option<User> {
        get() {
            match (this.businessConnection) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.messageReaction) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.managedBot) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.chatBoost) { case Some(value) => match (maybeUser(value.boost.source.user)) { case Some(user) => return Some(user); case None => () }; case None => () }
            match (this.removedChatBoost) { case Some(value) => match (maybeUser(value.source.user)) { case Some(user) => return Some(user); case None => () }; case None => () }
            match (this.callbackQuery) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.msg) { case Some(value) => match (maybeUser(value.user)) { case Some(user) => return Some(user); case None => () }; case None => () }
            match (this.inlineQuery) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.chosenInlineResult) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.shippingQuery) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.preCheckoutQuery) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.myChatMember) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.chatMember) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.chatJoinRequest) { case Some(value) => return maybeUser(value.user); case None => () }
            match (this.purchasedPaidMedia) { case Some(value) => return maybeUser(value.user); case None => () }
            None<User>
        }
    }

    public prop msgId: Option<Int64> {
        get() {
            match (this.msg) { case Some(value) => return Some(value.messageId); case None => () }
            match (this.messageReaction) { case Some(value) => return Some(value.messageId); case None => () }
            match (this.messageReactionCount) { case Some(value) => return Some(value.messageId); case None => () }
            None<Int64>
        }
    }

    public prop chatId: Option<Int64> {
        get() {
            match (this.chat) { case Some(value) => return Some(value.id); case None => () }
            match (this.businessConnection) { case Some(value) => return Some(value.userChatId); case None => () }
            None<Int64>
        }
    }

    public prop inlineMessageId: Option<String> {
        get() {
            match (this.callbackQuery) {
                case Some(value) =>
                    if (!value.inlineMessageId.isEmpty()) { return Some(value.inlineMessageId) }
                case None => ()
            }
            match (this.chosenInlineResult) {
                case Some(value) =>
                    if (!value.inlineMessageId.isEmpty()) { return Some(value.inlineMessageId) }
                case None => ()
            }
            None<String>
        }
    }

    public prop businessConnectionId: Option<String> {
        get() {
            match (this.msg) {
                case Some(value) =>
                    if (!value.businessConnectionId.isEmpty()) { return Some(value.businessConnectionId) }
                case None => ()
            }
            match (this.businessConnection) { case Some(value) => return Some(value.id); case None => () }
            match (this.deletedBusinessMessages) { case Some(value) => return Some(value.businessConnectionId); case None => () }
            None<String>
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

    public func hasText(trigger: TextTrigger): Bool {
        Context.has.text(trigger).matches(this)
    }

    public func hasText(trigger: Regex): Bool {
        Context.has.text(trigger).matches(this)
    }

    public func hasText(triggers: Array<Regex>): Bool {
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

    public func hasReaction(reactions: Array<String>): Bool {
        Context.has.reaction(reactions).matches(this)
    }

    public func hasReaction(reaction: ReactionType): Bool {
        Context.has.reaction(reaction).matches(this)
    }

    public func hasReaction(reactions: Array<ReactionType>): Bool {
        Context.has.reaction(reactions).matches(this)
    }

    public func hasChatType(chatType: String): Bool {
        Context.has.chatType(chatType).matches(this)
    }

    public func hasChatType(chatTypes: Array<String>): Bool {
        Context.has.chatType(chatTypes).matches(this)
    }

    public func hasCallbackQuery(trigger: String): Bool {
        Context.has.callbackQuery(trigger).matches(this)
    }

    public func hasCallbackQuery(triggers: Array<String>): Bool {
        Context.has.callbackQuery(triggers).matches(this)
    }

    public func hasCallbackQuery(trigger: TextTrigger): Bool {
        Context.has.callbackQuery(trigger).matches(this)
    }

    public func hasCallbackQuery(trigger: Regex): Bool {
        Context.has.callbackQuery(trigger).matches(this)
    }

    public func hasCallbackQuery(triggers: Array<Regex>): Bool {
        Context.has.callbackQuery(triggers).matches(this)
    }

    public func hasGameQuery(trigger: String): Bool {
        Context.has.gameQuery(trigger).matches(this)
    }

    public func hasGameQuery(triggers: Array<String>): Bool {
        Context.has.gameQuery(triggers).matches(this)
    }

    public func hasGameQuery(trigger: TextTrigger): Bool {
        Context.has.gameQuery(trigger).matches(this)
    }

    public func hasGameQuery(trigger: Regex): Bool {
        Context.has.gameQuery(trigger).matches(this)
    }

    public func hasGameQuery(triggers: Array<Regex>): Bool {
        Context.has.gameQuery(triggers).matches(this)
    }

    public func hasInlineQuery(trigger: String): Bool {
        Context.has.inlineQuery(trigger).matches(this)
    }

    public func hasInlineQuery(triggers: Array<String>): Bool {
        Context.has.inlineQuery(triggers).matches(this)
    }

    public func hasInlineQuery(trigger: TextTrigger): Bool {
        Context.has.inlineQuery(trigger).matches(this)
    }

    public func hasInlineQuery(trigger: Regex): Bool {
        Context.has.inlineQuery(trigger).matches(this)
    }

    public func hasInlineQuery(triggers: Array<Regex>): Bool {
        Context.has.inlineQuery(triggers).matches(this)
    }

    public func hasChosenInlineResult(trigger: String): Bool {
        Context.has.chosenInlineResult(trigger).matches(this)
    }

    public func hasChosenInlineResult(triggers: Array<String>): Bool {
        Context.has.chosenInlineResult(triggers).matches(this)
    }

    public func hasChosenInlineResult(trigger: TextTrigger): Bool {
        Context.has.chosenInlineResult(trigger).matches(this)
    }

    public func hasChosenInlineResult(trigger: Regex): Bool {
        Context.has.chosenInlineResult(trigger).matches(this)
    }

    public func hasChosenInlineResult(triggers: Array<Regex>): Bool {
        Context.has.chosenInlineResult(triggers).matches(this)
    }

    public func hasPreCheckoutQuery(trigger: String): Bool {
        Context.has.preCheckoutQuery(trigger).matches(this)
    }

    public func hasPreCheckoutQuery(triggers: Array<String>): Bool {
        Context.has.preCheckoutQuery(triggers).matches(this)
    }

    public func hasPreCheckoutQuery(trigger: TextTrigger): Bool {
        Context.has.preCheckoutQuery(trigger).matches(this)
    }

    public func hasPreCheckoutQuery(trigger: Regex): Bool {
        Context.has.preCheckoutQuery(trigger).matches(this)
    }

    public func hasPreCheckoutQuery(triggers: Array<Regex>): Bool {
        Context.has.preCheckoutQuery(triggers).matches(this)
    }

    public func hasShippingQuery(trigger: String): Bool {
        Context.has.shippingQuery(trigger).matches(this)
    }

    public func hasShippingQuery(triggers: Array<String>): Bool {
        Context.has.shippingQuery(triggers).matches(this)
    }

    public func hasShippingQuery(trigger: TextTrigger): Bool {
        Context.has.shippingQuery(trigger).matches(this)
    }

    public func hasShippingQuery(trigger: Regex): Bool {
        Context.has.shippingQuery(trigger).matches(this)
    }

    public func hasShippingQuery(triggers: Array<Regex>): Bool {
        Context.has.shippingQuery(triggers).matches(this)
    }

    public func refineText(trigger: String): Option<HearsContext> {
        this.refineText(TextTrigger.exact(trigger))
    }

    public func refineText(triggers: Array<String>): Option<HearsContext> {
        this.refineText(TextTrigger.exact(triggers))
    }

    public func refineText(trigger: TextTrigger): Option<HearsContext> {
        if (!this.hasText(trigger)) {
            return None<HearsContext>
        }
        Some(HearsContext(this, orThrow(triggerMessage(this), "refineText"), orThrow(this.`match`, "refineText")))
    }

    public func refineText(trigger: Regex): Option<HearsContext> {
        this.refineText(TextTrigger.regex(trigger))
    }

    public func refineText(triggers: Array<Regex>): Option<HearsContext> {
        this.refineText(TextTrigger.regex(triggers))
    }

    public func refineCommand(command: String): Option<CommandContext> {
        this.refineCommand([command])
    }

    public func refineCommand(commands: Array<String>): Option<CommandContext> {
        if (!this.hasCommand(commands)) {
            return None<CommandContext>
        }
        Some(CommandContext(this, orThrow(triggerMessage(this), "refineCommand"), orThrow(this.`match`, "refineCommand")))
    }

    public func refineChatType(chatType: String): Option<ChatTypeContext> {
        this.refineChatType([chatType])
    }

    public func refineChatType(chatTypes: Array<String>): Option<ChatTypeContext> {
        if (!this.hasChatType(chatTypes)) {
            return None<ChatTypeContext>
        }
        let chat = orThrow(this.chat, "refineChatType")
        Some(ChatTypeContext(this, chat, chat.kind))
    }

    public func refineCallbackQuery(trigger: String): Option<CallbackQueryContext> {
        this.refineCallbackQuery(TextTrigger.exact(trigger))
    }

    public func refineCallbackQuery(triggers: Array<String>): Option<CallbackQueryContext> {
        this.refineCallbackQuery(TextTrigger.exact(triggers))
    }

    public func refineCallbackQuery(trigger: TextTrigger): Option<CallbackQueryContext> {
        if (!this.hasCallbackQuery(trigger)) {
            return None<CallbackQueryContext>
        }
        Some(CallbackQueryContext(this, orThrow(this.callbackQuery, "refineCallbackQuery"), orThrow(this.`match`, "refineCallbackQuery")))
    }

    public func refineCallbackQuery(trigger: Regex): Option<CallbackQueryContext> {
        this.refineCallbackQuery(TextTrigger.regex(trigger))
    }

    public func refineCallbackQuery(triggers: Array<Regex>): Option<CallbackQueryContext> {
        this.refineCallbackQuery(TextTrigger.regex(triggers))
    }

    public func refineGameQuery(trigger: String): Option<GameQueryContext> {
        this.refineGameQuery(TextTrigger.exact(trigger))
    }

    public func refineGameQuery(triggers: Array<String>): Option<GameQueryContext> {
        this.refineGameQuery(TextTrigger.exact(triggers))
    }

    public func refineGameQuery(trigger: TextTrigger): Option<GameQueryContext> {
        if (!this.hasGameQuery(trigger)) {
            return None<GameQueryContext>
        }
        Some(GameQueryContext(this, orThrow(this.callbackQuery, "refineGameQuery"), orThrow(this.`match`, "refineGameQuery")))
    }

    public func refineGameQuery(trigger: Regex): Option<GameQueryContext> {
        this.refineGameQuery(TextTrigger.regex(trigger))
    }

    public func refineGameQuery(triggers: Array<Regex>): Option<GameQueryContext> {
        this.refineGameQuery(TextTrigger.regex(triggers))
    }

    public func refineInlineQuery(trigger: String): Option<InlineQueryContext> {
        this.refineInlineQuery(TextTrigger.exact(trigger))
    }

    public func refineInlineQuery(triggers: Array<String>): Option<InlineQueryContext> {
        this.refineInlineQuery(TextTrigger.exact(triggers))
    }

    public func refineInlineQuery(trigger: TextTrigger): Option<InlineQueryContext> {
        if (!this.hasInlineQuery(trigger)) {
            return None<InlineQueryContext>
        }
        Some(InlineQueryContext(this, orThrow(this.inlineQuery, "refineInlineQuery"), orThrow(this.`match`, "refineInlineQuery")))
    }

    public func refineInlineQuery(trigger: Regex): Option<InlineQueryContext> {
        this.refineInlineQuery(TextTrigger.regex(trigger))
    }

    public func refineInlineQuery(triggers: Array<Regex>): Option<InlineQueryContext> {
        this.refineInlineQuery(TextTrigger.regex(triggers))
    }

    public func refineChosenInlineResult(trigger: String): Option<ChosenInlineResultContext> {
        this.refineChosenInlineResult(TextTrigger.exact(trigger))
    }

    public func refineChosenInlineResult(triggers: Array<String>): Option<ChosenInlineResultContext> {
        this.refineChosenInlineResult(TextTrigger.exact(triggers))
    }

    public func refineChosenInlineResult(trigger: TextTrigger): Option<ChosenInlineResultContext> {
        if (!this.hasChosenInlineResult(trigger)) {
            return None<ChosenInlineResultContext>
        }
        Some(ChosenInlineResultContext(this, orThrow(this.chosenInlineResult, "refineChosenInlineResult"), orThrow(this.`match`, "refineChosenInlineResult")))
    }

    public func refineChosenInlineResult(trigger: Regex): Option<ChosenInlineResultContext> {
        this.refineChosenInlineResult(TextTrigger.regex(trigger))
    }

    public func refineChosenInlineResult(triggers: Array<Regex>): Option<ChosenInlineResultContext> {
        this.refineChosenInlineResult(TextTrigger.regex(triggers))
    }

    public func refinePreCheckoutQuery(trigger: String): Option<PreCheckoutQueryContext> {
        this.refinePreCheckoutQuery(TextTrigger.exact(trigger))
    }

    public func refinePreCheckoutQuery(triggers: Array<String>): Option<PreCheckoutQueryContext> {
        this.refinePreCheckoutQuery(TextTrigger.exact(triggers))
    }

    public func refinePreCheckoutQuery(trigger: TextTrigger): Option<PreCheckoutQueryContext> {
        if (!this.hasPreCheckoutQuery(trigger)) {
            return None<PreCheckoutQueryContext>
        }
        Some(PreCheckoutQueryContext(this, orThrow(this.preCheckoutQuery, "refinePreCheckoutQuery"), orThrow(this.`match`, "refinePreCheckoutQuery")))
    }

    public func refinePreCheckoutQuery(trigger: Regex): Option<PreCheckoutQueryContext> {
        this.refinePreCheckoutQuery(TextTrigger.regex(trigger))
    }

    public func refinePreCheckoutQuery(triggers: Array<Regex>): Option<PreCheckoutQueryContext> {
        this.refinePreCheckoutQuery(TextTrigger.regex(triggers))
    }

    public func refineShippingQuery(trigger: String): Option<ShippingQueryContext> {
        this.refineShippingQuery(TextTrigger.exact(trigger))
    }

    public func refineShippingQuery(triggers: Array<String>): Option<ShippingQueryContext> {
        this.refineShippingQuery(TextTrigger.exact(triggers))
    }

    public func refineShippingQuery(trigger: TextTrigger): Option<ShippingQueryContext> {
        if (!this.hasShippingQuery(trigger)) {
            return None<ShippingQueryContext>
        }
        Some(ShippingQueryContext(this, orThrow(this.shippingQuery, "refineShippingQuery"), orThrow(this.`match`, "refineShippingQuery")))
    }

    public func refineShippingQuery(trigger: Regex): Option<ShippingQueryContext> {
        this.refineShippingQuery(TextTrigger.regex(trigger))
    }

    public func refineShippingQuery(triggers: Array<Regex>): Option<ShippingQueryContext> {
        this.refineShippingQuery(TextTrigger.regex(triggers))
    }

    public func refineReaction(reaction: String): Option<ReactionContext> {
        if (!this.hasReaction(reaction)) {
            return None<ReactionContext>
        }
        Some(ReactionContext(this, orThrow(this.messageReaction, "refineReaction")))
    }

    public func refineReaction(reactions: Array<String>): Option<ReactionContext> {
        if (!this.hasReaction(reactions)) {
            return None<ReactionContext>
        }
        Some(ReactionContext(this, orThrow(this.messageReaction, "refineReaction")))
    }

    public func refineReaction(reaction: ReactionType): Option<ReactionContext> {
        if (!this.hasReaction(reaction)) {
            return None<ReactionContext>
        }
        Some(ReactionContext(this, orThrow(this.messageReaction, "refineReaction")))
    }

    public func refineReaction(reactions: Array<ReactionType>): Option<ReactionContext> {
        if (!this.hasReaction(reactions)) {
            return None<ReactionContext>
        }
        Some(ReactionContext(this, orThrow(this.messageReaction, "refineReaction")))
    }

    public func reply(text: String): Payload {
        let payload = defaultReplyPayload("sendMessage")
        payload.addValue("text", text)
        this.api.sendMessage(payload)
    }

    public func replyWithDraft(text: String): Payload {
        let payload = draftReplyPayload("sendMessageDraft")
        payload.addInt("update_id", this.update.updateId)
        payload.addValue("text", text)
        this.api.sendMessageDraft(payload)
    }

    public func forwardMessage(chatId: Int64): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", chatId)
        payload.addInt("from_chat_id", orThrow(this.chatId, "forwardMessage"))
        payload.addInt("message_id", orThrow(this.msgId, "forwardMessage"))
        addDirectMessagesTopicIfPresent(payload)
        this.api.forwardMessage(payload)
    }

    public func forwardMessages(chatId: Int64, messageIds: String): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", chatId)
        payload.addInt("from_chat_id", orThrow(this.chatId, "forwardMessages"))
        payload.addRawJson("message_ids", messageIds)
        addDirectMessagesTopicIfPresent(payload)
        this.api.forwardMessages(payload)
    }

    public func forwardMessages(chatId: Int64, messageIds: Array<Int64>): Payload {
        forwardMessages(chatId, intArrayJson(messageIds))
    }

    public func copyMessage(chatId: Int64): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", chatId)
        payload.addInt("from_chat_id", orThrow(this.chatId, "copyMessage"))
        payload.addInt("message_id", orThrow(this.msgId, "copyMessage"))
        addDirectMessagesTopicIfPresent(payload)
        this.api.copyMessage(payload)
    }

    public func copyMessages(chatId: Int64, messageIds: String): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", chatId)
        payload.addInt("from_chat_id", orThrow(this.chatId, "copyMessages"))
        payload.addRawJson("message_ids", messageIds)
        addDirectMessagesTopicIfPresent(payload)
        this.api.copyMessages(payload)
    }

    public func copyMessages(chatId: Int64, messageIds: Array<Int64>): Payload {
        copyMessages(chatId, intArrayJson(messageIds))
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

    public func editMessageLiveLocation(latitude: String, longitude: String): Payload {
        let payload = inlineOrMessageTargetPayload("editMessageLiveLocation")
        payload.addValue("latitude", latitude)
        payload.addValue("longitude", longitude)
        invokeInlineOrMessageApi("editMessageLiveLocation", "editMessageLiveLocationInline", payload)
    }

    public func stopMessageLiveLocation(): Payload {
        let payload = inlineOrMessageTargetPayload("stopMessageLiveLocation")
        invokeInlineOrMessageApi("stopMessageLiveLocation", "stopMessageLiveLocationInline", payload)
    }

    public func sendPaidMedia(starCount: Int64, media: String): Payload {
        let payload = defaultReplyPayload("sendPaidMedia")
        payload.addInt("star_count", starCount)
        payload.addRawJson("media", media)
        invokeApi("sendPaidMedia", payload)
    }

    public func replyWithVenue(latitude: String, longitude: String, title: String, address: String): Payload {
        let payload = defaultReplyPayload("sendVenue")
        payload.addValue("latitude", latitude)
        payload.addValue("longitude", longitude)
        payload.addValue("title", title)
        payload.addValue("address", address)
        invokeApi("sendVenue", payload)
    }

    public func replyWithContact(phoneNumber: String, firstName: String): Payload {
        let payload = defaultReplyPayload("sendContact")
        payload.addValue("phone_number", phoneNumber)
        payload.addValue("first_name", firstName)
        invokeApi("sendContact", payload)
    }

    public func replyWithPoll(question: String, optionsJson: String): Payload {
        let payload = defaultReplyPayloadWithoutDirectTopic("sendPoll")
        payload.addValue("question", question)
        payload.addRawJson("options", optionsJson)
        invokeApi("sendPoll", payload)
    }

    public func replyWithChecklist(checklistJson: String): Payload {
        let payload = businessPayload("sendChecklist")
        payload.addInt("chat_id", orThrow(this.chatId, "sendChecklist"))
        payload.addRawJson("checklist", checklistJson)
        invokeApi("sendChecklist", payload)
    }

    public func editMessageChecklist(checklistJson: String): Payload {
        let payload = businessMessageTargetPayload("editMessageChecklist")
        payload.addRawJson("checklist", checklistJson)
        invokeApi("editMessageChecklist", payload)
    }

    public func replyWithDice(emoji: String): Payload {
        let payload = defaultReplyPayload("sendDice")
        payload.addValue("emoji", emoji)
        invokeApi("sendDice", payload)
    }

    public func replyWithChatAction(action: String): Payload {
        let payload = chatActionPayload("sendChatAction")
        payload.addValue("action", action)
        invokeApi("sendChatAction", payload)
    }

    public func react(reaction: String): Payload {
        let payload = messageTargetPayload("setMessageReaction")
        payload.addRawJson("reaction", "[{\"type\":\"emoji\",\"emoji\":\"" + reaction + "\"}]")
        invokeApi("setMessageReaction", payload)
    }

    public func react(reactions: Array<String>): Payload {
        let normalized = ArrayList<ReactionType>()
        for (reaction in reactions) {
            normalized.add(ReactionType.emojiReaction(reaction))
        }
        react(normalized.toArray())
    }

    public func react(reaction: ReactionType): Payload {
        react([reaction])
    }

    public func react(reactions: Array<ReactionType>): Payload {
        let payload = messageTargetPayload("setMessageReaction")
        payload.addRawJson("reaction", reactionArrayJson(reactions))
        invokeApi("setMessageReaction", payload)
    }

    public func getUserProfilePhotos(): Payload {
        invokeApi("getUserProfilePhotos", fromPayload("getUserProfilePhotos"))
    }

    public func getUserProfileAudios(): Payload {
        invokeApi("getUserProfileAudios", fromPayload("getUserProfileAudios"))
    }

    public func setUserEmojiStatus(emojiStatusCustomEmojiId: String): Payload {
        let payload = fromPayload("setUserEmojiStatus")
        payload.addValue("emoji_status_custom_emoji_id", emojiStatusCustomEmojiId)
        invokeApi("setUserEmojiStatus", payload)
    }

    public func getUserChatBoosts(chatId: Int64): Payload {
        let payload = fromPayload("getUserChatBoosts")
        payload.addInt("chat_id", chatId)
        invokeApi("getUserChatBoosts", payload)
    }

    public func getUserChatBoosts(): Payload {
        let payload = fromPayload("getUserChatBoosts")
        payload.addInt("chat_id", orThrow(this.chatId, "getUserChatBoosts"))
        invokeApi("getUserChatBoosts", payload)
    }

    public func getUserGifts(): Payload {
        invokeApi("getUserGifts", fromPayload("getUserGifts"))
    }

    public func getChatGifts(): Payload {
        invokeApi("getChatGifts", chatPayload("getChatGifts"))
    }

    public func getBusinessConnection(): Payload {
        invokeApi("getBusinessConnection", businessPayload("getBusinessConnection"))
    }

    public func getFile(fileId: String): Payload {
        let payload = Payload("")
        payload.addValue("file_id", orThrow(fileId, "getFile"))
        invokeApi("getFile", payload)
    }

    public func kickAuthor(): Payload {
        banAuthor()
    }

    public func banAuthor(): Payload {
        let payload = chatAuthorPayload("banAuthor")
        invokeApi("banChatMember", payload)
    }

    public func kickChatMember(userId: Int64): Payload {
        banChatMember(userId)
    }

    public func banChatMember(userId: Int64): Payload {
        let payload = chatUserPayload("banChatMember", userId)
        invokeApi("banChatMember", payload)
    }

    public func unbanChatMember(userId: Int64): Payload {
        let payload = chatUserPayload("unbanChatMember", userId)
        invokeApi("unbanChatMember", payload)
    }

    public func restrictAuthor(permissionsJson: String): Payload {
        let payload = chatAuthorPayload("restrictAuthor")
        payload.addRawJson("permissions", permissionsJson)
        invokeApi("restrictChatMember", payload)
    }

    public func restrictChatMember(userId: Int64, permissionsJson: String): Payload {
        let payload = chatUserPayload("restrictChatMember", userId)
        payload.addRawJson("permissions", permissionsJson)
        invokeApi("restrictChatMember", payload)
    }

    public func promoteAuthor(): Payload {
        let payload = chatAuthorPayload("promoteAuthor")
        invokeApi("promoteChatMember", payload)
    }

    public func promoteChatMember(userId: Int64): Payload {
        let payload = chatUserPayload("promoteChatMember", userId)
        invokeApi("promoteChatMember", payload)
    }

    public func setChatAdministratorAuthorCustomTitle(customTitle: String): Payload {
        let payload = chatAuthorPayload("setChatAdministratorAuthorCustomTitle")
        payload.addValue("custom_title", customTitle)
        invokeApi("setChatAdministratorCustomTitle", payload)
    }

    public func setChatAdministratorCustomTitle(userId: Int64, customTitle: String): Payload {
        let payload = chatUserPayload("setChatAdministratorCustomTitle", userId)
        payload.addValue("custom_title", customTitle)
        invokeApi("setChatAdministratorCustomTitle", payload)
    }

    public func setAuthorTag(tag: String): Payload {
        let payload = chatPayload("setChatMemberTag")
        payload.addInt("user_id", orThrow(this.from, "setChatMemberTag").id)
        payload.addValue("tag", tag)
        invokeApi("setChatMemberTag", payload)
    }

    public func setChatMemberTag(userId: Int64, tag: String): Payload {
        let payload = chatUserPayload("setChatMemberTag", userId)
        payload.addValue("tag", tag)
        invokeApi("setChatMemberTag", payload)
    }

    public func banChatSenderChat(senderChatId: Int64): Payload {
        let payload = chatPayload("banChatSenderChat")
        payload.addInt("sender_chat_id", senderChatId)
        invokeApi("banChatSenderChat", payload)
    }

    public func unbanChatSenderChat(senderChatId: Int64): Payload {
        let payload = chatPayload("unbanChatSenderChat")
        payload.addInt("sender_chat_id", senderChatId)
        invokeApi("unbanChatSenderChat", payload)
    }

    public func setChatPermissions(permissionsJson: String): Payload {
        let payload = chatPayload("setChatPermissions")
        payload.addRawJson("permissions", permissionsJson)
        invokeApi("setChatPermissions", payload)
    }

    public func exportChatInviteLink(): Payload {
        invokeApi("exportChatInviteLink", chatPayload("exportChatInviteLink"))
    }

    public func createChatInviteLink(): Payload {
        invokeApi("createChatInviteLink", chatPayload("createChatInviteLink"))
    }

    public func editChatInviteLink(inviteLink: String): Payload {
        let payload = chatPayload("editChatInviteLink")
        payload.addValue("invite_link", inviteLink)
        invokeApi("editChatInviteLink", payload)
    }

    public func createChatSubscriptionInviteLink(subscriptionPeriod: Int64, subscriptionPrice: Int64): Payload {
        let payload = chatPayload("createChatSubscriptionInviteLink")
        payload.addInt("subscription_period", subscriptionPeriod)
        payload.addInt("subscription_price", subscriptionPrice)
        invokeApi("createChatSubscriptionInviteLink", payload)
    }

    public func editChatSubscriptionInviteLink(inviteLink: String): Payload {
        let payload = chatPayload("editChatSubscriptionInviteLink")
        payload.addValue("invite_link", inviteLink)
        invokeApi("editChatSubscriptionInviteLink", payload)
    }

    public func revokeChatInviteLink(inviteLink: String): Payload {
        let payload = chatPayload("editChatInviteLink")
        payload.addValue("invite_link", inviteLink)
        invokeApi("revokeChatInviteLink", payload)
    }

    public func getManagedBotToken(): Payload {
        invokeApi("getManagedBotToken", managedBotPayload("getManagedBotToken"))
    }

    public func replaceManagedBotToken(): Payload {
        invokeApi("replaceManagedBotToken", managedBotPayload("getManagedBotToken"))
    }

    public func approveChatJoinRequest(userId: Int64): Payload {
        let payload = chatUserPayload("approveChatJoinRequest", userId)
        invokeApi("approveChatJoinRequest", payload)
    }

    public func declineChatJoinRequest(userId: Int64): Payload {
        let payload = chatUserPayload("declineChatJoinRequest", userId)
        invokeApi("declineChatJoinRequest", payload)
    }

    public func approveSuggestedPost(): Payload {
        invokeApi("approveSuggestedPost", messageTargetPayload("approveSuggestedPost"))
    }

    public func declineSuggestedPost(): Payload {
        invokeApi("declineSuggestedPost", messageTargetPayload("declineSuggestedPost"))
    }

    public func setChatPhoto(photo: String): Payload {
        let payload = chatPayload("setChatPhoto")
        payload.addValue("photo", photo)
        invokeApi("setChatPhoto", payload)
    }

    public func deleteChatPhoto(): Payload {
        invokeApi("deleteChatPhoto", chatPayload("deleteChatPhoto"))
    }

    public func setChatTitle(title: String): Payload {
        let payload = chatPayload("setChatTitle")
        payload.addValue("title", title)
        invokeApi("setChatTitle", payload)
    }

    public func setChatDescription(description: String): Payload {
        let payload = chatPayload("setChatDescription")
        payload.addValue("description", description)
        invokeApi("setChatDescription", payload)
    }

    public func pinChatMessage(messageId: Int64): Payload {
        let payload = chatPayload("pinChatMessage")
        payload.addInt("message_id", messageId)
        addBusinessConnectionIfPresent(payload)
        invokeApi("pinChatMessage", payload)
    }

    public func unpinChatMessage(messageId: Int64): Payload {
        let payload = chatPayload("unpinChatMessage")
        payload.addInt("message_id", messageId)
        addBusinessConnectionIfPresent(payload)
        invokeApi("unpinChatMessage", payload)
    }

    public func unpinChatMessage(): Payload {
        let payload = chatPayload("unpinChatMessage")
        addBusinessConnectionIfPresent(payload)
        invokeApi("unpinChatMessage", payload)
    }

    public func unpinAllChatMessages(): Payload {
        invokeApi("unpinAllChatMessages", chatPayload("unpinAllChatMessages"))
    }

    public func leaveChat(): Payload {
        invokeApi("leaveChat", chatPayload("leaveChat"))
    }

    public func getChat(): Payload {
        invokeApi("getChat", chatPayload("getChat"))
    }

    public func getChatAdministrators(): Payload {
        invokeApi("getChatAdministrators", chatPayload("getChatAdministrators"))
    }

    public func getChatMembersCount(): Payload {
        getChatMemberCount()
    }

    public func getChatMemberCount(): Payload {
        invokeApi("getChatMemberCount", chatPayload("getChatMemberCount"))
    }

    public func getAuthor(): Payload {
        let payload = chatAuthorPayload("getAuthor")
        invokeApi("getChatMember", payload)
    }

    public func getChatMember(userId: Int64): Payload {
        let payload = chatUserPayload("getChatMember", userId)
        invokeApi("getChatMember", payload)
    }

    public func setChatStickerSet(stickerSetName: String): Payload {
        let payload = chatPayload("setChatStickerSet")
        payload.addValue("sticker_set_name", stickerSetName)
        invokeApi("setChatStickerSet", payload)
    }

    public func deleteChatStickerSet(): Payload {
        invokeApi("deleteChatStickerSet", chatPayload("deleteChatStickerSet"))
    }

    public func createForumTopic(name: String): Payload {
        let payload = chatPayload("createForumTopic")
        payload.addValue("name", name)
        invokeApi("createForumTopic", payload)
    }

    public func editForumTopic(): Payload {
        invokeApi("editForumTopic", forumTopicPayload("editForumTopic"))
    }

    public func closeForumTopic(): Payload {
        invokeApi("closeForumTopic", forumTopicPayload("closeForumTopic"))
    }

    public func reopenForumTopic(): Payload {
        invokeApi("reopenForumTopic", forumTopicPayload("reopenForumTopic"))
    }

    public func deleteForumTopic(): Payload {
        invokeApi("deleteForumTopic", forumTopicPayload("deleteForumTopic"))
    }

    public func unpinAllForumTopicMessages(): Payload {
        invokeApi("unpinAllForumTopicMessages", forumTopicPayload("unpinAllForumTopicMessages"))
    }

    public func editGeneralForumTopic(name: String): Payload {
        let payload = chatPayload("editGeneralForumTopic")
        payload.addValue("name", name)
        invokeApi("editGeneralForumTopic", payload)
    }

    public func closeGeneralForumTopic(): Payload {
        invokeApi("closeGeneralForumTopic", chatPayload("closeGeneralForumTopic"))
    }

    public func reopenGeneralForumTopic(): Payload {
        invokeApi("reopenGeneralForumTopic", chatPayload("reopenGeneralForumTopic"))
    }

    public func hideGeneralForumTopic(): Payload {
        invokeApi("hideGeneralForumTopic", chatPayload("hideGeneralForumTopic"))
    }

    public func unhideGeneralForumTopic(): Payload {
        invokeApi("unhideGeneralForumTopic", chatPayload("unhideGeneralForumTopic"))
    }

    public func unpinAllGeneralForumTopicMessages(): Payload {
        invokeApi("unpinAllGeneralForumTopicMessages", chatPayload("unpinAllGeneralForumTopicMessages"))
    }

    public func answerCallbackQuery(text: String): Payload {
        let payload = callbackQueryPayload("answerCallbackQuery")
        payload.addValue("text", text)
        invokeApi("answerCallbackQuery", payload)
    }

    public func answerCallbackQuery(): Payload {
        invokeApi("answerCallbackQuery", callbackQueryPayload("answerCallbackQuery"))
    }

    public func setChatMenuButton(): Payload {
        invokeApi("setChatMenuButton", Payload(""))
    }

    public func getChatMenuButton(): Payload {
        invokeApi("getChatMenuButton", Payload(""))
    }

    public func setMyDefaultAdministratorRights(): Payload {
        invokeApi("setMyDefaultAdministratorRights", Payload(""))
    }

    public func getMyDefaultAdministratorRights(): Payload {
        invokeApi("getMyDefaultAdministratorRights", Payload(""))
    }

    public func editMessageText(text: String): Payload {
        let payload = inlineOrMessageTargetPayload("editMessageText")
        payload.addValue("text", text)
        invokeInlineOrMessageApi("editMessageText", "editMessageTextInline", payload)
    }

    public func editMessageCaption(caption: String): Payload {
        let payload = inlineOrMessageTargetPayload("editMessageCaption")
        payload.addValue("caption", caption)
        invokeInlineOrMessageApi("editMessageCaption", "editMessageCaptionInline", payload)
    }

    public func editMessageMedia(media: String): Payload {
        let payload = inlineOrMessageTargetPayload("editMessageMedia")
        payload.addRawJson("media", media)
        invokeInlineOrMessageApi("editMessageMedia", "editMessageMediaInline", payload)
    }

    public func editMessageReplyMarkup(replyMarkup: String): Payload {
        let payload = inlineOrMessageTargetPayload("editMessageReplyMarkup")
        payload.addRawJson("reply_markup", replyMarkup)
        invokeInlineOrMessageApi("editMessageReplyMarkup", "editMessageReplyMarkupInline", payload)
    }

    public func stopPoll(): Payload {
        invokeApi("stopPoll", messageTargetPayload("stopPoll"))
    }

    public func deleteMessage(): Payload {
        invokeApi("deleteMessage", messageTargetPayload("deleteMessage"))
    }

    public func deleteMessages(messageIds: String): Payload {
        let payload = chatPayload("deleteMessages")
        payload.addRawJson("message_ids", messageIds)
        invokeApi("deleteMessages", payload)
    }

    public func deleteMessages(messageIds: Array<Int64>): Payload {
        deleteMessages(intArrayJson(messageIds))
    }

    public func deleteBusinessMessages(messageIds: String): Payload {
        let payload = businessPayload("deleteBusinessMessages")
        payload.addRawJson("message_ids", messageIds)
        invokeApi("deleteBusinessMessages", payload)
    }

    public func deleteBusinessMessages(messageIds: Array<Int64>): Payload {
        deleteBusinessMessages(intArrayJson(messageIds))
    }

    public func setBusinessAccountName(firstName: String): Payload {
        let payload = businessPayload("setBusinessAccountName")
        payload.addValue("first_name", firstName)
        invokeApi("setBusinessAccountName", payload)
    }

    public func setBusinessAccountUsername(username: String): Payload {
        let payload = businessPayload("setBusinessAccountUsername")
        payload.addValue("username", username)
        invokeApi("setBusinessAccountUsername", payload)
    }

    public func setBusinessAccountBio(bio: String): Payload {
        let payload = businessPayload("setBusinessAccountBio")
        payload.addValue("bio", bio)
        invokeApi("setBusinessAccountBio", payload)
    }

    public func setBusinessAccountProfilePhoto(photo: String): Payload {
        let payload = businessPayload("setBusinessAccountProfilePhoto")
        payload.addRawJson("photo", photo)
        invokeApi("setBusinessAccountProfilePhoto", payload)
    }

    public func removeBusinessAccountProfilePhoto(): Payload {
        invokeApi("removeBusinessAccountProfilePhoto", businessPayload("removeBusinessAccountProfilePhoto"))
    }

    public func setBusinessAccountGiftSettings(showGiftButton: Bool, acceptedGiftTypes: String): Payload {
        let payload = businessPayload("setBusinessAccountGiftSettings")
        payload.addBool("show_gift_button", showGiftButton)
        payload.addRawJson("accepted_gift_types", acceptedGiftTypes)
        invokeApi("setBusinessAccountGiftSettings", payload)
    }

    public func getBusinessAccountStarBalance(): Payload {
        invokeApi("getBusinessAccountStarBalance", businessPayload("getBusinessAccountStarBalance"))
    }

    public func transferBusinessAccountStars(starCount: Int64): Payload {
        let payload = businessPayload("transferBusinessAccountStars")
        payload.addInt("star_count", starCount)
        invokeApi("transferBusinessAccountStars", payload)
    }

    public func getBusinessAccountGifts(): Payload {
        invokeApi("getBusinessAccountGifts", businessPayload("getBusinessAccountGifts"))
    }

    public func convertGiftToStars(ownedGiftId: String): Payload {
        let payload = businessPayload("convertGiftToStars")
        payload.addValue("owned_gift_id", ownedGiftId)
        invokeApi("convertGiftToStars", payload)
    }

    public func upgradeGift(ownedGiftId: String): Payload {
        let payload = businessPayload("upgradeGift")
        payload.addValue("owned_gift_id", ownedGiftId)
        invokeApi("upgradeGift", payload)
    }

    public func transferGift(ownedGiftId: String, newOwnerChatId: Int64, starCount: Int64): Payload {
        let payload = businessPayload("transferGift")
        payload.addValue("owned_gift_id", ownedGiftId)
        payload.addInt("new_owner_chat_id", newOwnerChatId)
        payload.addInt("star_count", starCount)
        invokeApi("transferGift", payload)
    }

    public func postStory(content: String, activePeriod: Int64): Payload {
        let payload = businessPayload("postStory")
        payload.addRawJson("content", content)
        payload.addInt("active_period", activePeriod)
        invokeApi("postStory", payload)
    }

    public func repostStory(fromChatId: Int64, fromStoryId: Int64, activePeriod: Int64): Payload {
        let payload = businessPayload("repostStory")
        payload.addInt("from_chat_id", fromChatId)
        payload.addInt("from_story_id", fromStoryId)
        payload.addInt("active_period", activePeriod)
        invokeApi("repostStory", payload)
    }

    public func editStory(storyId: Int64, content: String): Payload {
        let payload = businessPayload("editStory")
        payload.addInt("story_id", storyId)
        payload.addRawJson("content", content)
        invokeApi("editStory", payload)
    }

    public func deleteStory(storyId: Int64): Payload {
        let payload = businessPayload("deleteStory")
        payload.addInt("story_id", storyId)
        invokeApi("deleteStory", payload)
    }

    public func replyWithSticker(sticker: String): Payload {
        let payload = defaultReplyPayload("sendSticker")
        payload.addValue("sticker", sticker)
        invokeApi("sendSticker", payload)
    }

    public func getCustomEmojiStickers(customEmojiIds: String): Payload {
        let payload = Payload("")
        payload.addRawJson("custom_emoji_ids", customEmojiIds)
        invokeApi("getCustomEmojiStickers", payload)
    }

    public func replyWithGift(giftId: String): Payload {
        let payload = fromPayload("sendGift")
        payload.addValue("gift_id", giftId)
        invokeApi("sendGift", payload)
    }

    public func giftPremiumSubscription(monthCount: Int64, starCount: Int64): Payload {
        let payload = fromPayload("giftPremiumSubscription")
        payload.addInt("month_count", monthCount)
        payload.addInt("star_count", starCount)
        invokeApi("giftPremiumSubscription", payload)
    }

    public func replyWithGiftToChannel(giftId: String): Payload {
        let payload = chatPayload("sendGift")
        payload.addValue("gift_id", giftId)
        invokeApi("sendGiftToChannel", payload)
    }

    public func answerInlineQuery(resultsJson: String): Payload {
        let payload = inlineQueryPayload("answerInlineQuery")
        payload.addRawJson("results", resultsJson)
        invokeApi("answerInlineQuery", payload)
    }

    public func savePreparedInlineMessage(resultJson: String): Payload {
        let payload = fromPayload("savePreparedInlineMessage")
        payload.addRawJson("result", resultJson)
        invokeApi("savePreparedInlineMessage", payload)
    }

    public func savePreparedKeyboardButton(buttonJson: String): Payload {
        let payload = fromPayload("savePreparedKeyboardButton")
        payload.addRawJson("button", buttonJson)
        invokeApi("savePreparedKeyboardButton", payload)
    }

    public func replyWithInvoice(title: String, description: String, invoicePayload: String, currency: String, pricesJson: String): Payload {
        let payload = invoiceReplyPayload("sendInvoice")
        payload.addValue("title", title)
        payload.addValue("description", description)
        payload.addValue("payload", invoicePayload)
        payload.addValue("currency", currency)
        payload.addRawJson("prices", pricesJson)
        invokeApi("sendInvoice", payload)
    }

    public func answerShippingQuery(ok: Bool): Payload {
        let payload = shippingQueryPayload("answerShippingQuery")
        payload.addBool("ok", ok)
        invokeApi("answerShippingQuery", payload)
    }

    public func answerPreCheckoutQuery(ok: Bool): Payload {
        let payload = preCheckoutQueryPayload("answerPreCheckoutQuery")
        payload.addBool("ok", ok)
        invokeApi("answerPreCheckoutQuery", payload)
    }

    public func answerPreCheckoutQuery(ok: Bool, errorMessage: String): Payload {
        let payload = preCheckoutQueryPayload("answerPreCheckoutQuery")
        payload.addBool("ok", ok)
        payload.addValue("error_message", errorMessage)
        invokeApi("answerPreCheckoutQuery", payload)
    }

    public func refundStarPayment(telegramPaymentChargeId: String): Payload {
        let payload = fromPayload("refundStarPayment")
        payload.addValue("telegram_payment_charge_id", telegramPaymentChargeId)
        invokeApi("refundStarPayment", payload)
    }

    public func editUserStarSubscription(telegramPaymentChargeId: String, isCanceled: Bool): Payload {
        let payload = fromPayload("editUserStarSubscription")
        payload.addValue("telegram_payment_charge_id", telegramPaymentChargeId)
        payload.addBool("is_canceled", isCanceled)
        invokeApi("editUserStarSubscription", payload)
    }

    public func verifyUser(): Payload {
        invokeApi("verifyUser", fromPayload("verifyUser"))
    }

    public func verifyChat(): Payload {
        invokeApi("verifyChat", chatPayload("verifyChat"))
    }

    public func removeUserVerification(): Payload {
        invokeApi("removeUserVerification", fromPayload("removeUserVerification"))
    }

    public func removeChatVerification(): Payload {
        invokeApi("removeChatVerification", chatPayload("removeChatVerification"))
    }

    public func readBusinessMessage(): Payload {
        let payload = businessMessageTargetPayload("readBusinessMessage")
        invokeApi("readBusinessMessage", payload)
    }

    public func setPassportDataErrors(errorsJson: String): Payload {
        let payload = fromPayload("setPassportDataErrors")
        payload.addRawJson("errors", errorsJson)
        invokeApi("setPassportDataErrors", payload)
    }

    public func replyWithGame(gameShortName: String): Payload {
        let payload = defaultReplyPayloadWithoutDirectTopic("sendGame")
        payload.addValue("game_short_name", gameShortName)
        invokeApi("sendGame", payload)
    }

    private func defaultReplyPayload(method: String): Payload {
        defaultReplyPayload(method, true)
    }

    private func defaultReplyPayloadWithoutDirectTopic(method: String): Payload {
        defaultReplyPayload(method, false)
    }

    private func defaultReplyPayload(method: String, includeDirectTopic: Bool): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", orThrow(this.chatId, method))
        match (this.businessConnectionId) {
            case Some(id) => payload.addValue("business_connection_id", id)
            case None => ()
        }
        match (this.msg) {
            case Some(message) =>
                if (message.isTopicMessage) { payload.addInt("message_thread_id", message.messageThreadId) }
            case None => ()
        }
        if (includeDirectTopic) {
            addDirectMessagesTopicIfPresent(payload)
        }
        payload
    }

    private func draftReplyPayload(method: String): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", orThrow(this.chatId, method))
        match (this.msg) {
            case Some(message) =>
                if (message.isTopicMessage) { payload.addInt("message_thread_id", message.messageThreadId) }
            case None => ()
        }
        payload
    }

    private func chatActionPayload(method: String): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", orThrow(this.chatId, method))
        match (this.businessConnectionId) {
            case Some(id) => payload.addValue("business_connection_id", id)
            case None => ()
        }
        match (this.msg) {
            case Some(message) =>
                if (message.messageThreadId != 0) { payload.addInt("message_thread_id", message.messageThreadId) }
            case None => ()
        }
        payload
    }

    private func invoiceReplyPayload(method: String): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", orThrow(this.chatId, method))
        match (this.msg) {
            case Some(message) =>
                if (message.isTopicMessage) { payload.addInt("message_thread_id", message.messageThreadId) }
            case None => ()
        }
        addDirectMessagesTopicIfPresent(payload)
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
        invokeApi(method, payload)
    }

    private func chatPayload(method: String): Payload {
        let payload = Payload("")
        payload.addInt("chat_id", orThrow(this.chatId, method))
        payload
    }

    private func messageTargetPayload(method: String): Payload {
        let payload = chatPayload(method)
        payload.addInt("message_id", orThrow(this.msgId, method))
        payload
    }

    private func businessPayload(method: String): Payload {
        let payload = Payload("")
        payload.addValue("business_connection_id", orThrow(this.businessConnectionId, method))
        payload
    }

    private func businessMessageTargetPayload(method: String): Payload {
        let payload = businessPayload(method)
        payload.addInt("chat_id", orThrow(this.chatId, method))
        payload.addInt("message_id", orThrow(this.msgId, method))
        payload
    }

    private func fromPayload(method: String): Payload {
        let payload = Payload("")
        payload.addInt("user_id", orThrow(this.from, method).id)
        payload
    }

    private func chatUserPayload(method: String, userId: Int64): Payload {
        let payload = chatPayload(method)
        payload.addInt("user_id", orThrow(userId, method))
        payload
    }

    private func chatAuthorPayload(method: String): Payload {
        let payload = chatPayload(method)
        payload.addInt("user_id", orThrow(this.from, method).id)
        payload
    }

    private func callbackQueryPayload(method: String): Payload {
        let payload = Payload("")
        payload.addValue("callback_query_id", callbackQueryId(method))
        payload
    }

    private func inlineQueryPayload(method: String): Payload {
        let payload = Payload("")
        payload.addValue("inline_query_id", inlineQueryId(method))
        payload
    }

    private func shippingQueryPayload(method: String): Payload {
        let payload = Payload("")
        payload.addValue("shipping_query_id", shippingQueryId(method))
        payload
    }

    private func preCheckoutQueryPayload(method: String): Payload {
        let payload = Payload("")
        payload.addValue("pre_checkout_query_id", preCheckoutQueryId(method))
        payload
    }

    private func managedBotPayload(method: String): Payload {
        let payload = Payload("")
        payload.addInt("bot_id", orThrow(this.managedBot, method).user.id)
        payload
    }

    private func forumTopicPayload(method: String): Payload {
        let message = orThrow(this.msg, method)
        let payload = Payload("")
        payload.addInt("chat_id", orThrow(message.chat.id, method))
        payload.addInt("message_thread_id", orThrow(message.messageThreadId, method))
        payload
    }

    private func inlineOrMessageTargetPayload(method: String): Payload {
        let payload = Payload("")
        match (this.inlineMessageId) {
            case Some(id) => payload.addValue("inline_message_id", id)
            case None =>
                payload.addInt("chat_id", orThrow(this.chatId, method))
                payload.addInt("message_id", orThrow(this.msgId, method))
        }
        addBusinessConnectionIfPresent(payload)
        payload
    }

    private func addBusinessConnectionIfPresent(payload: Payload): Unit {
        match (this.businessConnectionId) {
            case Some(id) => payload.addValue("business_connection_id", id)
            case None => ()
        }
    }

    private func addDirectMessagesTopicIfPresent(payload: Payload): Unit {
        match (this.msg) {
            case Some(message) =>
                if (message.directMessagesTopicId != 0) { payload.addInt("direct_messages_topic_id", message.directMessagesTopicId) }
            case None => ()
        }
    }

    private func callbackQueryId(method: String): String {
        match (this.callbackQuery) {
            case Some(callbackQuery) =>
                if (!callbackQuery.data.isEmpty()) { return callbackQuery.data }
                if (!callbackQuery.gameShortName.isEmpty()) { return callbackQuery.gameShortName }
                if (!callbackQuery.inlineMessageId.isEmpty()) { return callbackQuery.inlineMessageId }
            case None => ()
        }
        throw Exception("Missing information for API call to " + method)
    }

    private func inlineQueryId(method: String): String {
        match (this.inlineQuery) {
            case Some(inlineQuery) =>
                if (!inlineQuery.query.isEmpty()) { return inlineQuery.query }
            case None => ()
        }
        throw Exception("Missing information for API call to " + method)
    }

    private func shippingQueryId(method: String): String {
        match (this.shippingQuery) {
            case Some(shippingQuery) =>
                if (!shippingQuery.invoicePayload.isEmpty()) { return shippingQuery.invoicePayload }
            case None => ()
        }
        throw Exception("Missing information for API call to " + method)
    }

    private func preCheckoutQueryId(method: String): String {
        match (this.preCheckoutQuery) {
            case Some(preCheckoutQuery) =>
                if (!preCheckoutQuery.invoicePayload.isEmpty()) { return preCheckoutQuery.invoicePayload }
            case None => ()
        }
        throw Exception("Missing information for API call to " + method)
    }

    private func invokeInlineOrMessageApi(messageMethod: String, inlineMethod: String, payload: Payload): Payload {
        match (this.inlineMessageId) {
            case Some(_) => return invokeApi(inlineMethod, payload)
            case None => ()
        }
        invokeApi(messageMethod, payload)
    }

    private func invokeApi(method: String, payload: Payload): Payload {
        if (method == "answerCallbackQuery") { return this.api.answerCallbackQuery(payload) }
        if (method == "answerInlineQuery") { return this.api.answerInlineQuery(payload) }
        if (method == "answerPreCheckoutQuery") { return this.api.answerPreCheckoutQuery(payload) }
        if (method == "answerShippingQuery") { return this.api.answerShippingQuery(payload) }
        if (method == "approveChatJoinRequest") { return this.api.approveChatJoinRequest(payload) }
        if (method == "approveSuggestedPost") { return this.api.approveSuggestedPost(payload) }
        if (method == "banChatMember") { return this.api.banChatMember(payload) }
        if (method == "banChatSenderChat") { return this.api.banChatSenderChat(payload) }
        if (method == "closeForumTopic") { return this.api.closeForumTopic(payload) }
        if (method == "closeGeneralForumTopic") { return this.api.closeGeneralForumTopic(payload) }
        if (method == "convertGiftToStars") { return this.api.convertGiftToStars(payload) }
        if (method == "copyMessage") { return this.api.copyMessage(payload) }
        if (method == "copyMessages") { return this.api.copyMessages(payload) }
        if (method == "createChatInviteLink") { return this.api.createChatInviteLink(payload) }
        if (method == "createChatSubscriptionInviteLink") { return this.api.createChatSubscriptionInviteLink(payload) }
        if (method == "createForumTopic") { return this.api.createForumTopic(payload) }
        if (method == "declineChatJoinRequest") { return this.api.declineChatJoinRequest(payload) }
        if (method == "declineSuggestedPost") { return this.api.declineSuggestedPost(payload) }
        if (method == "deleteBusinessMessages") { return this.api.deleteBusinessMessages(payload) }
        if (method == "deleteChatPhoto") { return this.api.deleteChatPhoto(payload) }
        if (method == "deleteChatStickerSet") { return this.api.deleteChatStickerSet(payload) }
        if (method == "deleteForumTopic") { return this.api.deleteForumTopic(payload) }
        if (method == "deleteMessage") { return this.api.deleteMessage(payload) }
        if (method == "deleteMessages") { return this.api.deleteMessages(payload) }
        if (method == "deleteStory") { return this.api.deleteStory(payload) }
        if (method == "editChatInviteLink") { return this.api.editChatInviteLink(payload) }
        if (method == "editChatSubscriptionInviteLink") { return this.api.editChatSubscriptionInviteLink(payload) }
        if (method == "editForumTopic") { return this.api.editForumTopic(payload) }
        if (method == "editGeneralForumTopic") { return this.api.editGeneralForumTopic(payload) }
        if (method == "editMessageCaption") { return this.api.editMessageCaption(payload) }
        if (method == "editMessageCaptionInline") { return this.api.editMessageCaptionInline(payload) }
        if (method == "editMessageChecklist") { return this.api.editMessageChecklist(payload) }
        if (method == "editMessageLiveLocation") { return this.api.editMessageLiveLocation(payload) }
        if (method == "editMessageLiveLocationInline") { return this.api.editMessageLiveLocationInline(payload) }
        if (method == "editMessageMedia") { return this.api.editMessageMedia(payload) }
        if (method == "editMessageMediaInline") { return this.api.editMessageMediaInline(payload) }
        if (method == "editMessageReplyMarkup") { return this.api.editMessageReplyMarkup(payload) }
        if (method == "editMessageReplyMarkupInline") { return this.api.editMessageReplyMarkupInline(payload) }
        if (method == "editMessageText") { return this.api.editMessageText(payload) }
        if (method == "editMessageTextInline") { return this.api.editMessageTextInline(payload) }
        if (method == "editStory") { return this.api.editStory(payload) }
        if (method == "editUserStarSubscription") { return this.api.editUserStarSubscription(payload) }
        if (method == "exportChatInviteLink") { return this.api.exportChatInviteLink(payload) }
        if (method == "forwardMessage") { return this.api.forwardMessage(payload) }
        if (method == "forwardMessages") { return this.api.forwardMessages(payload) }
        if (method == "getBusinessAccountGifts") { return this.api.getBusinessAccountGifts(payload) }
        if (method == "getBusinessAccountStarBalance") { return this.api.getBusinessAccountStarBalance(payload) }
        if (method == "getBusinessConnection") { return this.api.getBusinessConnection(payload) }
        if (method == "getChat") { return this.api.getChat(payload) }
        if (method == "getChatAdministrators") { return this.api.getChatAdministrators(payload) }
        if (method == "getChatGifts") { return this.api.getChatGifts(payload) }
        if (method == "getChatMember") { return this.api.getChatMember(payload) }
        if (method == "getChatMemberCount") { return this.api.getChatMemberCount(payload) }
        if (method == "getChatMenuButton") { return this.api.getChatMenuButton(payload) }
        if (method == "getCustomEmojiStickers") { return this.api.getCustomEmojiStickers(payload) }
        if (method == "getFile") { return this.api.getFile(payload) }
        if (method == "getManagedBotToken") { return this.api.getManagedBotToken(payload) }
        if (method == "getMyDefaultAdministratorRights") { return this.api.getMyDefaultAdministratorRights(payload) }
        if (method == "getUserChatBoosts") { return this.api.getUserChatBoosts(payload) }
        if (method == "getUserGifts") { return this.api.getUserGifts(payload) }
        if (method == "getUserProfileAudios") { return this.api.getUserProfileAudios(payload) }
        if (method == "getUserProfilePhotos") { return this.api.getUserProfilePhotos(payload) }
        if (method == "giftPremiumSubscription") { return this.api.giftPremiumSubscription(payload) }
        if (method == "hideGeneralForumTopic") { return this.api.hideGeneralForumTopic(payload) }
        if (method == "leaveChat") { return this.api.leaveChat(payload) }
        if (method == "pinChatMessage") { return this.api.pinChatMessage(payload) }
        if (method == "postStory") { return this.api.postStory(payload) }
        if (method == "promoteChatMember") { return this.api.promoteChatMember(payload) }
        if (method == "readBusinessMessage") { return this.api.readBusinessMessage(payload) }
        if (method == "refundStarPayment") { return this.api.refundStarPayment(payload) }
        if (method == "removeBusinessAccountProfilePhoto") { return this.api.removeBusinessAccountProfilePhoto(payload) }
        if (method == "removeChatVerification") { return this.api.removeChatVerification(payload) }
        if (method == "removeUserVerification") { return this.api.removeUserVerification(payload) }
        if (method == "reopenForumTopic") { return this.api.reopenForumTopic(payload) }
        if (method == "reopenGeneralForumTopic") { return this.api.reopenGeneralForumTopic(payload) }
        if (method == "replaceManagedBotToken") { return this.api.replaceManagedBotToken(payload) }
        if (method == "repostStory") { return this.api.repostStory(payload) }
        if (method == "restrictChatMember") { return this.api.restrictChatMember(payload) }
        if (method == "revokeChatInviteLink") { return this.api.revokeChatInviteLink(payload) }
        if (method == "savePreparedInlineMessage") { return this.api.savePreparedInlineMessage(payload) }
        if (method == "savePreparedKeyboardButton") { return this.api.savePreparedKeyboardButton(payload) }
        if (method == "sendAnimation") { return this.api.sendAnimation(payload) }
        if (method == "sendAudio") { return this.api.sendAudio(payload) }
        if (method == "sendChatAction") { return this.api.sendChatAction(payload) }
        if (method == "sendChecklist") { return this.api.sendChecklist(payload) }
        if (method == "sendContact") { return this.api.sendContact(payload) }
        if (method == "sendDice") { return this.api.sendDice(payload) }
        if (method == "sendDocument") { return this.api.sendDocument(payload) }
        if (method == "sendGame") { return this.api.sendGame(payload) }
        if (method == "sendGift") { return this.api.sendGift(payload) }
        if (method == "sendGiftToChannel") { return this.api.sendGiftToChannel(payload) }
        if (method == "sendInvoice") { return this.api.sendInvoice(payload) }
        if (method == "sendLocation") { return this.api.sendLocation(payload) }
        if (method == "sendMediaGroup") { return this.api.sendMediaGroup(payload) }
        if (method == "sendMessage") { return this.api.sendMessage(payload) }
        if (method == "sendMessageDraft") { return this.api.sendMessageDraft(payload) }
        if (method == "sendPaidMedia") { return this.api.sendPaidMedia(payload) }
        if (method == "sendPhoto") { return this.api.sendPhoto(payload) }
        if (method == "sendPoll") { return this.api.sendPoll(payload) }
        if (method == "sendSticker") { return this.api.sendSticker(payload) }
        if (method == "sendVenue") { return this.api.sendVenue(payload) }
        if (method == "sendVideo") { return this.api.sendVideo(payload) }
        if (method == "sendVideoNote") { return this.api.sendVideoNote(payload) }
        if (method == "sendVoice") { return this.api.sendVoice(payload) }
        if (method == "setBusinessAccountBio") { return this.api.setBusinessAccountBio(payload) }
        if (method == "setBusinessAccountGiftSettings") { return this.api.setBusinessAccountGiftSettings(payload) }
        if (method == "setBusinessAccountName") { return this.api.setBusinessAccountName(payload) }
        if (method == "setBusinessAccountProfilePhoto") { return this.api.setBusinessAccountProfilePhoto(payload) }
        if (method == "setBusinessAccountUsername") { return this.api.setBusinessAccountUsername(payload) }
        if (method == "setChatAdministratorCustomTitle") { return this.api.setChatAdministratorCustomTitle(payload) }
        if (method == "setChatDescription") { return this.api.setChatDescription(payload) }
        if (method == "setChatMemberTag") { return this.api.setChatMemberTag(payload) }
        if (method == "setChatMenuButton") { return this.api.setChatMenuButton(payload) }
        if (method == "setChatPermissions") { return this.api.setChatPermissions(payload) }
        if (method == "setChatPhoto") { return this.api.setChatPhoto(payload) }
        if (method == "setChatStickerSet") { return this.api.setChatStickerSet(payload) }
        if (method == "setChatTitle") { return this.api.setChatTitle(payload) }
        if (method == "setMessageReaction") { return this.api.setMessageReaction(payload) }
        if (method == "setMyDefaultAdministratorRights") { return this.api.setMyDefaultAdministratorRights(payload) }
        if (method == "setPassportDataErrors") { return this.api.setPassportDataErrors(payload) }
        if (method == "setUserEmojiStatus") { return this.api.setUserEmojiStatus(payload) }
        if (method == "stopMessageLiveLocation") { return this.api.stopMessageLiveLocation(payload) }
        if (method == "stopMessageLiveLocationInline") { return this.api.stopMessageLiveLocationInline(payload) }
        if (method == "stopPoll") { return this.api.stopPoll(payload) }
        if (method == "transferBusinessAccountStars") { return this.api.transferBusinessAccountStars(payload) }
        if (method == "transferGift") { return this.api.transferGift(payload) }
        if (method == "unbanChatMember") { return this.api.unbanChatMember(payload) }
        if (method == "unbanChatSenderChat") { return this.api.unbanChatSenderChat(payload) }
        if (method == "unhideGeneralForumTopic") { return this.api.unhideGeneralForumTopic(payload) }
        if (method == "unpinAllChatMessages") { return this.api.unpinAllChatMessages(payload) }
        if (method == "unpinAllForumTopicMessages") { return this.api.unpinAllForumTopicMessages(payload) }
        if (method == "unpinAllGeneralForumTopicMessages") { return this.api.unpinAllGeneralForumTopicMessages(payload) }
        if (method == "unpinChatMessage") { return this.api.unpinChatMessage(payload) }
        if (method == "upgradeGift") { return this.api.upgradeGift(payload) }
        if (method == "verifyChat") { return this.api.verifyChat(payload) }
        if (method == "verifyUser") { return this.api.verifyUser(payload) }
        throw Exception("Unsupported Context API target " + method)
    }
}

public func contextShortcutMappings(): Array<ContextShortcutMapping> {
    let mappings = ArrayList<ContextShortcutMapping>()
    for (target in contextShortcutApiTargets()) {
        mappings.add(ContextShortcutMapping(target, target, contextShortcutRequiredContext(target)))
    }
    mappings.toArray()
}

public func contextSourceDriftGate(): Array<ContextSourceDriftRow> {
    [
        ContextSourceDriftRow("src/context.ts update shortcuts", "Option update getter surface", 24, contextUpdateShortcutNames().size),
        ContextSourceDriftRow("src/context.ts aggregation shortcuts", "Option aggregate getter surface", 8, contextAggregateShortcutNames().size),
        ContextSourceDriftRow("src/context.ts StaticHas overload families", "Context.has runtime predicate families", 11, contextHasPredicateFamilies().size),
        ContextSourceDriftRow("src/context.ts trigger match writers", "ctx.match ContextMatch writer families", 8, contextMatchWriterFamilies().size),
        ContextSourceDriftRow("src/context.ts API shortcut methods", "Context typed API shortcut targets", 136, contextShortcutApiTargets().size)
    ]
}

public func contextSourceDriftGateOk(): Bool {
    for (row in contextSourceDriftGate()) {
        if (!row.ok) {
            return false
        }
    }
    true
}

public func contextUpdateShortcutNames(): Array<String> {
    [
        "message",
        "editedMessage",
        "channelPost",
        "editedChannelPost",
        "businessConnection",
        "businessMessage",
        "editedBusinessMessage",
        "deletedBusinessMessages",
        "messageReaction",
        "messageReactionCount",
        "inlineQuery",
        "chosenInlineResult",
        "callbackQuery",
        "shippingQuery",
        "preCheckoutQuery",
        "poll",
        "pollAnswer",
        "myChatMember",
        "chatMember",
        "managedBot",
        "chatJoinRequest",
        "chatBoost",
        "removedChatBoost",
        "purchasedPaidMedia"
    ]
}

public func contextAggregateShortcutNames(): Array<String> {
    [
        "msg",
        "chat",
        "senderChat",
        "from",
        "msgId",
        "chatId",
        "inlineMessageId",
        "businessConnectionId"
    ]
}

public func contextHasPredicateFamilies(): Array<String> {
    [
        "filterQuery",
        "text",
        "command",
        "reaction",
        "chatType",
        "callbackQuery",
        "gameQuery",
        "inlineQuery",
        "chosenInlineResult",
        "preCheckoutQuery",
        "shippingQuery"
    ]
}

public func contextMatchWriterFamilies(): Array<String> {
    [
        "text",
        "command",
        "callbackQuery",
        "gameQuery",
        "inlineQuery",
        "chosenInlineResult",
        "preCheckoutQuery",
        "shippingQuery"
    ]
}

public func contextShortcutApiTargets(): Array<String> {
    [
        "answerCallbackQuery",
        "answerInlineQuery",
        "answerPreCheckoutQuery",
        "answerShippingQuery",
        "approveChatJoinRequest",
        "approveSuggestedPost",
        "banChatMember",
        "banChatSenderChat",
        "closeForumTopic",
        "closeGeneralForumTopic",
        "convertGiftToStars",
        "copyMessage",
        "copyMessages",
        "createChatInviteLink",
        "createChatSubscriptionInviteLink",
        "createForumTopic",
        "declineChatJoinRequest",
        "declineSuggestedPost",
        "deleteBusinessMessages",
        "deleteChatPhoto",
        "deleteChatStickerSet",
        "deleteForumTopic",
        "deleteMessage",
        "deleteMessages",
        "deleteStory",
        "editChatInviteLink",
        "editChatSubscriptionInviteLink",
        "editForumTopic",
        "editGeneralForumTopic",
        "editMessageCaption",
        "editMessageCaptionInline",
        "editMessageChecklist",
        "editMessageLiveLocation",
        "editMessageLiveLocationInline",
        "editMessageMedia",
        "editMessageMediaInline",
        "editMessageReplyMarkup",
        "editMessageReplyMarkupInline",
        "editMessageText",
        "editMessageTextInline",
        "editStory",
        "editUserStarSubscription",
        "exportChatInviteLink",
        "forwardMessage",
        "forwardMessages",
        "getBusinessAccountGifts",
        "getBusinessAccountStarBalance",
        "getBusinessConnection",
        "getChat",
        "getChatAdministrators",
        "getChatGifts",
        "getChatMember",
        "getChatMemberCount",
        "getChatMenuButton",
        "getCustomEmojiStickers",
        "getFile",
        "getManagedBotToken",
        "getMyDefaultAdministratorRights",
        "getUserChatBoosts",
        "getUserGifts",
        "getUserProfileAudios",
        "getUserProfilePhotos",
        "giftPremiumSubscription",
        "hideGeneralForumTopic",
        "leaveChat",
        "pinChatMessage",
        "postStory",
        "promoteChatMember",
        "readBusinessMessage",
        "refundStarPayment",
        "removeBusinessAccountProfilePhoto",
        "removeChatVerification",
        "removeUserVerification",
        "reopenForumTopic",
        "reopenGeneralForumTopic",
        "replaceManagedBotToken",
        "repostStory",
        "restrictChatMember",
        "revokeChatInviteLink",
        "savePreparedInlineMessage",
        "savePreparedKeyboardButton",
        "sendAnimation",
        "sendAudio",
        "sendChatAction",
        "sendChecklist",
        "sendContact",
        "sendDice",
        "sendDocument",
        "sendGame",
        "sendGift",
        "sendGiftToChannel",
        "sendInvoice",
        "sendLocation",
        "sendMediaGroup",
        "sendMessage",
        "sendMessageDraft",
        "sendPaidMedia",
        "sendPhoto",
        "sendPoll",
        "sendSticker",
        "sendVenue",
        "sendVideo",
        "sendVideoNote",
        "sendVoice",
        "setBusinessAccountBio",
        "setBusinessAccountGiftSettings",
        "setBusinessAccountName",
        "setBusinessAccountProfilePhoto",
        "setBusinessAccountUsername",
        "setChatAdministratorCustomTitle",
        "setChatDescription",
        "setChatMemberTag",
        "setChatMenuButton",
        "setChatPermissions",
        "setChatPhoto",
        "setChatStickerSet",
        "setChatTitle",
        "setMessageReaction",
        "setMyDefaultAdministratorRights",
        "setPassportDataErrors",
        "setUserEmojiStatus",
        "stopMessageLiveLocation",
        "stopMessageLiveLocationInline",
        "stopPoll",
        "transferBusinessAccountStars",
        "transferGift",
        "unbanChatMember",
        "unbanChatSenderChat",
        "unhideGeneralForumTopic",
        "unpinAllChatMessages",
        "unpinAllForumTopicMessages",
        "unpinAllGeneralForumTopicMessages",
        "unpinChatMessage",
        "upgradeGift",
        "verifyChat",
        "verifyUser"
    ]
}

public func contextShortcutRequiredContext(target: String): String {
    if (target == "setChatMenuButton" || target == "getChatMenuButton" ||
        target == "setMyDefaultAdministratorRights" || target == "getMyDefaultAdministratorRights") {
        return "none"
    }
    if (target == "answerCallbackQuery") { return "callback_query_id" }
    if (target == "answerInlineQuery") { return "inline_query_id" }
    if (target == "answerShippingQuery") { return "shipping_query_id" }
    if (target == "answerPreCheckoutQuery") { return "pre_checkout_query_id" }
    if (target == "sendChecklist" || target == "editMessageChecklist" ||
        target == "deleteBusinessMessages" || target.startsWith("setBusinessAccount") ||
        target.startsWith("removeBusinessAccount") || target.startsWith("getBusinessAccount") ||
        target == "transferBusinessAccountStars" || target == "convertGiftToStars" ||
        target == "upgradeGift" || target == "transferGift" || target == "postStory" ||
        target == "repostStory" || target == "editStory" || target == "deleteStory" ||
        target == "readBusinessMessage" || target == "getBusinessConnection") {
        return "business_connection_id"
    }
    if (target == "getUserProfilePhotos" || target == "getUserProfileAudios" ||
        target == "setUserEmojiStatus" || target == "getUserChatBoosts" ||
        target == "getUserGifts" || target == "sendGift" ||
        target == "giftPremiumSubscription" || target == "savePreparedInlineMessage" ||
        target == "savePreparedKeyboardButton" || target == "refundStarPayment" ||
        target == "editUserStarSubscription" || target == "verifyUser" ||
        target == "removeUserVerification" || target == "setPassportDataErrors") {
        return "user_id"
    }
    if (target == "editMessageText" || target == "editMessageCaption" ||
        target == "editMessageMedia" || target == "editMessageReplyMarkup" ||
        target == "editMessageLiveLocation" || target == "stopMessageLiveLocation") {
        return "chat_id/message_id or inline_message_id"
    }
    if (target.endsWith("Inline")) { return "inline_message_id" }
    if (target == "forwardMessage" || target == "copyMessage") {
        return "chat_id, from_chat_id, message_id"
    }
    if (target == "forwardMessages" || target == "copyMessages") {
        return "chat_id, from_chat_id, message_ids"
    }
    if (target == "getFile") { return "file_id" }
    if (target == "getCustomEmojiStickers") { return "custom_emoji_ids" }
    if (target == "getManagedBotToken" || target == "replaceManagedBotToken") { return "bot_id" }
    if (target == "editForumTopic" || target == "closeForumTopic" ||
        target == "reopenForumTopic" || target == "deleteForumTopic" ||
        target == "unpinAllForumTopicMessages") {
        return "chat_id, message_thread_id"
    }
    if (target == "deleteMessage" || target == "stopPoll" || target == "approveSuggestedPost" ||
        target == "declineSuggestedPost" || target == "setMessageReaction") {
        return "chat_id, message_id"
    }
    if (target == "banChatMember" || target == "unbanChatMember" ||
        target == "restrictChatMember" || target == "promoteChatMember" ||
        target == "setChatAdministratorCustomTitle" || target == "setChatMemberTag" ||
        target == "getChatMember" || target == "approveChatJoinRequest" ||
        target == "declineChatJoinRequest") {
        return "chat_id, user_id"
    }
    "chat_id"
}

public func maybeUser(value: User): Option<User> {
    if (value.isPresent) { return Some(value) }
    None<User>
}

public func maybeChat(value: Chat): Option<Chat> {
    if (value.isPresent) { return Some(value) }
    None<Chat>
}

public func maybeMessage(value: Message): Option<Message> {
    if (value.isPresent) { return Some(value) }
    None<Message>
}

public func maybeBusinessConnection(value: BusinessConnection): Option<BusinessConnection> {
    if (value.isPresent) { return Some(value) }
    None<BusinessConnection>
}

public func maybeBusinessMessagesDeleted(value: BusinessMessagesDeleted): Option<BusinessMessagesDeleted> {
    if (value.isPresent) { return Some(value) }
    None<BusinessMessagesDeleted>
}

public func maybeMessageReactionUpdated(value: MessageReactionUpdated): Option<MessageReactionUpdated> {
    if (value.isPresent) { return Some(value) }
    None<MessageReactionUpdated>
}

public func maybeMessageReactionCountUpdated(value: MessageReactionCountUpdated): Option<MessageReactionCountUpdated> {
    if (value.isPresent) { return Some(value) }
    None<MessageReactionCountUpdated>
}

public func maybeInlineQuery(value: InlineQuery): Option<InlineQuery> {
    if (value.isPresent) { return Some(value) }
    None<InlineQuery>
}

public func maybeChosenInlineResult(value: ChosenInlineResult): Option<ChosenInlineResult> {
    if (value.isPresent) { return Some(value) }
    None<ChosenInlineResult>
}

public func maybeCallbackQuery(value: CallbackQuery): Option<CallbackQuery> {
    if (value.isPresent) { return Some(value) }
    None<CallbackQuery>
}

public func maybeShippingQuery(value: ShippingQuery): Option<ShippingQuery> {
    if (value.isPresent) { return Some(value) }
    None<ShippingQuery>
}

public func maybePreCheckoutQuery(value: PreCheckoutQuery): Option<PreCheckoutQuery> {
    if (value.isPresent) { return Some(value) }
    None<PreCheckoutQuery>
}

public func maybePoll(value: Poll): Option<Poll> {
    if (value.isPresent) { return Some(value) }
    None<Poll>
}

public func maybePollAnswer(value: PollAnswer): Option<PollAnswer> {
    if (value.isPresent) { return Some(value) }
    None<PollAnswer>
}

public func maybeChatMemberUpdated(value: ChatMemberUpdated): Option<ChatMemberUpdated> {
    if (value.isPresent) { return Some(value) }
    None<ChatMemberUpdated>
}

public func maybeManagedBotUpdate(value: ManagedBotUpdate): Option<ManagedBotUpdate> {
    if (value.isPresent) { return Some(value) }
    None<ManagedBotUpdate>
}

public func maybeChatJoinRequest(value: ChatJoinRequest): Option<ChatJoinRequest> {
    if (value.isPresent) { return Some(value) }
    None<ChatJoinRequest>
}

public func maybeChatBoostUpdated(value: ChatBoostUpdated): Option<ChatBoostUpdated> {
    if (value.isPresent) { return Some(value) }
    None<ChatBoostUpdated>
}

public func maybeChatBoostRemoved(value: ChatBoostRemoved): Option<ChatBoostRemoved> {
    if (value.isPresent) { return Some(value) }
    None<ChatBoostRemoved>
}

public func maybePurchasedPaidMedia(value: PurchasedPaidMedia): Option<PurchasedPaidMedia> {
    if (value.isPresent) { return Some(value) }
    None<PurchasedPaidMedia>
}

public func optionPresent<T>(value: Option<T>): Bool {
    match (value) {
        case Some(_) => true
        case None => false
    }
}

public func orThrow(value: Int64, method: String): Int64 {
    if (value == 0) {
        throw Exception("Missing information for API call to " + method)
    }
    value
}

public func orThrow<T>(value: Option<T>, method: String): T {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<Int64>, method: String): Int64 {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<String>, method: String): String {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<ContextMatch>, method: String): ContextMatch {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<User>, method: String): User {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<Chat>, method: String): Chat {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<Message>, method: String): Message {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<CallbackQuery>, method: String): CallbackQuery {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<InlineQuery>, method: String): InlineQuery {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<ChosenInlineResult>, method: String): ChosenInlineResult {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<PreCheckoutQuery>, method: String): PreCheckoutQuery {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<ShippingQuery>, method: String): ShippingQuery {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<MessageReactionUpdated>, method: String): MessageReactionUpdated {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: Option<ManagedBotUpdate>, method: String): ManagedBotUpdate {
    match (value) {
        case Some(v) => v
        case None => throw Exception("Missing information for API call to " + method)
    }
}

public func orThrow(value: String, method: String): String {
    if (value.isEmpty()) {
        throw Exception("Missing information for API call to " + method)
    }
    value
}

public func orThrow(value: User, method: String): User {
    if (!value.isPresent) {
        throw Exception("Missing information for API call to " + method)
    }
    value
}

public func orThrow(value: Message, method: String): Message {
    if (!value.isPresent) {
        throw Exception("Missing information for API call to " + method)
    }
    value
}

public func orThrow(value: ManagedBotUpdate, method: String): ManagedBotUpdate {
    if (!value.isPresent) {
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

public func triggerFn(trigger: TextTrigger): TextTrigger {
    trigger
}

public func triggerFn(trigger: Regex): TextTrigger {
    TextTrigger.regex(trigger)
}

public func triggerFn(triggers: Array<Regex>): TextTrigger {
    TextTrigger.regex(triggers)
}

private func validateCommandNames(commands: Array<String>): Unit {
    for (command in commands) {
        if (command.startsWith("/")) {
            throw Exception("Do not include '/' when registering command handlers (use '" + command[1..] + "' not '" + command + "')")
        }
    }
}

private func matchesFilterQuery(ctx: Context, query: String): Bool {
    if (query == ":text") {
        match (triggerMessage(ctx)) {
            case Some(message) => return !message.text.isEmpty()
            case None => return false
        }
    }
    if (query == ":caption") {
        match (triggerMessage(ctx)) {
            case Some(message) => return !message.caption.isEmpty()
            case None => return false
        }
    }
    if (query == ":entities:bot_command") {
        match (triggerMessage(ctx)) {
            case Some(message) => return hasBotCommandEntity(message)
            case None => return false
        }
    }
    if (query == "callback_query:data") {
        match (ctx.callbackQuery) {
            case Some(callbackQuery) => return !callbackQuery.data.isEmpty()
            case None => return false
        }
    }
    if (query == "callback_query:game_short_name") {
        match (ctx.callbackQuery) {
            case Some(callbackQuery) => return !callbackQuery.gameShortName.isEmpty()
            case None => return false
        }
    }
    if (query == "message_reaction") { return optionPresent(ctx.messageReaction) }
    if (query == "inline_query") { return optionPresent(ctx.inlineQuery) }
    if (query == "chosen_inline_result") { return optionPresent(ctx.chosenInlineResult) }
    if (query == "pre_checkout_query") { return optionPresent(ctx.preCheckoutQuery) }
    if (query == "shipping_query") { return optionPresent(ctx.shippingQuery) }
    if (query == "message") { return optionPresent(ctx.message) }
    if (query == "edited_message") { return optionPresent(ctx.editedMessage) }
    if (query == "channel_post") { return optionPresent(ctx.channelPost) }
    if (query == "edited_channel_post") { return optionPresent(ctx.editedChannelPost) }
    if (query == "business_connection") { return optionPresent(ctx.businessConnection) }
    if (query == "business_message") { return optionPresent(ctx.businessMessage) }
    if (query == "edited_business_message") { return optionPresent(ctx.editedBusinessMessage) }
    if (query == "deleted_business_messages") { return optionPresent(ctx.deletedBusinessMessages) }
    if (query == "message_reaction_count") { return optionPresent(ctx.messageReactionCount) }
    if (query == "poll") { return optionPresent(ctx.poll) }
    if (query == "poll_answer") { return optionPresent(ctx.pollAnswer) }
    if (query == "my_chat_member") { return optionPresent(ctx.myChatMember) }
    if (query == "chat_member") { return optionPresent(ctx.chatMember) }
    if (query == "managed_bot") { return optionPresent(ctx.managedBot) }
    if (query == "chat_join_request") { return optionPresent(ctx.chatJoinRequest) }
    if (query == "chat_boost") { return optionPresent(ctx.chatBoost) }
    if (query == "removed_chat_boost") { return optionPresent(ctx.removedChatBoost) }
    if (query == "purchased_paid_media") { return optionPresent(ctx.purchasedPaidMedia) }
    !query.isEmpty() && query == ctx.update.kind
}

private func matchesText(ctx: Context, trigger: TextTrigger): Bool {
    let message = triggerMessage(ctx)
    match (message) {
        case Some(value) => return matchAndStore(ctx, messageContent(value), trigger)
        case None => return false
    }
}

private func matchAndStore(ctx: Context, content: String, trigger: TextTrigger): Bool {
    match (trigger.matchResult(content)) {
        case Some(result) =>
            ctx.`match` = Some(result)
            return true
        case None => false
    }
}

private func firstRegexMatch(regex: Regex, content: String): Option<ContextMatch> {
    for (md in regex.findAll(content, group: true)) {
        let values = ArrayList<String>()
        values.add(md.matchString())
        var index: Int64 = 1
        while (index <= md.groupCount()) {
            values.add(md.matchString(index))
            index += 1
        }
        return Some(ContextMatch.regex(values.toArray()))
    }
    None<ContextMatch>
}

private func matchesCommand(ctx: Context, commands: Array<String>): Bool {
    let message = triggerMessage(ctx)
    match (message) {
        case Some(value) =>
            if (!hasBotCommandEntity(value)) { return false }
            let text = messageContent(value)
            for (entity in value.entities) {
                if (entity.kind != "bot_command" || entity.offset != 0 || entity.length <= 1 || entity.length > text.size) {
                    continue
                }
                let raw = text[1..entity.length]
                if (commandMatches(ctx, commands, raw)) {
                    ctx.`match` = Some(ContextMatch.string(text[entity.length..].trimAsciiStart()))
                    return true
                }
            }
            return false
        case None => return false
    }
}

private func commandMatches(ctx: Context, commands: Array<String>, raw: String): Bool {
    if (containsString(commands, raw)) {
        return true
    }
    let command = commandNameWithoutBot(raw)
    if (command == raw) {
        return containsString(commands, raw)
    }
    asciiEqualsIgnoreCase(commandTarget(raw), ctx.me.username) && containsString(commands, command)
}

private func commandNameWithoutBot(raw: String): String {
    match (raw.indexOf("@")) {
        case Some(index) => raw[0..index]
        case None => raw
    }
}

private func commandTarget(raw: String): String {
    match (raw.indexOf("@")) {
        case Some(index) => raw[index + 1..]
        case None => ""
    }
}

private func triggerMessage(ctx: Context): Option<Message> {
    match (ctx.message) { case Some(value) => return Some(value); case None => () }
    match (ctx.channelPost) { case Some(value) => return Some(value); case None => () }
    None<Message>
}

private func matchesReaction(ctx: Context, wanted: Array<ReactionType>): Bool {
    match (ctx.messageReaction) {
        case Some(messageReaction) =>
            for (reaction in messageReaction.newReaction) {
                if (reactionExists(messageReaction.oldReaction, reaction)) {
                    continue
                }
                for (candidate in wanted) {
                    if (sameReaction(reaction, candidate)) {
                        return true
                    }
                }
                if (reaction.kind != "emoji" && reaction.kind != "custom_emoji" && reaction.kind != "paid") {
                    return true
                }
            }
            return false
        case None => return false
    }
}

private func collectEntities(messageOption: Option<Message>, kinds: Array<String>): Array<MessageEntityText> {
    let result = ArrayList<MessageEntityText>()
    let message = match (messageOption) {
        case Some(value) => value
        case None => return result.toArray()
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

private func reactionSummary(updateOption: Option<MessageReactionUpdated>): ReactionSummary {
    let summary = ReactionSummary()
    let update = match (updateOption) {
        case Some(value) => value
        case None => return summary
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
        } else if (reaction.kind == "custom_emoji") {
            customEmoji.add(reaction.customEmojiId)
        } else if (reaction.kind == "paid") {
            summary.paid = true
            summary.paidAdded = true
        }
    }
    for (reaction in update.oldReaction) {
        if (reaction.kind == "emoji") {
            emojiRemoved.add(reaction.emoji)
        } else if (reaction.kind == "custom_emoji") {
            customEmojiRemoved.add(reaction.customEmojiId)
        } else if (reaction.kind == "paid") {
            summary.paidAdded = false
        }
    }
    for (value in emoji) {
        emojiAdded.add(value)
    }
    for (value in customEmoji) {
        customEmojiAdded.add(value)
    }
    moveCommonStrings(emojiRemoved, emojiAdded, emojiKept)
    moveCommonStrings(customEmojiRemoved, customEmojiAdded, customEmojiKept)
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

private func moveCommonStrings(removed: ArrayList<String>, added: ArrayList<String>, kept: ArrayList<String>): Unit {
    var i: Int64 = 0
    while (i < removed.size) {
        if (added.size == 0) {
            return
        }
        let rem = removed[i]
        var found = false
        var j: Int64 = 0
        while (j < added.size) {
            if (rem == added[j]) {
                kept.add(rem)
                removed.remove(at: i)
                added.remove(at: j)
                found = true
                break
            }
            j += 1
        }
        if (!found) {
            i += 1
        }
    }
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

private func intArrayJson(values: Array<Int64>): String {
    var body = "["
    var first = true
    for (value in values) {
        if (!first) {
            body += ","
        }
        body += value.toString()
        first = false
    }
    body + "]"
}

private func reactionArrayJson(values: Array<ReactionType>): String {
    var body = "["
    var first = true
    for (value in values) {
        if (!first) {
            body += ","
        }
        body += reactionJson(value)
        first = false
    }
    body + "]"
}

private func reactionJson(value: ReactionType): String {
    if (value.kind == "emoji") {
        return "{\"type\":\"emoji\",\"emoji\":\"" + value.emoji + "\"}"
    }
    if (value.kind == "custom_emoji") {
        return "{\"type\":\"custom_emoji\",\"custom_emoji_id\":\"" + value.customEmojiId + "\"}"
    }
    if (value.kind == "paid") {
        return "{\"type\":\"paid\"}"
    }
    "{\"type\":\"" + value.kind + "\"}"
}

private func asciiEqualsIgnoreCase(left: String, right: String): Bool {
    if (left.size != right.size) {
        return false
    }
    var index: Int64 = 0
    while (index < left.size) {
        if (asciiLowerChar(left[index..index + 1]) != asciiLowerChar(right[index..index + 1])) {
            return false
        }
        index += 1
    }
    true
}

private func asciiLowerChar(value: String): String {
    if (value == "A") { return "a" }
    if (value == "B") { return "b" }
    if (value == "C") { return "c" }
    if (value == "D") { return "d" }
    if (value == "E") { return "e" }
    if (value == "F") { return "f" }
    if (value == "G") { return "g" }
    if (value == "H") { return "h" }
    if (value == "I") { return "i" }
    if (value == "J") { return "j" }
    if (value == "K") { return "k" }
    if (value == "L") { return "l" }
    if (value == "M") { return "m" }
    if (value == "N") { return "n" }
    if (value == "O") { return "o" }
    if (value == "P") { return "p" }
    if (value == "Q") { return "q" }
    if (value == "R") { return "r" }
    if (value == "S") { return "s" }
    if (value == "T") { return "t" }
    if (value == "U") { return "u" }
    if (value == "V") { return "v" }
    if (value == "W") { return "w" }
    if (value == "X") { return "x" }
    if (value == "Y") { return "y" }
    if (value == "Z") { return "z" }
    value
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
