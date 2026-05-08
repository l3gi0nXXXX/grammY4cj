package grammy4cj.types

import std.collection.ArrayList

public class ResponseParameters {
    public let migrateToChatId: Int64
    public let retryAfter: Int64

    public init() {
        this.migrateToChatId = 0
        this.retryAfter = 0
    }

    public init(migrateToChatId: Int64, retryAfter: Int64) {
        this.migrateToChatId = migrateToChatId
        this.retryAfter = retryAfter
    }
}

public class ApiError {
    public let errorCode: Int64
    public let description: String
    public let parameters: ResponseParameters

    public init(errorCode: Int64, description: String, parameters: ResponseParameters) {
        this.errorCode = errorCode
        this.description = description
        this.parameters = parameters
    }
}

public class ApiResponse {
    public let ok: Bool
    public let result: String
    public let error: ApiError

    public init(ok: Bool, result: String, error: ApiError) {
        this.ok = ok
        this.result = result
        this.error = error
    }

    public static func success(result: String): ApiResponse {
        ApiResponse(true, result, ApiError(0, "", ResponseParameters()))
    }

    public static func failure(errorCode: Int64, description: String, parameters: ResponseParameters): ApiResponse {
        ApiResponse(false, "", ApiError(errorCode, description, parameters))
    }
}

public class TelegramTypeAliasTrace {
    public let aliasName: String
    public let upstreamGeneric: String
    public let inputFileBinding: String
    public let exportedFromDeno: Bool
    public let exportedFromNode: Bool
    public let exportedFromWeb: Bool

    public init(aliasName: String, upstreamGeneric: String, inputFileBinding: String) {
        this.aliasName = aliasName
        this.upstreamGeneric = upstreamGeneric
        this.inputFileBinding = inputFileBinding
        this.exportedFromDeno = true
        this.exportedFromNode = true
        this.exportedFromWeb = true
    }
}

public class TypeSourceMatrixRow {
    public let upstreamFile: String
    public let cangjieFiles: String
    public let facade: String
    public let inputFileSourceApi: String
    public let coversApiMethods: Bool
    public let coversOpts: Bool
    public let coversInputFileGenericAliases: Bool
    public let coversTelegramObjectSubset: Bool

    public init(
        upstreamFile: String,
        cangjieFiles: String,
        facade: String,
        inputFileSourceApi: String,
        coversApiMethods: Bool,
        coversOpts: Bool,
        coversInputFileGenericAliases: Bool,
        coversTelegramObjectSubset: Bool
    ) {
        this.upstreamFile = upstreamFile
        this.cangjieFiles = cangjieFiles
        this.facade = facade
        this.inputFileSourceApi = inputFileSourceApi
        this.coversApiMethods = coversApiMethods
        this.coversOpts = coversOpts
        this.coversInputFileGenericAliases = coversInputFileGenericAliases
        this.coversTelegramObjectSubset = coversTelegramObjectSubset
    }
}

public class TelegramObjectSubsetTrace {
    public let objectName: String
    public let upstreamObject: String
    public let cangjieType: String
    public let requiredForGate: String
    public let historicalOnly: Bool

    public init(objectName: String, upstreamObject: String, cangjieType: String, requiredForGate: String) {
        this.objectName = objectName
        this.upstreamObject = upstreamObject
        this.cangjieType = cangjieType
        this.requiredForGate = requiredForGate
        this.historicalOnly = true
    }
}

public func typeSourceMatrix(): Array<TypeSourceMatrixRow> {
    [
        TypeSourceMatrixRow(
            "src/types.ts",
            "src/types/telegram_types.cj src/types/input_file.cj",
            "root re-export facade",
            "deno facade selected by upstream types.ts",
            true,
            true,
            true,
            true
        ),
        TypeSourceMatrixRow(
            "src/types.deno.ts",
            "src/types/telegram_types.cj src/types/input_file.cj",
            "Deno type facade",
            "path,url,url_like,bytes,blob,response,stream,iterable,async_iterable,supplier",
            true,
            true,
            true,
            true
        ),
        TypeSourceMatrixRow(
            "src/types.node.ts",
            "src/types/telegram_types.cj src/types/input_file.cj",
            "Node type facade",
            "path,url,url_like,bytes,stream,iterable,async_iterable,supplier",
            true,
            true,
            true,
            true
        ),
        TypeSourceMatrixRow(
            "src/types.web.ts",
            "src/types/telegram_types.cj src/types/input_file.cj",
            "Web type facade",
            "url,url_like,bytes,blob,stream,iterable,async_iterable",
            true,
            true,
            true,
            true
        )
    ]
}

public func typeSourceMatrixCount(): Int64 {
    4
}

public func typeSourceMatrixFor(upstreamFile: String): TypeSourceMatrixRow {
    for (row in typeSourceMatrix()) {
        if (row.upstreamFile == upstreamFile) {
            return row
        }
    }
    TypeSourceMatrixRow(upstreamFile, "", "", "", false, false, false, false)
}

public func telegramInputFileAliasTrace(): Array<TelegramTypeAliasTrace> {
    [
        TelegramTypeAliasTrace("ApiMethods", "ApiMethodsF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("Opts", "OptsF<InputFile>[M]", "InputFile"),
        TelegramTypeAliasTrace("InputSticker", "InputStickerF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputMedia", "InputMediaF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputMediaPhoto", "InputMediaPhotoF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputMediaVideo", "InputMediaVideoF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputMediaAnimation", "InputMediaAnimationF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputMediaAudio", "InputMediaAudioF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputMediaDocument", "InputMediaDocumentF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputPaidMedia", "InputPaidMediaF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputPaidMediaPhoto", "InputPaidMediaPhotoF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputPaidMediaVideo", "InputPaidMediaVideoF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputProfilePhoto", "InputProfilePhotoF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputProfilePhotoStatic", "InputProfilePhotoStaticF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputProfilePhotoAnimated", "InputProfilePhotoAnimatedF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputStoryContent", "InputStoryContentF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputStoryContentPhoto", "InputStoryContentPhotoF<InputFile>", "InputFile"),
        TelegramTypeAliasTrace("InputStoryContentVideo", "InputStoryContentVideoF<InputFile>", "InputFile")
    ]
}

public func telegramInputFileAliasTraceCount(): Int64 {
    18
}

public func telegramObjectSubsetTrace(): Array<TelegramObjectSubsetTrace> {
    [
        TelegramObjectSubsetTrace("ResponseParameters", "ResponseParameters", "ResponseParameters", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("ApiError", "ApiResponse error object", "ApiError", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("ApiResponse", "ApiResponse", "ApiResponse", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("User", "User", "User", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("UserFromGetMe", "UserFromGetMe", "UserFromGetMe", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("Chat", "Chat", "Chat", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("MessageEntity", "MessageEntity", "MessageEntity", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("Message", "Message", "Message", "historical fixture; complete type manifest is the gate"),
        TelegramObjectSubsetTrace("Update", "Update", "Update", "historical fixture; complete type manifest is the gate")
    ]
}

public func telegramObjectSubsetTraceCount(): Int64 {
    9
}

public class User {
    public var id: Int64 = 0
    public var isBot: Bool = false
    public var firstName: String = ""
    public var username: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(id: Int64, isBot: Bool, firstName: String, username: String) {
        this.id = id
        this.isBot = isBot
        this.firstName = firstName
        this.username = username
        this.isPresent = true
    }
}

public class UserFromGetMe {
    public let id: Int64
    public let isBot: Bool
    public let firstName: String
    public let username: String

    public init(id: Int64, isBot: Bool, firstName: String, username: String) {
        this.id = id
        this.isBot = isBot
        this.firstName = firstName
        this.username = username
    }
}

public class Chat {
    public var id: Int64 = 0
    public var kind: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(id: Int64, kind: String) {
        this.id = id
        this.kind = kind
        this.isPresent = true
    }
}

public class MessageEntity {
    public var kind: String = ""
    public var offset: Int64 = 0
    public var length: Int64 = 0

    public init() {}

    public init(kind: String, offset: Int64, length: Int64) {
        this.kind = kind
        this.offset = offset
        this.length = length
    }
}

public class MessageEntityText {
    public let entity: MessageEntity
    public let text: String

    public init(entity: MessageEntity, text: String) {
        this.entity = entity
        this.text = text
    }
}

public class Message {
    public var messageId: Int64 = 0
    public var chat: Chat = Chat()
    public var text: String = ""
    public var caption: String = ""
    public var textPresent: Bool = false
    public var captionPresent: Bool = false
    public var user: User = User()
    public var senderChat: Chat = Chat()
    public var entities: ArrayList<MessageEntity> = ArrayList<MessageEntity>()
    public var captionEntities: ArrayList<MessageEntity> = ArrayList<MessageEntity>()
    public var businessConnectionId: String = ""
    public var isTopicMessage: Bool = false
    public var messageThreadId: Int64 = 0
    public var directMessagesTopicId: Int64 = 0
    public var animation: Bool = false
    public var audio: Bool = false
    public var document: Bool = false
    public var paidMedia: Bool = false
    public var photo: Bool = false
    public var sticker: Bool = false
    public var story: Bool = false
    public var video: Bool = false
    public var videoNote: Bool = false
    public var voice: Bool = false
    public var contact: Bool = false
    public var dice: Bool = false
    public var game: Bool = false
    public var poll: Bool = false
    public var venue: Bool = false
    public var location: Bool = false
    public var forwardOriginType: String = ""
    public var stickerIsVideo: Bool = false
    public var stickerIsAnimated: Bool = false
    public var stickerPremiumAnimation: Bool = false
    public var giveawayOnlyNewMembers: Bool = false
    public var giveawayHasPublicWinners: Bool = false
    public var checklistOthersCanAddTasks: Bool = false
    public var checklistOthersCanMarkTasksAsDone: Bool = false
    public var linkPreviewUrl: String = ""
    public var objectFields: ArrayList<String> = ArrayList<String>()
    public var objectNestedFields: ArrayList<String> = ArrayList<String>()
    public var isPresent: Bool = false

    public init() {}

    public init(messageId: Int64, chat: Chat, text: String) {
        this.messageId = messageId
        this.chat = chat
        this.text = text
        this.textPresent = true
        this.addObjectField("text")
        this.isPresent = true
    }

    public init(messageId: Int64, chat: Chat, text: String, user: User) {
        this.messageId = messageId
        this.chat = chat
        this.text = text
        this.user = user
        this.textPresent = true
        this.addObjectField("text")
        this.isPresent = true
    }

    public func addObjectField(key: String): Message {
        if (!containsTelegramString(this.objectFields, key)) {
            this.objectFields.add(key)
        }
        this
    }

    public func addObjectNestedField(key: String, nestedKey: String): Message {
        this.addObjectField(key)
        let path = key + ":" + nestedKey
        if (!containsTelegramString(this.objectNestedFields, path)) {
            this.objectNestedFields.add(path)
        }
        this
    }

    public func addEntity(entity: MessageEntity): Message {
        this.addObjectField("entities")
        this.entities.add(entity)
        this
    }

    public func addCaptionEntity(entity: MessageEntity): Message {
        this.addObjectField("caption_entities")
        this.captionEntities.add(entity)
        this
    }
}

public class BusinessConnection {
    public var id: String = ""
    public var user: User = User()
    public var userChatId: Int64 = 0
    public var isPresent: Bool = false

    public init() {}

    public init(id: String, user: User, userChatId: Int64) {
        this.id = id
        this.user = user
        this.userChatId = userChatId
        this.isPresent = true
    }
}

public class BusinessMessagesDeleted {
    public var chat: Chat = Chat()
    public var businessConnectionId: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(chat: Chat, businessConnectionId: String) {
        this.chat = chat
        this.businessConnectionId = businessConnectionId
        this.isPresent = true
    }
}

public class ReactionType {
    public var kind: String = ""
    public var emoji: String = ""
    public var customEmojiId: String = ""

    public init() {}

    public init(kind: String, emoji: String, customEmojiId: String) {
        this.kind = kind
        this.emoji = emoji
        this.customEmojiId = customEmojiId
    }

    public static func emojiReaction(emoji: String): ReactionType {
        ReactionType("emoji", emoji, "")
    }

    public static func customEmojiReaction(customEmojiId: String): ReactionType {
        ReactionType("custom_emoji", "", customEmojiId)
    }

    public static func paidReaction(): ReactionType {
        ReactionType("paid", "", "")
    }
}

public class MessageReactionUpdated {
    public var chat: Chat = Chat()
    public var user: User = User()
    public var messageId: Int64 = 0
    public var oldReaction: Array<ReactionType> = []
    public var newReaction: Array<ReactionType> = []
    public var isPresent: Bool = false

    public init() {}

    public init(chat: Chat, user: User, messageId: Int64, oldReaction: Array<ReactionType>, newReaction: Array<ReactionType>) {
        this.chat = chat
        this.user = user
        this.messageId = messageId
        this.oldReaction = oldReaction
        this.newReaction = newReaction
        this.isPresent = true
    }
}

public class MessageReactionCountUpdated {
    public var chat: Chat = Chat()
    public var messageId: Int64 = 0
    public var reactions: Array<ReactionType> = []
    public var isPresent: Bool = false

    public init() {}

    public init(chat: Chat, messageId: Int64) {
        this.chat = chat
        this.messageId = messageId
        this.isPresent = true
    }

    public init(chat: Chat, messageId: Int64, reactions: Array<ReactionType>) {
        this.chat = chat
        this.messageId = messageId
        this.reactions = reactions
        this.isPresent = true
    }
}

public class InlineQuery {
    public var user: User = User()
    public var query: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(user: User, query: String) {
        this.user = user
        this.query = query
        this.isPresent = true
    }
}

public class ChosenInlineResult {
    public var user: User = User()
    public var resultId: String = ""
    public var inlineMessageId: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(user: User, resultId: String, inlineMessageId: String) {
        this.user = user
        this.resultId = resultId
        this.inlineMessageId = inlineMessageId
        this.isPresent = true
    }
}

public class CallbackQuery {
    public var user: User = User()
    public var data: String = ""
    public var gameShortName: String = ""
    public var message: Message = Message()
    public var inlineMessageId: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(user: User, data: String, message: Message) {
        this.user = user
        this.data = data
        this.message = message
        this.isPresent = true
    }

    public init(user: User, data: String, gameShortName: String, message: Message, inlineMessageId: String) {
        this.user = user
        this.data = data
        this.gameShortName = gameShortName
        this.message = message
        this.inlineMessageId = inlineMessageId
        this.isPresent = true
    }
}

public class ShippingQuery {
    public var user: User = User()
    public var invoicePayload: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(user: User, invoicePayload: String) {
        this.user = user
        this.invoicePayload = invoicePayload
        this.isPresent = true
    }
}

public class PreCheckoutQuery {
    public var user: User = User()
    public var invoicePayload: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(user: User, invoicePayload: String) {
        this.user = user
        this.invoicePayload = invoicePayload
        this.isPresent = true
    }
}

public class Poll {
    public var id: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(id: String) {
        this.id = id
        this.isPresent = true
    }
}

public class PollAnswer {
    public var user: User = User()
    public var pollId: String = ""
    public var isPresent: Bool = false

    public init() {}

    public init(user: User, pollId: String) {
        this.user = user
        this.pollId = pollId
        this.isPresent = true
    }
}

public class ChatMemberUpdated {
    public var chat: Chat = Chat()
    public var user: User = User()
    public var isPresent: Bool = false

    public init() {}

    public init(chat: Chat, user: User) {
        this.chat = chat
        this.user = user
        this.isPresent = true
    }
}

public class ManagedBotUpdate {
    public var user: User = User()
    public var isPresent: Bool = false

    public init() {}

    public init(user: User) {
        this.user = user
        this.isPresent = true
    }
}

public class ChatJoinRequest {
    public var chat: Chat = Chat()
    public var user: User = User()
    public var isPresent: Bool = false

    public init() {}

    public init(chat: Chat, user: User) {
        this.chat = chat
        this.user = user
        this.isPresent = true
    }
}

public class ChatBoostSource {
    public var user: User = User()

    public init() {}

    public init(user: User) {
        this.user = user
    }
}

public class ChatBoost {
    public var source: ChatBoostSource = ChatBoostSource()

    public init() {}

    public init(source: ChatBoostSource) {
        this.source = source
    }
}

public class ChatBoostUpdated {
    public var chat: Chat = Chat()
    public var boost: ChatBoost = ChatBoost()
    public var isPresent: Bool = false

    public init() {}

    public init(chat: Chat, boost: ChatBoost) {
        this.chat = chat
        this.boost = boost
        this.isPresent = true
    }
}

public class ChatBoostRemoved {
    public var chat: Chat = Chat()
    public var source: ChatBoostSource = ChatBoostSource()
    public var isPresent: Bool = false

    public init() {}

    public init(chat: Chat, source: ChatBoostSource) {
        this.chat = chat
        this.source = source
        this.isPresent = true
    }
}

public class PurchasedPaidMedia {
    public var user: User = User()
    public var isPresent: Bool = false

    public init() {}

    public init(user: User) {
        this.user = user
        this.isPresent = true
    }
}

public class ReactionSummary {
    public var emoji: Array<String> = []
    public var emojiAdded: Array<String> = []
    public var emojiKept: Array<String> = []
    public var emojiRemoved: Array<String> = []
    public var customEmoji: Array<String> = []
    public var customEmojiAdded: Array<String> = []
    public var customEmojiKept: Array<String> = []
    public var customEmojiRemoved: Array<String> = []
    public var paid: Bool = false
    public var paidAdded: Bool = false

    public init() {}
}

public class Update {
    public let updateId: Int64
    public let kind: String
    public var message: Message = Message()
    public var editedMessage: Message = Message()
    public var channelPost: Message = Message()
    public var editedChannelPost: Message = Message()
    public var businessConnection: BusinessConnection = BusinessConnection()
    public var businessMessage: Message = Message()
    public var editedBusinessMessage: Message = Message()
    public var deletedBusinessMessages: BusinessMessagesDeleted = BusinessMessagesDeleted()
    public var messageReaction: MessageReactionUpdated = MessageReactionUpdated()
    public var messageReactionCount: MessageReactionCountUpdated = MessageReactionCountUpdated()
    public var inlineQuery: InlineQuery = InlineQuery()
    public var chosenInlineResult: ChosenInlineResult = ChosenInlineResult()
    public var callbackQuery: CallbackQuery = CallbackQuery()
    public var shippingQuery: ShippingQuery = ShippingQuery()
    public var preCheckoutQuery: PreCheckoutQuery = PreCheckoutQuery()
    public var poll: Poll = Poll()
    public var pollAnswer: PollAnswer = PollAnswer()
    public var myChatMember: ChatMemberUpdated = ChatMemberUpdated()
    public var chatMember: ChatMemberUpdated = ChatMemberUpdated()
    public var managedBot: ManagedBotUpdate = ManagedBotUpdate()
    public var chatJoinRequest: ChatJoinRequest = ChatJoinRequest()
    public var chatBoost: ChatBoostUpdated = ChatBoostUpdated()
    public var removedChatBoost: ChatBoostRemoved = ChatBoostRemoved()
    public var purchasedPaidMedia: PurchasedPaidMedia = PurchasedPaidMedia()

    public init(updateId: Int64) {
        this.updateId = updateId
        this.kind = ""
    }

    public init(updateId: Int64, kind: String) {
        this.updateId = updateId
        this.kind = kind
    }

    public static func withMessage(updateId: Int64, message: Message): Update {
        let update = Update(updateId, "message")
        update.message = message
        return update
    }

    public static func withEditedMessage(updateId: Int64, message: Message): Update {
        let update = Update(updateId, "edited_message")
        update.editedMessage = message
        return update
    }

    public static func withChannelPost(updateId: Int64, message: Message): Update {
        let update = Update(updateId, "channel_post")
        update.channelPost = message
        return update
    }

    public static func withEditedChannelPost(updateId: Int64, message: Message): Update {
        let update = Update(updateId, "edited_channel_post")
        update.editedChannelPost = message
        return update
    }

    public static func withBusinessConnection(updateId: Int64, businessConnection: BusinessConnection): Update {
        let update = Update(updateId, "business_connection")
        update.businessConnection = businessConnection
        return update
    }

    public static func withBusinessMessage(updateId: Int64, message: Message): Update {
        let update = Update(updateId, "business_message")
        update.businessMessage = message
        return update
    }

    public static func withEditedBusinessMessage(updateId: Int64, message: Message): Update {
        let update = Update(updateId, "edited_business_message")
        update.editedBusinessMessage = message
        return update
    }

    public static func withDeletedBusinessMessages(updateId: Int64, deletedBusinessMessages: BusinessMessagesDeleted): Update {
        let update = Update(updateId, "deleted_business_messages")
        update.deletedBusinessMessages = deletedBusinessMessages
        return update
    }

    public static func withMessageReaction(updateId: Int64, messageReaction: MessageReactionUpdated): Update {
        let update = Update(updateId, "message_reaction")
        update.messageReaction = messageReaction
        return update
    }

    public static func withMessageReactionCount(updateId: Int64, messageReactionCount: MessageReactionCountUpdated): Update {
        let update = Update(updateId, "message_reaction_count")
        update.messageReactionCount = messageReactionCount
        return update
    }

    public static func withInlineQuery(updateId: Int64, inlineQuery: InlineQuery): Update {
        let update = Update(updateId, "inline_query")
        update.inlineQuery = inlineQuery
        return update
    }

    public static func withChosenInlineResult(updateId: Int64, chosenInlineResult: ChosenInlineResult): Update {
        let update = Update(updateId, "chosen_inline_result")
        update.chosenInlineResult = chosenInlineResult
        return update
    }

    public static func withCallbackQuery(updateId: Int64, callbackQuery: CallbackQuery): Update {
        let update = Update(updateId, "callback_query")
        update.callbackQuery = callbackQuery
        return update
    }

    public static func withShippingQuery(updateId: Int64, shippingQuery: ShippingQuery): Update {
        let update = Update(updateId, "shipping_query")
        update.shippingQuery = shippingQuery
        return update
    }

    public static func withPreCheckoutQuery(updateId: Int64, preCheckoutQuery: PreCheckoutQuery): Update {
        let update = Update(updateId, "pre_checkout_query")
        update.preCheckoutQuery = preCheckoutQuery
        return update
    }

    public static func withPoll(updateId: Int64, poll: Poll): Update {
        let update = Update(updateId, "poll")
        update.poll = poll
        return update
    }

    public static func withPollAnswer(updateId: Int64, pollAnswer: PollAnswer): Update {
        let update = Update(updateId, "poll_answer")
        update.pollAnswer = pollAnswer
        return update
    }

    public static func withMyChatMember(updateId: Int64, myChatMember: ChatMemberUpdated): Update {
        let update = Update(updateId, "my_chat_member")
        update.myChatMember = myChatMember
        return update
    }

    public static func withChatMember(updateId: Int64, chatMember: ChatMemberUpdated): Update {
        let update = Update(updateId, "chat_member")
        update.chatMember = chatMember
        return update
    }

    public static func withManagedBot(updateId: Int64, managedBot: ManagedBotUpdate): Update {
        let update = Update(updateId, "managed_bot")
        update.managedBot = managedBot
        return update
    }

    public static func withChatJoinRequest(updateId: Int64, chatJoinRequest: ChatJoinRequest): Update {
        let update = Update(updateId, "chat_join_request")
        update.chatJoinRequest = chatJoinRequest
        return update
    }

    public static func withChatBoost(updateId: Int64, chatBoost: ChatBoostUpdated): Update {
        let update = Update(updateId, "chat_boost")
        update.chatBoost = chatBoost
        return update
    }

    public static func withRemovedChatBoost(updateId: Int64, removedChatBoost: ChatBoostRemoved): Update {
        let update = Update(updateId, "removed_chat_boost")
        update.removedChatBoost = removedChatBoost
        return update
    }

    public static func withPurchasedPaidMedia(updateId: Int64, purchasedPaidMedia: PurchasedPaidMedia): Update {
        let update = Update(updateId, "purchased_paid_media")
        update.purchasedPaidMedia = purchasedPaidMedia
        return update
    }
}

private func containsTelegramString(values: ArrayList<String>, needle: String): Bool {
    for (value in values) {
        if (value == needle) {
            return true
        }
    }
    false
}
