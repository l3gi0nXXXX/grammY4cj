package grammy4cj.types

import std.collection.ArrayList

public class TelegramTypePackageBaseline {
    public let npmPackage: String
    public let denoPackage: String
    public let version: String
    public let denoSpecifier: String
    public let nodeSpecifier: String
    public let webSpecifier: String
    public let rootFacade: String

    public init(
        npmPackage: String,
        denoPackage: String,
        version: String,
        denoSpecifier: String,
        nodeSpecifier: String,
        webSpecifier: String,
        rootFacade: String
    ) {
        this.npmPackage = npmPackage
        this.denoPackage = denoPackage
        this.version = version
        this.denoSpecifier = denoSpecifier
        this.nodeSpecifier = nodeSpecifier
        this.webSpecifier = webSpecifier
        this.rootFacade = rootFacade
    }
}

public class TelegramTypeExportModule {
    public let moduleName: String
    public let declarationFile: String
    public let exportNames: String

    public init(moduleName: String, declarationFile: String, exportNames: String) {
        this.moduleName = moduleName
        this.declarationFile = declarationFile
        this.exportNames = exportNames
    }

    public func names(): Array<String> {
        if (this.exportNames.isEmpty()) {
            return []
        }
        this.exportNames.split("|")
    }

    public func exportCount(): Int64 {
        this.names().size
    }

    public func contains(name: String): Bool {
        for (exportName in this.names()) {
            if (exportName == name) {
                return true
            }
        }
        false
    }
}

public class TelegramTypeAliasModel {
    public let aliasName: String
    public let upstreamGeneric: String
    public let cangjieModel: String
    public let inputFileReplacementPoint: String
    public let constructible: Bool

    public init(aliasName: String, upstreamGeneric: String, cangjieModel: String, inputFileReplacementPoint: String, constructible: Bool) {
        this.aliasName = aliasName
        this.upstreamGeneric = upstreamGeneric
        this.cangjieModel = cangjieModel
        this.inputFileReplacementPoint = inputFileReplacementPoint
        this.constructible = constructible
    }
}

public class TelegramApiMethodModel {
    public let name: String
    public let hasPayload: Bool
    public let usesInputFile: Bool
    public let returnsArray: Bool

    public init(name: String, hasPayload: Bool, usesInputFile: Bool, returnsArray: Bool) {
        this.name = name
        this.hasPayload = hasPayload
        this.usesInputFile = usesInputFile
        this.returnsArray = returnsArray
    }
}

public class TelegramTypeFieldModel {
    public let objectName: String
    public let fieldName: String
    public let jsonKey: String
    public let required: Bool
    public let arrayDepth: String
    public let unionMembers: String
    public let inputFileReplacementPoint: String
    public let apiMethod: String

    public init(
        objectName: String,
        fieldName: String,
        jsonKey: String,
        required: Bool,
        arrayDepth: String,
        unionMembers: String,
        inputFileReplacementPoint: String,
        apiMethod: String
    ) {
        this.objectName = objectName
        this.fieldName = fieldName
        this.jsonKey = jsonKey
        this.required = required
        this.arrayDepth = arrayDepth
        this.unionMembers = unionMembers
        this.inputFileReplacementPoint = inputFileReplacementPoint
        this.apiMethod = apiMethod
    }

    public func optional(): Bool {
        !this.required
    }
}

public class TelegramTypeModelDescriptor {
    public let exportName: String
    public let moduleName: String
    public let declarationKind: String
    public let cangjieModel: String
    public let fieldSpec: String
    public let unionMembers: String
    public let inputFileReplacementPoint: String
    public let associatedApiMethods: String
    public let constructible: Bool
    public let generatedFromUpstream: Bool

    public init(
        exportName: String,
        moduleName: String,
        declarationKind: String,
        cangjieModel: String,
        fieldSpec: String,
        unionMembers: String,
        inputFileReplacementPoint: String,
        associatedApiMethods: String,
        constructible: Bool,
        generatedFromUpstream: Bool
    ) {
        this.exportName = exportName
        this.moduleName = moduleName
        this.declarationKind = declarationKind
        this.cangjieModel = cangjieModel
        this.fieldSpec = fieldSpec
        this.unionMembers = unionMembers
        this.inputFileReplacementPoint = inputFileReplacementPoint
        this.associatedApiMethods = associatedApiMethods
        this.constructible = constructible
        this.generatedFromUpstream = generatedFromUpstream
    }

    public func fieldCount(): Int64 {
        if (this.fieldSpec.isEmpty()) {
            return 0
        }
        this.fieldSpec.split(";").size
    }

    public func unionMemberCount(): Int64 {
        if (this.unionMembers.isEmpty()) {
            return 0
        }
        this.unionMembers.split("|").size
    }

    public func hasField(jsonKey: String): Bool {
        for (field in telegramTypeFieldManifestFor(this.exportName)) {
            if (field.jsonKey == jsonKey) {
                return true
            }
        }
        false
    }
}

public class TelegramTypeDryRunDiff {
    public let changeKind: String
    public let objectName: String
    public let memberName: String
    public let detail: String

    public init(changeKind: String, objectName: String, memberName: String, detail: String) {
        this.changeKind = changeKind
        this.objectName = objectName
        this.memberName = memberName
        this.detail = detail
    }
}

public class TelegramTypeExportIntegrityReport {
    public let expectedExportCount: Int64
    public let actualExportCount: Int64
    public let duplicateExportCount: Int64
    public let missingModelCount: Int64

    public init(expectedExportCount: Int64, actualExportCount: Int64, duplicateExportCount: Int64, missingModelCount: Int64) {
        this.expectedExportCount = expectedExportCount
        this.actualExportCount = actualExportCount
        this.duplicateExportCount = duplicateExportCount
        this.missingModelCount = missingModelCount
    }

    public func ok(): Bool {
        this.expectedExportCount == this.actualExportCount &&
            this.duplicateExportCount == 0 &&
            this.missingModelCount == 0
    }
}

public class TelegramTypeIRField {
    public let ownerTypeName: String
    public let fieldName: String
    public let jsonKey: String
    public let cangjieFieldName: String
    public let required: Bool
    public let arrayDepth: String
    public let inputFileReplacementPoint: String
    public let apiMethods: String

    public init(
        ownerTypeName: String,
        fieldName: String,
        jsonKey: String,
        cangjieFieldName: String,
        required: Bool,
        arrayDepth: String,
        inputFileReplacementPoint: String,
        apiMethods: String
    ) {
        this.ownerTypeName = ownerTypeName
        this.fieldName = fieldName
        this.jsonKey = jsonKey
        this.cangjieFieldName = cangjieFieldName
        this.required = required
        this.arrayDepth = arrayDepth
        this.inputFileReplacementPoint = inputFileReplacementPoint
        this.apiMethods = apiMethods
    }

    public func optional(): Bool {
        !this.required
    }

    public func usesInputFile(): Bool {
        !this.inputFileReplacementPoint.isEmpty()
    }
}

public class TelegramTypeIRNode {
    public let exportName: String
    public let moduleName: String
    public let declarationKind: String
    public let cangjieModel: String
    public let fields: Array<TelegramTypeIRField>
    public let unionMembers: Array<String>
    public let inputFileReplacementPoint: String
    public let associatedApiMethods: String
    public let generatedFromUpstream: Bool
    public let publicExport: Bool

    public init(
        exportName: String,
        moduleName: String,
        declarationKind: String,
        cangjieModel: String,
        fields: Array<TelegramTypeIRField>,
        unionMembers: Array<String>,
        inputFileReplacementPoint: String,
        associatedApiMethods: String,
        generatedFromUpstream: Bool,
        publicExport: Bool
    ) {
        this.exportName = exportName
        this.moduleName = moduleName
        this.declarationKind = declarationKind
        this.cangjieModel = cangjieModel
        this.fields = fields
        this.unionMembers = unionMembers
        this.inputFileReplacementPoint = inputFileReplacementPoint
        this.associatedApiMethods = associatedApiMethods
        this.generatedFromUpstream = generatedFromUpstream
        this.publicExport = publicExport
    }

    public func fieldCount(): Int64 {
        this.fields.size
    }

    public func unionMemberCount(): Int64 {
        this.unionMembers.size
    }

    public func hasField(jsonKey: String): Bool {
        for (field in this.fields) {
            if (field.jsonKey == jsonKey) {
                return true
            }
        }
        false
    }

    public func hasUnionMember(memberName: String): Bool {
        for (member in this.unionMembers) {
            if (member == memberName) {
                return true
            }
        }
        false
    }

    public func usedByApiMethod(methodName: String): Bool {
        ("," + this.associatedApiMethods + ",").contains("," + methodName + ",")
    }
}

public class TelegramTypeApiMapping {
    public let apiMethodName: String
    public let payloadTypeName: String
    public let resultTypeName: String
    public let usesInputFile: Bool
    public let hasPayload: Bool
    public let hasCangjieWrapper: Bool

    public init(
        apiMethodName: String,
        payloadTypeName: String,
        resultTypeName: String,
        usesInputFile: Bool,
        hasPayload: Bool,
        hasCangjieWrapper: Bool
    ) {
        this.apiMethodName = apiMethodName
        this.payloadTypeName = payloadTypeName
        this.resultTypeName = resultTypeName
        this.usesInputFile = usesInputFile
        this.hasPayload = hasPayload
        this.hasCangjieWrapper = hasCangjieWrapper
    }
}

public class TelegramTypeBuilderMapping {
    public let builderName: String
    public let methodName: String
    public let returnTypeName: String
    public let requiredFields: String
    public let optionalFields: String
    public let inputFileFields: String

    public init(
        builderName: String,
        methodName: String,
        returnTypeName: String,
        requiredFields: String,
        optionalFields: String,
        inputFileFields: String
    ) {
        this.builderName = builderName
        this.methodName = methodName
        this.returnTypeName = returnTypeName
        this.requiredFields = requiredFields
        this.optionalFields = optionalFields
        this.inputFileFields = inputFileFields
    }

    public func usesInputFile(): Bool {
        !this.inputFileFields.isEmpty()
    }
}

public class TelegramTypeContextMapping {
    public let updateFieldName: String
    public let contextPropertyName: String
    public let contextAccessorName: String
    public let resultTypeName: String
    public let required: Bool

    public init(
        updateFieldName: String,
        contextPropertyName: String,
        contextAccessorName: String,
        resultTypeName: String,
        required: Bool
    ) {
        this.updateFieldName = updateFieldName
        this.contextPropertyName = contextPropertyName
        this.contextAccessorName = contextAccessorName
        this.resultTypeName = resultTypeName
        this.required = required
    }

    public func optional(): Bool {
        !this.required
    }
}

public class TelegramTypeManifestSnapshot {
    public let version: String
    public let exportCount: Int64
    public let exportModuleCount: Int64
    public let apiMethodCount: Int64
    public let inputFileAliasCount: Int64
    public let irNodeCount: Int64
    public let apiMappingCount: Int64
    public let contextMappingCount: Int64
    public let rootFacade: String

    public init(
        version: String,
        exportCount: Int64,
        exportModuleCount: Int64,
        apiMethodCount: Int64,
        inputFileAliasCount: Int64,
        irNodeCount: Int64,
        apiMappingCount: Int64,
        contextMappingCount: Int64,
        rootFacade: String
    ) {
        this.version = version
        this.exportCount = exportCount
        this.exportModuleCount = exportModuleCount
        this.apiMethodCount = apiMethodCount
        this.inputFileAliasCount = inputFileAliasCount
        this.irNodeCount = irNodeCount
        this.apiMappingCount = apiMappingCount
        this.contextMappingCount = contextMappingCount
        this.rootFacade = rootFacade
    }
}

public class TelegramTypeDriftCheckReport {
    public let ok: Bool
    public let diffs: Array<TelegramTypeDryRunDiff>
    public let report: String

    public init(ok: Bool, diffs: Array<TelegramTypeDryRunDiff>, report: String) {
        this.ok = ok
        this.diffs = diffs
        this.report = report
    }

    public func diffCount(): Int64 {
        this.diffs.size
    }
}

public class TelegramTypeBus {
    public let irNodes: Array<TelegramTypeIRNode>
    public let apiMappings: Array<TelegramTypeApiMapping>
    public let contextMappings: Array<TelegramTypeContextMapping>
    public let integrity: TelegramTypeExportIntegrityReport

    public init(
        irNodes: Array<TelegramTypeIRNode>,
        apiMappings: Array<TelegramTypeApiMapping>,
        contextMappings: Array<TelegramTypeContextMapping>,
        integrity: TelegramTypeExportIntegrityReport
    ) {
        this.irNodes = irNodes
        this.apiMappings = apiMappings
        this.contextMappings = contextMappings
        this.integrity = integrity
    }

    public func complete(): Bool {
        this.integrity.ok() &&
            this.irNodes.size == 306 &&
            this.apiMappings.size == 180 &&
            this.contextMappings.size == 25
    }
}

public func telegramTypePackageBaseline(): TelegramTypePackageBaseline {
    TelegramTypePackageBaseline(
        "@grammyjs/types",
        "grammy_types",
        "3.26.0",
        "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
        "@grammyjs/types",
        "https://deno.land/x/grammy_types@v3.26.0/mod.ts",
        "./types.deno.ts"
    )
}

public func telegramTypeUpstreamSourceAnchors(): Array<String> {
    [
        "src/types.ts",
        "src/types.deno.ts",
        "src/types.node.ts",
        "src/types.web.ts",
        "package.json",
        "@grammyjs/types@3.26.0/api.d.ts",
        "@grammyjs/types@3.26.0/checklist.d.ts",
        "@grammyjs/types@3.26.0/inline.d.ts",
        "@grammyjs/types@3.26.0/langs.d.ts",
        "@grammyjs/types@3.26.0/manage.d.ts",
        "@grammyjs/types@3.26.0/markup.d.ts",
        "@grammyjs/types@3.26.0/message.d.ts",
        "@grammyjs/types@3.26.0/methods.d.ts",
        "@grammyjs/types@3.26.0/passport.d.ts",
        "@grammyjs/types@3.26.0/payment.d.ts",
        "@grammyjs/types@3.26.0/settings.d.ts",
        "@grammyjs/types@3.26.0/story.d.ts",
        "@grammyjs/types@3.26.0/update.d.ts",
        "test/types.test.ts"
    ]
}

public func telegramTypeFacadeDriftCheck(
    denoImportSpecifier: String,
    denoExportSpecifier: String,
    nodeImportSpecifier: String,
    nodeExportSpecifier: String,
    webImportSpecifier: String,
    webExportSpecifier: String,
    rootFacade: String
): Bool {
    let baseline = telegramTypePackageBaseline()
    denoImportSpecifier == baseline.denoSpecifier &&
        denoExportSpecifier == baseline.denoSpecifier &&
        nodeImportSpecifier == baseline.nodeSpecifier &&
        nodeExportSpecifier == baseline.nodeSpecifier &&
        webImportSpecifier == baseline.webSpecifier &&
        webExportSpecifier == baseline.webSpecifier &&
        rootFacade == baseline.rootFacade
}

public func telegramTypeExportModules(): Array<TelegramTypeExportModule> {
    [
        TelegramTypeExportModule("api", "api.d.ts", "ApiError|ApiSuccess|ApiResponse|ResponseParameters"),
        TelegramTypeExportModule("checklist", "checklist.d.ts", "ChecklistTask|Checklist|InputChecklistTask|InputChecklist|ChecklistTasksDone|ChecklistTasksAdded"),
        TelegramTypeExportModule("inline", "inline.d.ts", "InlineQuery|InlineQueryResult|InlineQueryResultArticle|InlineQueryResultPhoto|InlineQueryResultGif|InlineQueryResultMpeg4Gif|InlineQueryResultVideo|InlineQueryResultAudio|InlineQueryResultVoice|InlineQueryResultDocument|InlineQueryResultLocation|InlineQueryResultVenue|InlineQueryResultContact|InlineQueryResultGame|InlineQueryResultCachedPhoto|InlineQueryResultCachedGif|InlineQueryResultCachedMpeg4Gif|InlineQueryResultCachedSticker|InlineQueryResultCachedDocument|InlineQueryResultCachedVideo|InlineQueryResultCachedVoice|InlineQueryResultCachedAudio|InputMessageContent|InputTextMessageContent|InputLocationMessageContent|InputVenueMessageContent|InputContactMessageContent|InputInvoiceMessageContent|ChosenInlineResult|InlineQueryResultsButton"),
        TelegramTypeExportModule("langs", "langs.d.ts", "LanguageCode"),
        TelegramTypeExportModule("manage", "manage.d.ts", "WebhookInfo|AcceptedGiftTypes|User|UserFromGetMe|ManagedBotCreated|ManagedBotUpdated|ChatOwnerLeft|ChatOwnerChanged|UserRating|ChatNamespace|Chat|ChatFullInfoNamespace|ChatFullInfo|ChatFromGetChat|UserProfilePhotos|UserProfileAudios|ChatPhoto|ChatInviteLink|ChatAdministratorRights|ChatMemberUpdated|ChatMember|ChatMemberOwner|ChatMemberAdministrator|ChatMemberMember|ChatMemberRestricted|ChatMemberLeft|ChatMemberBanned|ChatJoinRequest|ChatPermissions|Birthdate|BusinessIntro|BusinessLocation|BusinessOpeningHoursInterval|BusinessOpeningHours|ChatLocation|ForumTopic|BotCommand|ChatBoostSource|ChatBoostSourcePremium|ChatBoostSourceGiftCode|ChatBoostSourceGiveaway|ChatBoost|ChatBoostUpdated|ChatBoostRemoved|UserChatBoosts|BusinessBotRights|BusinessConnection|BusinessMessagesDeleted"),
        TelegramTypeExportModule("markup", "markup.d.ts", "InlineKeyboardMarkup|InlineKeyboardButtonNamespace|InlineKeyboardButton|LoginUrl|SwitchInlineQueryChosenChat|CallbackGame|CallbackQuery|ReplyKeyboardMarkup|KeyboardButtonNamespace|KeyboardButton|KeyboardButtonPollType|KeyboardButtonRequestManagedBot|ReplyKeyboardRemove|ForceReply|CopyTextButton|WebAppInfo|KeyboardButtonRequestUsers|KeyboardButtonRequestChat|PreparedKeyboardButton"),
        TelegramTypeExportModule("message", "message.d.ts", "MessageNamespace|Message|MessageId|SentWebAppMessage|InaccessibleMessage|MaybeInaccessibleMessage|ParseMode|MessageEntityNamespace|MessageEntity|TextQuote|ExternalReplyInfo|ReplyParameters|MessageOrigin|MessageOriginUser|MessageOriginHiddenUser|MessageOriginChat|MessageOriginChannel|PhotoSize|Animation|Audio|Document|Story|Video|VideoQuality|VideoNote|Voice|Contact|Dice|PollOption|InputPollOption|PollAnswer|PollOptionAdded|PollOptionDeleted|Poll|Location|PaidMediaInfo|PaidMedia|PaidMediaPreview|PaidMediaPhoto|PaidMediaVideo|Venue|WebAppData|ProximityAlertTriggered|MessageAutoDeleteTimerChanged|ChatBoostAdded|BackgroundFill|BackgroundFillSolid|BackgroundFillGradient|BackgroundFillFreeformGradient|BackgroundType|BackgroundTypeFill|BackgroundTypeWallpaper|BackgroundTypePattern|BackgroundTypeChatTheme|ChatBackground|ForumTopicCreated|ForumTopicEdited|ForumTopicClosed|ForumTopicReopened|GeneralForumTopicHidden|GeneralForumTopicUnhidden|SharedUser|UsersShared|ChatShared|WriteAccessAllowed|DirectMessagePriceChanged|VideoChatScheduled|VideoChatStarted|VideoChatEnded|VideoChatParticipantsInvited|GiveawayCreated|Giveaway|GiveawayWinners|GiveawayCompleted|LinkPreviewOptions|Sticker|StickerSet|MaskPosition|Game|GameHighScore|File|ReactionType|ReactionTypeEmoji|ReactionTypeCustomEmoji|ReactionTypePaid|ReactionCount|MessageReactionUpdated|MessageReactionCountUpdated|PreparedInlineMessage|DirectMessagesTopic|SuggestedPostParameters"),
        TelegramTypeExportModule("methods", "methods.d.ts", "Opts|ApiMethods|InputSticker|InputMedia|InputMediaPhoto|InputMediaVideo|InputMediaAnimation|InputMediaAudio|InputMediaDocument|InputPaidMedia|InputPaidMediaPhoto|InputPaidMediaVideo|InputProfilePhoto|InputProfilePhotoStatic|InputProfilePhotoAnimated|InputStoryContent|InputStoryContentPhoto|InputStoryContentVideo"),
        TelegramTypeExportModule("passport", "passport.d.ts", "PassportData|PassportFile|EncryptedPassportElement|EncryptedCredentials|PassportElementError|PassportElementErrorDataField|PassportElementErrorFrontSide|PassportElementErrorReverseSide|PassportElementErrorSelfie|PassportElementErrorFile|PassportElementErrorFiles|PassportElementErrorTranslationFile|PassportElementErrorTranslationFiles|PassportElementErrorUnspecified"),
        TelegramTypeExportModule("payment", "payment.d.ts", "LabeledPrice|Invoice|ShippingAddress|OrderInfo|ShippingOption|SuccessfulPayment|RefundedPayment|ShippingQuery|PreCheckoutQuery|RevenueWithdrawalState|RevenueWithdrawalStatePending|RevenueWithdrawalStateSucceeded|RevenueWithdrawalStateFailed|AffiliateInfo|TransactionPartner|TransactionPartnerUser|TransactionPartnerChat|TransactionPartnerAffiliateProgram|TransactionPartnerFragment|TransactionPartnerTelegramAds|TransactionPartnerTelegramApi|TransactionPartnerOther|StarTransaction|StarTransactions|PaidMediaPurchased|GiftBackground|Gift|Gifts|UniqueGiftModel|UniqueGiftSymbol|UniqueGiftBackdropColors|UniqueGiftBackdrop|UniqueGift|UniqueGiftColors|GiftInfo|UniqueGiftInfo|PaidMessagePriceChanged|StarAmount|OwnedGift|OwnedGiftRegular|OwnedGiftUnique|OwnedGifts|SuggestedPostPrice|SuggestedPostInfo|SuggestedPostApproved|SuggestedPostApprovalFailed|SuggestedPostDeclined|SuggestedPostPaid|SuggestedPostRefunded"),
        TelegramTypeExportModule("settings", "settings.d.ts", "BotName|BotDescription|BotShortDescription|MenuButton|MenuButtonCommands|MenuButtonWebApp|MenuButtonDefault|BotCommandScope|BotCommandScopeDefault|BotCommandScopeAllPrivateChats|BotCommandScopeAllGroupChats|BotCommandScopeAllChatAdministrators|BotCommandScopeChat|BotCommandScopeChatAdministrators|BotCommandScopeChatMember"),
        TelegramTypeExportModule("story", "story.d.ts", "StoryAreaPosition|LocationAddress|StoryAreaType|StoryAreaTypeLocation|StoryAreaTypeSuggestedReaction|StoryAreaTypeLink|StoryAreaTypeWeather|StoryAreaTypeUniqueGift|StoryArea"),
        TelegramTypeExportModule("update", "update.d.ts", "UpdateNamespace|Update")
    ]
}

public func telegramTypeExportManifestCount(): Int64 {
    var total: Int64 = 0
    for (module in telegramTypeExportModules()) {
        total += module.exportCount()
    }
    total
}

public func telegramTypeExportModuleCount(): Int64 {
    telegramTypeExportModules().size
}

public func telegramTypeExportExists(name: String): Bool {
    for (module in telegramTypeExportModules()) {
        if (module.contains(name)) {
            return true
        }
    }
    false
}

public func telegramTypeExportModuleFor(name: String): String {
    for (module in telegramTypeExportModules()) {
        if (module.contains(name)) {
            return module.moduleName
        }
    }
    ""
}

public func telegramTypeExportNames(): Array<String> {
    let out = ArrayList<String>()
    for (module in telegramTypeExportModules()) {
        for (name in module.names()) {
            out.add(name)
        }
    }
    out.toArray()
}

public func telegramTypeExportIntegrityReport(): TelegramTypeExportIntegrityReport {
    let names = telegramTypeExportNames()
    var duplicates: Int64 = 0
    var missingModels: Int64 = 0
    var index: Int64 = 0
    for (name in names) {
        if (stringArrayContainsBefore(names, name, index)) {
            duplicates += 1
        }
        if (!telegramTypeModelDescriptorFor(name).constructible) {
            missingModels += 1
        }
        index += 1
    }
    TelegramTypeExportIntegrityReport(306, names.size, duplicates, missingModels)
}

public func telegramApiMethodNames(): Array<String> {
    [
        "getUpdates", "setWebhook", "deleteWebhook", "getWebhookInfo", "getMe", "logOut", "close", "sendMessage",
        "sendMessageDraft", "forwardMessage", "forwardMessages", "copyMessage", "copyMessages", "sendPhoto", "sendAudio",
        "sendDocument", "sendVideo", "sendAnimation", "sendVoice", "sendVideoNote", "sendMediaGroup", "sendLocation",
        "editMessageLiveLocation", "stopMessageLiveLocation", "sendPaidMedia", "sendVenue", "sendContact", "sendPoll",
        "sendChecklist", "editMessageChecklist", "sendDice", "sendChatAction", "setMessageReaction", "getUserProfilePhotos",
        "getUserProfileAudios", "setUserEmojiStatus", "getFile", "banChatMember", "unbanChatMember", "restrictChatMember",
        "promoteChatMember", "setChatAdministratorCustomTitle", "setChatMemberTag", "banChatSenderChat", "unbanChatSenderChat",
        "setChatPermissions", "exportChatInviteLink", "createChatInviteLink", "editChatInviteLink", "createChatSubscriptionInviteLink",
        "editChatSubscriptionInviteLink", "revokeChatInviteLink", "getManagedBotToken", "replaceManagedBotToken",
        "approveChatJoinRequest", "declineChatJoinRequest", "approveSuggestedPost", "declineSuggestedPost", "setChatPhoto",
        "deleteChatPhoto", "setChatTitle", "setChatDescription", "pinChatMessage", "unpinChatMessage", "unpinAllChatMessages",
        "leaveChat", "getChat", "getChatAdministrators", "getChatMemberCount", "getChatMember", "setChatStickerSet",
        "deleteChatStickerSet", "getForumTopicIconStickers", "createForumTopic", "editForumTopic", "closeForumTopic",
        "reopenForumTopic", "deleteForumTopic", "unpinAllForumTopicMessages", "editGeneralForumTopic", "closeGeneralForumTopic",
        "reopenGeneralForumTopic", "hideGeneralForumTopic", "unhideGeneralForumTopic", "unpinAllGeneralForumTopicMessages",
        "answerCallbackQuery", "getUserChatBoosts", "getUserGifts", "getChatGifts", "getBusinessConnection", "setMyCommands",
        "deleteMyCommands", "getMyCommands", "setMyName", "getMyName", "setMyDescription", "getMyDescription",
        "setMyShortDescription", "getMyShortDescription", "setMyProfilePhoto", "removeMyProfilePhoto", "setChatMenuButton",
        "getChatMenuButton", "setMyDefaultAdministratorRights", "getMyDefaultAdministratorRights", "getMyStarBalance",
        "editMessageText", "editMessageCaption", "editMessageMedia", "editMessageReplyMarkup", "stopPoll", "deleteMessage",
        "deleteMessages", "deleteBusinessMessages", "setBusinessAccountName", "setBusinessAccountUsername", "setBusinessAccountBio",
        "setBusinessAccountProfilePhoto", "removeBusinessAccountProfilePhoto", "setBusinessAccountGiftSettings",
        "getBusinessAccountStarBalance", "transferBusinessAccountStars", "getBusinessAccountGifts", "convertGiftToStars",
        "upgradeGift", "transferGift", "postStory", "repostStory", "editStory", "deleteStory", "sendSticker", "getStickerSet",
        "getCustomEmojiStickers", "uploadStickerFile", "createNewStickerSet", "addStickerToSet", "setStickerPositionInSet",
        "deleteStickerFromSet", "replaceStickerInSet", "setStickerEmojiList", "setStickerKeywords", "setStickerMaskPosition",
        "setStickerSetTitle", "deleteStickerSet", "setStickerSetThumbnail", "setCustomEmojiStickerSetThumbnail",
        "getAvailableGifts", "sendGift", "giftPremiumSubscription", "answerInlineQuery", "answerWebAppQuery",
        "savePreparedInlineMessage", "savePreparedKeyboardButton", "sendInvoice", "createInvoiceLink", "answerShippingQuery",
        "answerPreCheckoutQuery", "getStarTransactions", "refundStarPayment", "editUserStarSubscription", "verifyUser",
        "verifyChat", "removeUserVerification", "removeChatVerification", "readBusinessMessage", "setPassportDataErrors",
        "sendGame", "setGameScore", "getGameHighScores"
    ]
}

public func telegramApiMethodManifestCount(): Int64 {
    telegramApiMethodNames().size
}

public func telegramApiMethodExists(name: String): Bool {
    for (method in telegramApiMethodNames()) {
        if (method == name) {
            return true
        }
    }
    false
}

public func telegramApiMethodManifestFor(name: String): TelegramApiMethodModel {
    TelegramApiMethodModel(name, !zeroArgTelegramApiMethod(name), methodUsesInputFile(name), methodReturnsArray(name))
}

public func telegramInputFileBoundAliasManifest(): Array<TelegramTypeAliasModel> {
    [
        TelegramTypeAliasModel("ApiMethods", "ApiMethodsF<InputFile>", "ApiMethods", "all F payload positions", true),
        TelegramTypeAliasModel("Opts", "OptsF<InputFile>[M]", "Opts", "method payload by key", true),
        TelegramTypeAliasModel("InputSticker", "InputStickerF<InputFile>", "InputSticker", "sticker and thumbnail", true),
        TelegramTypeAliasModel("InputMedia", "InputMediaF<InputFile>", "InputMedia", "media and thumbnail", true),
        TelegramTypeAliasModel("InputMediaPhoto", "InputMediaPhotoF<InputFile>", "InputMediaPhoto", "media", true),
        TelegramTypeAliasModel("InputMediaVideo", "InputMediaVideoF<InputFile>", "InputMediaVideo", "media and thumbnail", true),
        TelegramTypeAliasModel("InputMediaAnimation", "InputMediaAnimationF<InputFile>", "InputMediaAnimation", "media and thumbnail", true),
        TelegramTypeAliasModel("InputMediaAudio", "InputMediaAudioF<InputFile>", "InputMediaAudio", "media and thumbnail", true),
        TelegramTypeAliasModel("InputMediaDocument", "InputMediaDocumentF<InputFile>", "InputMediaDocument", "media and thumbnail", true),
        TelegramTypeAliasModel("InputPaidMedia", "InputPaidMediaF<InputFile>", "InputPaidMedia", "media", true),
        TelegramTypeAliasModel("InputPaidMediaPhoto", "InputPaidMediaPhotoF<InputFile>", "InputPaidMediaPhoto", "media", true),
        TelegramTypeAliasModel("InputPaidMediaVideo", "InputPaidMediaVideoF<InputFile>", "InputPaidMediaVideo", "media and thumbnail", true),
        TelegramTypeAliasModel("InputProfilePhoto", "InputProfilePhotoF<InputFile>", "InputProfilePhoto", "photo", true),
        TelegramTypeAliasModel("InputProfilePhotoStatic", "InputProfilePhotoStaticF<InputFile>", "InputProfilePhotoStatic", "photo", true),
        TelegramTypeAliasModel("InputProfilePhotoAnimated", "InputProfilePhotoAnimatedF<InputFile>", "InputProfilePhotoAnimated", "animation", true),
        TelegramTypeAliasModel("InputStoryContent", "InputStoryContentF<InputFile>", "InputStoryContent", "photo or video", true),
        TelegramTypeAliasModel("InputStoryContentPhoto", "InputStoryContentPhotoF<InputFile>", "InputStoryContentPhoto", "photo", true),
        TelegramTypeAliasModel("InputStoryContentVideo", "InputStoryContentVideoF<InputFile>", "InputStoryContentVideo", "video", true)
    ]
}

public func telegramInputFileBoundAliasManifestCount(): Int64 {
    telegramInputFileBoundAliasManifest().size
}

public func telegramInputFileBoundAliasFor(name: String): TelegramTypeAliasModel {
    for (alias in telegramInputFileBoundAliasManifest()) {
        if (alias.aliasName == name) {
            return alias
        }
    }
    TelegramTypeAliasModel(name, "", "", "", false)
}

public func telegramTypeModelManifest(): Array<TelegramTypeModelDescriptor> {
    let out = ArrayList<TelegramTypeModelDescriptor>()
    for (module in telegramTypeExportModules()) {
        for (name in module.names()) {
            out.add(telegramTypeModelDescriptorForExport(module.moduleName, name))
        }
    }
    out.toArray()
}

public func telegramTypeModelManifestCount(): Int64 {
    telegramTypeModelManifest().size
}

public func telegramTypeModelDescriptorFor(name: String): TelegramTypeModelDescriptor {
    let moduleName = telegramTypeExportModuleFor(name)
    if (moduleName == "") {
        return TelegramTypeModelDescriptor(name, "", "missing", "", "", "", "", "", false, false)
    }
    telegramTypeModelDescriptorForExport(moduleName, name)
}

public func telegramTypeFieldManifestFor(name: String): Array<TelegramTypeFieldModel> {
    let descriptor = telegramTypeModelDescriptorFor(name)
    if (descriptor.fieldSpec.isEmpty()) {
        return []
    }
    let out = ArrayList<TelegramTypeFieldModel>()
    for (spec in descriptor.fieldSpec.split(";")) {
        let parts = spec.split(":")
        if (parts.size >= 3) {
            let api = if (parts.size >= 4) { parts[3] } else { descriptor.associatedApiMethods }
            out.add(TelegramTypeFieldModel(
                name,
                parts[0],
                parts[0],
                parts[1] == "req",
                parts[2],
                descriptor.unionMembers,
                descriptor.inputFileReplacementPoint,
                api
            ))
        }
    }
    out.toArray()
}

public func telegramTypeIRManifest(): Array<TelegramTypeIRNode> {
    let out = ArrayList<TelegramTypeIRNode>()
    for (descriptor in telegramTypeModelManifest()) {
        out.add(telegramTypeIRFromDescriptor(descriptor))
    }
    out.toArray()
}

public func telegramTypeIRManifestCount(): Int64 {
    telegramTypeIRManifest().size
}

public func telegramTypeIRFor(name: String): TelegramTypeIRNode {
    telegramTypeIRFromDescriptor(telegramTypeModelDescriptorFor(name))
}

public func telegramTypeIRCompletenessGate(): Bool {
    if (!telegramTypeExportIntegrityReport().ok()) {
        return false
    }
    if (telegramTypeIRManifestCount() != telegramTypeExportManifestCount()) {
        return false
    }
    for (node in telegramTypeIRManifest()) {
        if (!node.publicExport || !node.generatedFromUpstream) {
            return false
        }
    }
    true
}

public func telegramTypeModelExists(name: String): Bool {
    telegramTypeModelDescriptorFor(name).constructible
}

public func telegramTypeModelCompletenessGate(): Bool {
    if (!telegramTypeGateRequiresCompleteManifest()) {
        return false
    }
    if (telegramTypeModelManifestCount() != telegramTypeExportManifestCount()) {
        return false
    }
    for (entry in telegramTypeModelManifest()) {
        if (!entry.constructible || !entry.generatedFromUpstream) {
            return false
        }
    }
    true
}

public func telegramTypeModelCompletenessGateWithRemovedExport(removedExportName: String): Bool {
    var count: Int64 = 0
    for (entry in telegramTypeModelManifest()) {
        if (entry.exportName != removedExportName) {
            count += 1
        }
    }
    count == telegramTypeExportManifestCount()
}

public func telegramTypeFacadeAliasDriftCheck(aliasNames: Array<String>): Bool {
    if (aliasNames.size != telegramInputFileBoundAliasManifestCount()) {
        return false
    }
    for (alias in telegramInputFileBoundAliasManifest()) {
        var found = false
        for (name in aliasNames) {
            if (name == alias.aliasName) {
                found = true
            }
        }
        if (!found) {
            return false
        }
    }
    true
}

public func telegramTypeApiWrapperIntegrationNames(): Array<String> {
    [
        "getUpdates", "setWebhook", "deleteWebhook", "getWebhookInfo", "getMe", "logOut", "close", "sendMessage",
        "sendMessageDraft", "forwardMessage", "forwardMessages", "copyMessage", "copyMessages", "sendPhoto", "sendAudio",
        "sendDocument", "sendVideo", "sendAnimation", "sendVoice", "sendVideoNote", "sendMediaGroup", "sendLocation",
        "editMessageLiveLocation", "editMessageLiveLocationInline", "stopMessageLiveLocation", "stopMessageLiveLocationInline",
        "sendPaidMedia", "sendVenue", "sendContact", "sendPoll", "sendChecklist", "editMessageChecklist", "sendDice",
        "setMessageReaction", "sendChatAction", "getUserProfilePhotos", "getUserProfileAudios", "setUserEmojiStatus",
        "getUserChatBoosts", "getUserGifts", "getChatGifts", "getBusinessConnection", "getFile", "kickChatMember",
        "banChatMember", "unbanChatMember", "restrictChatMember", "promoteChatMember", "setChatAdministratorCustomTitle",
        "setChatMemberTag", "banChatSenderChat", "unbanChatSenderChat", "setChatPermissions", "exportChatInviteLink",
        "createChatInviteLink", "editChatInviteLink", "createChatSubscriptionInviteLink", "editChatSubscriptionInviteLink",
        "revokeChatInviteLink", "getManagedBotToken", "replaceManagedBotToken", "approveChatJoinRequest", "declineChatJoinRequest",
        "approveSuggestedPost", "declineSuggestedPost", "setChatPhoto", "deleteChatPhoto", "setChatTitle", "setChatDescription",
        "pinChatMessage", "unpinChatMessage", "unpinAllChatMessages", "leaveChat", "getChat", "getChatAdministrators",
        "getChatMembersCount", "getChatMemberCount", "getChatMember", "setChatStickerSet", "deleteChatStickerSet",
        "getForumTopicIconStickers", "createForumTopic", "editForumTopic", "closeForumTopic", "reopenForumTopic",
        "deleteForumTopic", "unpinAllForumTopicMessages", "editGeneralForumTopic", "closeGeneralForumTopic",
        "reopenGeneralForumTopic", "hideGeneralForumTopic", "unhideGeneralForumTopic", "unpinAllGeneralForumTopicMessages",
        "answerCallbackQuery", "setMyName", "getMyName", "setMyCommands", "deleteMyCommands", "getMyCommands",
        "setMyDescription", "getMyDescription", "setMyShortDescription", "getMyShortDescription", "setMyProfilePhoto",
        "removeMyProfilePhoto", "setChatMenuButton", "getChatMenuButton", "setMyDefaultAdministratorRights",
        "getMyDefaultAdministratorRights", "getMyStarBalance", "editMessageText", "editMessageTextInline",
        "editMessageCaption", "editMessageCaptionInline", "editMessageMedia", "editMessageMediaInline",
        "editMessageReplyMarkup", "editMessageReplyMarkupInline", "stopPoll", "deleteMessage", "deleteMessages",
        "deleteBusinessMessages", "setBusinessAccountName", "setBusinessAccountUsername", "setBusinessAccountBio",
        "setBusinessAccountProfilePhoto", "removeBusinessAccountProfilePhoto", "setBusinessAccountGiftSettings",
        "getBusinessAccountStarBalance", "transferBusinessAccountStars", "getBusinessAccountGifts", "convertGiftToStars",
        "upgradeGift", "transferGift", "postStory", "repostStory", "editStory", "deleteStory", "sendSticker",
        "getStickerSet", "getCustomEmojiStickers", "uploadStickerFile", "createNewStickerSet", "addStickerToSet",
        "setStickerPositionInSet", "deleteStickerFromSet", "replaceStickerInSet", "setStickerEmojiList",
        "setStickerKeywords", "setStickerMaskPosition", "setStickerSetTitle", "deleteStickerSet", "setStickerSetThumbnail",
        "setCustomEmojiStickerSetThumbnail", "getAvailableGifts", "sendGift", "giftPremiumSubscription", "sendGiftToChannel",
        "answerInlineQuery", "answerWebAppQuery", "savePreparedInlineMessage", "savePreparedKeyboardButton", "sendInvoice",
        "createInvoiceLink", "answerShippingQuery", "answerPreCheckoutQuery", "getStarTransactions", "refundStarPayment",
        "editUserStarSubscription", "verifyUser", "verifyChat", "removeUserVerification", "removeChatVerification",
        "readBusinessMessage", "setPassportDataErrors", "sendGame", "setGameScore", "setGameScoreInline",
        "getGameHighScores", "getGameHighScoresInline"
    ]
}

public func telegramTypeApiWrapperIntegrationCount(): Int64 {
    telegramTypeApiWrapperIntegrationNames().size
}

public func telegramTypeApiMappingManifest(): Array<TelegramTypeApiMapping> {
    let out = ArrayList<TelegramTypeApiMapping>()
    for (name in telegramTypeApiWrapperIntegrationNames()) {
        out.add(telegramTypeApiMappingFor(name))
    }
    out.toArray()
}

public func telegramTypeApiMappingCount(): Int64 {
    telegramTypeApiMappingManifest().size
}

public func telegramTypeApiMappingFor(methodName: String): TelegramTypeApiMapping {
    let apiModel = telegramApiMethodManifestFor(canonicalApiMethodName(methodName))
    TelegramTypeApiMapping(
        methodName,
        apiPayloadTypeName(methodName, apiModel.hasPayload),
        apiResultTypeName(methodName),
        apiModel.usesInputFile,
        apiModel.hasPayload,
        stringArrayContains(telegramTypeApiWrapperIntegrationNames(), methodName)
    )
}

public func telegramTypeBuilderMappingManifest(): Array<TelegramTypeBuilderMapping> {
    [
        TelegramTypeBuilderMapping("Keyboard", "textButton", "KeyboardButton.CommonButton", "text", "style|icon_custom_emoji_id", ""),
        TelegramTypeBuilderMapping("Keyboard", "requestContactButton", "KeyboardButton.RequestContactButton", "text|request_contact", "style|icon_custom_emoji_id", ""),
        TelegramTypeBuilderMapping("Keyboard", "webAppButton", "KeyboardButton.WebAppButton", "text|web_app", "style|icon_custom_emoji_id", ""),
        TelegramTypeBuilderMapping("InlineKeyboard", "urlButton", "InlineKeyboardButton.UrlButton", "text|url", "style|icon_custom_emoji_id", ""),
        TelegramTypeBuilderMapping("InlineKeyboard", "textButton", "InlineKeyboardButton.CallbackButton", "text|callback_data", "style|icon_custom_emoji_id", ""),
        TelegramTypeBuilderMapping("InlineKeyboard", "webAppButton", "InlineKeyboardButton.WebAppButton", "text|web_app", "style|icon_custom_emoji_id", ""),
        TelegramTypeBuilderMapping("InlineQueryResultBuilder", "article", "InlineQueryResultArticle", "type|id|title|input_message_content", "description|reply_markup|url|hide_url", ""),
        TelegramTypeBuilderMapping("InlineQueryResultBuilder", "audio", "InlineQueryResultAudio", "type|id|audio_url|title", "caption|parse_mode|reply_markup|input_message_content", ""),
        TelegramTypeBuilderMapping("InlineQueryResultBuilder", "photo", "InlineQueryResultPhoto", "type|id|photo_url|thumbnail_url", "caption|parse_mode|reply_markup|input_message_content", ""),
        TelegramTypeBuilderMapping("InlineQueryResultBuilder", "videoMp4", "InlineQueryResultVideo", "type|id|video_url|mime_type|thumbnail_url|title", "caption|parse_mode|reply_markup|input_message_content", ""),
        TelegramTypeBuilderMapping("InputMediaBuilder", "photo", "InputMediaPhoto", "type|media", "caption|parse_mode|caption_entities|show_caption_above_media|has_spoiler", "media"),
        TelegramTypeBuilderMapping("InputMediaBuilder", "video", "InputMediaVideo", "type|media", "caption|parse_mode|thumbnail|cover|start_timestamp|supports_streaming", "media|thumbnail|cover"),
        TelegramTypeBuilderMapping("InputMediaBuilder", "animation", "InputMediaAnimation", "type|media", "caption|parse_mode|thumbnail|show_caption_above_media|has_spoiler", "media|thumbnail"),
        TelegramTypeBuilderMapping("InputMediaBuilder", "audio", "InputMediaAudio", "type|media", "caption|parse_mode|thumbnail|performer|title", "media|thumbnail"),
        TelegramTypeBuilderMapping("InputMediaBuilder", "document", "InputMediaDocument", "type|media", "caption|parse_mode|thumbnail|disable_content_type_detection", "media|thumbnail")
    ]
}

public func telegramTypeBuilderMappingCount(): Int64 {
    telegramTypeBuilderMappingManifest().size
}

public func telegramTypeBuilderMappingFor(builderName: String, methodName: String): TelegramTypeBuilderMapping {
    for (mapping in telegramTypeBuilderMappingManifest()) {
        if (mapping.builderName == builderName && mapping.methodName == methodName) {
            return mapping
        }
    }
    TelegramTypeBuilderMapping(builderName, methodName, "", "", "", "")
}

public func telegramTypeDryRunImpactReport(diffs: Array<TelegramTypeDryRunDiff>): String {
    let base = telegramTypeDryRunReport(diffs)
    var report = base
    for (diff in diffs) {
        if (!report.isEmpty()) {
            report += "\n"
        }
        report += "impact:type." + diff.objectName
        let api = firstApiImpactForType(diff.objectName)
        if (!api.isEmpty()) {
            report += "\nimpact:api." + api
        }
        let builder = firstBuilderImpactForType(diff.objectName)
        if (!builder.isEmpty()) {
            report += "\nimpact:builder." + builder
        }
        let context = firstContextImpactForType(diff.objectName)
        if (!context.isEmpty()) {
            report += "\nimpact:context." + context
        }
    }
    report
}

public func telegramTypeContextGetterTrace(): Array<TelegramTypeFieldModel> {
    telegramTypeFieldManifestFor("Update")
}

public func telegramTypeContextGetterTraceCount(): Int64 {
    telegramTypeContextGetterTrace().size
}

public func telegramTypeContextMappingManifest(): Array<TelegramTypeContextMapping> {
    let out = ArrayList<TelegramTypeContextMapping>()
    for (field in telegramTypeFieldManifestFor("Update")) {
        out.add(TelegramTypeContextMapping(
            field.fieldName,
            contextPropertyNameForUpdateField(field.fieldName),
            contextAccessorNameForUpdateField(field.fieldName),
            contextTypeNameForUpdateField(field.fieldName),
            field.required
        ))
    }
    out.toArray()
}

public func telegramTypeContextMappingCount(): Int64 {
    telegramTypeContextMappingManifest().size
}

public func telegramTypeContextMappingFor(updateFieldName: String): TelegramTypeContextMapping {
    for (mapping in telegramTypeContextMappingManifest()) {
        if (mapping.updateFieldName == updateFieldName) {
            return mapping
        }
    }
    TelegramTypeContextMapping(updateFieldName, "", "", "", false)
}

public func telegramTypeDryRunDiff(
    oldFields: Array<TelegramTypeFieldModel>,
    newFields: Array<TelegramTypeFieldModel>,
    oldUnionMembers: String,
    newUnionMembers: String
): Array<TelegramTypeDryRunDiff> {
    let out = ArrayList<TelegramTypeDryRunDiff>()
    for (field in newFields) {
        if (!telegramTypeFieldArrayContains(oldFields, field.objectName, field.fieldName)) {
            out.add(TelegramTypeDryRunDiff("field_added", field.objectName, field.fieldName, "new upstream field"))
        }
    }
    for (field in oldFields) {
        if (!telegramTypeFieldArrayContains(newFields, field.objectName, field.fieldName)) {
            out.add(TelegramTypeDryRunDiff("field_removed", field.objectName, field.fieldName, "field missing from new upstream manifest"))
        }
    }
    for (member in splitMembers(newUnionMembers)) {
        if (!member.isEmpty() && !memberListContains(oldUnionMembers, member)) {
            out.add(TelegramTypeDryRunDiff("union_member_added", "union", member, "new upstream union member"))
        }
    }
    for (member in splitMembers(oldUnionMembers)) {
        if (!member.isEmpty() && !memberListContains(newUnionMembers, member)) {
            out.add(TelegramTypeDryRunDiff("union_member_removed", "union", member, "union member missing from new upstream manifest"))
        }
    }
    out.toArray()
}

public func telegramTypeDryRunReport(diffs: Array<TelegramTypeDryRunDiff>): String {
    var report = ""
    var first = true
    for (diff in diffs) {
        if (!first) {
            report += "\n"
        }
        report += diff.changeKind + ":" + diff.objectName + "." + diff.memberName + ":" + diff.detail
        first = false
    }
    report
}

public func telegramTypeExpectedManifestSnapshot(): TelegramTypeManifestSnapshot {
    let baseline = telegramTypePackageBaseline()
    TelegramTypeManifestSnapshot(
        baseline.version,
        306,
        13,
        169,
        18,
        306,
        180,
        25,
        baseline.rootFacade
    )
}

public func telegramTypeCurrentManifestSnapshot(): TelegramTypeManifestSnapshot {
    let baseline = telegramTypePackageBaseline()
    TelegramTypeManifestSnapshot(
        baseline.version,
        telegramTypeExportManifestCount(),
        telegramTypeExportModuleCount(),
        telegramApiMethodManifestCount(),
        telegramInputFileBoundAliasManifestCount(),
        telegramTypeIRManifestCount(),
        telegramTypeApiMappingCount(),
        telegramTypeContextMappingCount(),
        baseline.rootFacade
    )
}

public func telegramTypeSnapshotDriftCheck(actual: TelegramTypeManifestSnapshot): TelegramTypeDriftCheckReport {
    let expected = telegramTypeExpectedManifestSnapshot()
    let diffs = ArrayList<TelegramTypeDryRunDiff>()
    addStringDrift(diffs, "version", expected.version, actual.version)
    addCountDrift(diffs, "export_count", expected.exportCount, actual.exportCount)
    addCountDrift(diffs, "export_module_count", expected.exportModuleCount, actual.exportModuleCount)
    addCountDrift(diffs, "api_method_count", expected.apiMethodCount, actual.apiMethodCount)
    addCountDrift(diffs, "input_file_alias_count", expected.inputFileAliasCount, actual.inputFileAliasCount)
    addCountDrift(diffs, "ir_node_count", expected.irNodeCount, actual.irNodeCount)
    addCountDrift(diffs, "api_mapping_count", expected.apiMappingCount, actual.apiMappingCount)
    addCountDrift(diffs, "context_mapping_count", expected.contextMappingCount, actual.contextMappingCount)
    addStringDrift(diffs, "root_facade", expected.rootFacade, actual.rootFacade)
    let out = diffs.toArray()
    TelegramTypeDriftCheckReport(out.size == 0, out, telegramTypeDryRunReport(out))
}

public func telegramTypeBus(): TelegramTypeBus {
    TelegramTypeBus(
        telegramTypeIRManifest(),
        telegramTypeApiMappingManifest(),
        telegramTypeContextMappingManifest(),
        telegramTypeExportIntegrityReport()
    )
}

public func telegramTypeGateRequiresCompleteManifest(): Bool {
    telegramTypeExportManifestCount() == 306 &&
        telegramApiMethodManifestCount() == 169 &&
        telegramInputFileBoundAliasManifestCount() == 18 &&
        telegramTypeModelManifestCount() == 306 &&
        telegramTypeIRCompletenessGate() &&
        telegramTypeBus().complete() &&
        telegramTypeSnapshotDriftCheck(telegramTypeCurrentManifestSnapshot()).ok
}

public func telegramObjectSubsetTraceAcceptedAsGate(): Bool {
    false
}

private func zeroArgTelegramApiMethod(name: String): Bool {
    name == "getWebhookInfo" || name == "getMe" || name == "logOut" || name == "close" ||
        name == "getForumTopicIconStickers" || name == "removeMyProfilePhoto" ||
        name == "getMyStarBalance" || name == "getAvailableGifts"
}

private func methodReturnsArray(name: String): Bool {
    name == "getUpdates" || name == "forwardMessages" || name == "copyMessages" ||
        name == "sendMediaGroup" || name == "getChatAdministrators" ||
        name == "getForumTopicIconStickers" || name == "getMyCommands" ||
        name == "deleteMessages" || name == "getCustomEmojiStickers" ||
        name == "getGameHighScores"
}

private func methodUsesInputFile(name: String): Bool {
    name == "setWebhook" || name == "sendPhoto" || name == "sendAudio" ||
        name == "sendDocument" || name == "sendVideo" || name == "sendAnimation" ||
        name == "sendVoice" || name == "sendVideoNote" || name == "sendMediaGroup" ||
        name == "sendPaidMedia" || name == "sendChecklist" || name == "editMessageChecklist" ||
        name == "setChatPhoto" || name == "setMyProfilePhoto" || name == "editMessageMedia" ||
        name == "setBusinessAccountProfilePhoto" || name == "postStory" || name == "editStory" ||
        name == "sendSticker" || name == "uploadStickerFile" || name == "createNewStickerSet" ||
        name == "addStickerToSet" || name == "replaceStickerInSet" ||
        name == "setStickerSetThumbnail" || name == "answerInlineQuery" ||
        name == "savePreparedInlineMessage" || name == "savePreparedKeyboardButton" ||
        name == "sendInvoice" || name == "createInvoiceLink"
}

private func telegramTypeModelDescriptorForExport(moduleName: String, name: String): TelegramTypeModelDescriptor {
    let alias = telegramInputFileBoundAliasFor(name)
    let inputFilePoint = if (alias.constructible) { alias.inputFileReplacementPoint } else { inputFilePointForExport(name) }
    TelegramTypeModelDescriptor(
        name,
        moduleName,
        declarationKindForExport(name),
        cangjieModelForExport(name),
        fieldSpecForExport(name),
        unionMembersForExport(name),
        inputFilePoint,
        associatedApiMethodsForExport(name),
        true,
        true
    )
}

private func declarationKindForExport(name: String): String {
    if (name == "ApiMethods" || name == "Opts") {
        return "api-generic-alias"
    }
    if (name.contains("Namespace")) {
        return "namespace"
    }
    if (unionMembersForExport(name) != "") {
        return "union"
    }
    if (name == "LanguageCode" || name == "ParseMode" || name == "VideoQuality") {
        return "string-enum"
    }
    "object"
}

private func cangjieModelForExport(name: String): String {
    if (name == "ApiMethods") {
        return "ApiMethods<InputFile>"
    }
    if (name == "Opts") {
        return "Opts<M>"
    }
    name
}

private func fieldSpecForExport(name: String): String {
    if (name == "ResponseParameters") {
        return "migrate_to_chat_id:opt:0;retry_after:opt:0"
    }
    if (name == "ApiError") {
        return "ok:req:0;error_code:req:0;description:req:0;parameters:opt:0"
    }
    if (name == "ApiSuccess") {
        return "ok:req:0;result:req:0"
    }
    if (name == "User") {
        return "id:req:0;is_bot:req:0;first_name:req:0;last_name:opt:0;username:opt:0;language_code:opt:0;is_premium:opt:0;added_to_attachment_menu:opt:0"
    }
    if (name == "UserFromGetMe") {
        return "id:req:0;is_bot:req:0;first_name:req:0;last_name:opt:0;username:opt:0;can_join_groups:opt:0;can_read_all_group_messages:opt:0;supports_inline_queries:opt:0;can_connect_to_business:opt:0;has_main_web_app:opt:0"
    }
    if (name == "Chat") {
        return "id:req:0;type:req:0;title:opt:0;username:opt:0;first_name:opt:0;last_name:opt:0;is_forum:opt:0"
    }
    if (name == "MessageEntity") {
        return "type:req:0;offset:req:0;length:req:0;url:opt:0;user:opt:0;language:opt:0;custom_emoji_id:opt:0"
    }
    if (name == "Message") {
        return "message_id:req:0;message_thread_id:opt:0;from:opt:0;sender_chat:opt:0;date:req:0;business_connection_id:opt:0;chat:req:0;text:opt:0;entities:opt:1;caption:opt:0;caption_entities:opt:1;photo:opt:1;video:opt:0;document:opt:0;reply_markup:opt:0"
    }
    if (name == "Update") {
        return "update_id:req:0;message:opt:0;edited_message:opt:0;channel_post:opt:0;edited_channel_post:opt:0;business_connection:opt:0;business_message:opt:0;edited_business_message:opt:0;deleted_business_messages:opt:0;message_reaction:opt:0;message_reaction_count:opt:0;inline_query:opt:0;chosen_inline_result:opt:0;callback_query:opt:0;shipping_query:opt:0;pre_checkout_query:opt:0;poll:opt:0;poll_answer:opt:0;my_chat_member:opt:0;chat_member:opt:0;managed_bot:opt:0;chat_join_request:opt:0;chat_boost:opt:0;removed_chat_boost:opt:0;purchased_paid_media:opt:0"
    }
    if (name == "InputMediaPhoto") {
        return "type:req:0;media:req:0;caption:opt:0;parse_mode:opt:0;caption_entities:opt:1;show_caption_above_media:opt:0;has_spoiler:opt:0"
    }
    if (name == "InputMediaVideo") {
        return "type:req:0;media:req:0;thumbnail:opt:0;cover:opt:0;start_timestamp:opt:0;caption:opt:0;parse_mode:opt:0;caption_entities:opt:1;width:opt:0;height:opt:0;duration:opt:0;supports_streaming:opt:0;has_spoiler:opt:0"
    }
    if (name == "InputSticker") {
        return "sticker:req:0;format:req:0;emoji_list:req:1;mask_position:opt:0;keywords:opt:1"
    }
    if (name == "ApiMethods") {
        return "methods:req:1"
    }
    if (name == "Opts") {
        return "method_payload:req:0"
    }
    ""
}

private func unionMembersForExport(name: String): String {
    if (name == "ApiResponse") {
        return "ApiError|ApiSuccess"
    }
    if (name == "InputMedia") {
        return "InputMediaAnimation|InputMediaDocument|InputMediaAudio|InputMediaPhoto|InputMediaVideo"
    }
    if (name == "InputPaidMedia") {
        return "InputPaidMediaPhoto|InputPaidMediaVideo"
    }
    if (name == "InputProfilePhoto") {
        return "InputProfilePhotoStatic|InputProfilePhotoAnimated"
    }
    if (name == "InputStoryContent") {
        return "InputStoryContentPhoto|InputStoryContentVideo"
    }
    if (name == "ReactionType") {
        return "ReactionTypeEmoji|ReactionTypeCustomEmoji|ReactionTypePaid"
    }
    if (name == "PaidMedia") {
        return "PaidMediaPreview|PaidMediaPhoto|PaidMediaVideo"
    }
    ""
}

private func inputFilePointForExport(name: String): String {
    if (name == "InputMediaPhoto" || name == "InputPaidMediaPhoto" || name == "InputProfilePhotoStatic" || name == "InputStoryContentPhoto") {
        return "media/photo"
    }
    if (name == "InputMediaVideo" || name == "InputPaidMediaVideo" || name == "InputProfilePhotoAnimated" || name == "InputStoryContentVideo") {
        return "media/video thumbnail"
    }
    ""
}

private func associatedApiMethodsForExport(name: String): String {
    if (name == "Update") {
        return "getUpdates,setWebhook"
    }
    if (name == "Message") {
        return "sendMessage,sendPhoto,sendAudio,sendDocument,sendVideo,sendAnimation,sendVoice,sendVideoNote,sendMediaGroup,copyMessage,forwardMessage"
    }
    if (name == "UserFromGetMe") {
        return "getMe"
    }
    if (name == "InputMedia" || name == "InputMediaPhoto" || name == "InputMediaVideo" || name == "InputMediaAnimation" || name == "InputMediaAudio" || name == "InputMediaDocument") {
        return "sendMediaGroup,editMessageMedia"
    }
    if (name == "InputSticker") {
        return "createNewStickerSet,addStickerToSet,replaceStickerInSet"
    }
    if (name == "ApiMethods" || name == "Opts") {
        return "all ApiMethods payload positions"
    }
    ""
}

private func telegramTypeFieldArrayContains(fields: Array<TelegramTypeFieldModel>, objectName: String, fieldName: String): Bool {
    for (field in fields) {
        if (field.objectName == objectName && field.fieldName == fieldName) {
            return true
        }
    }
    false
}

private func splitMembers(members: String): Array<String> {
    if (members.isEmpty()) {
        return []
    }
    members.split("|")
}

private func memberListContains(members: String, member: String): Bool {
    for (existing in splitMembers(members)) {
        if (existing == member) {
            return true
        }
    }
    false
}

private func telegramTypeIRFromDescriptor(descriptor: TelegramTypeModelDescriptor): TelegramTypeIRNode {
    let fields = ArrayList<TelegramTypeIRField>()
    for (field in telegramTypeFieldManifestFor(descriptor.exportName)) {
        fields.add(TelegramTypeIRField(
            field.objectName,
            field.fieldName,
            field.jsonKey,
            cangjieFieldNameForJsonKey(field.jsonKey),
            field.required,
            field.arrayDepth,
            field.inputFileReplacementPoint,
            field.apiMethod
        ))
    }
    TelegramTypeIRNode(
        descriptor.exportName,
        descriptor.moduleName,
        descriptor.declarationKind,
        descriptor.cangjieModel,
        fields.toArray(),
        splitMembers(descriptor.unionMembers),
        descriptor.inputFileReplacementPoint,
        descriptor.associatedApiMethods,
        descriptor.generatedFromUpstream,
        telegramTypeExportExists(descriptor.exportName)
    )
}

private func stringArrayContains(values: Array<String>, target: String): Bool {
    for (value in values) {
        if (value == target) {
            return true
        }
    }
    false
}

private func stringArrayContainsBefore(values: Array<String>, target: String, beforeIndex: Int64): Bool {
    var index: Int64 = 0
    for (value in values) {
        if (index >= beforeIndex) {
            return false
        }
        if (value == target) {
            return true
        }
        index += 1
    }
    false
}

private func cangjieFieldNameForJsonKey(jsonKey: String): String {
    if (jsonKey == "update_id") { return "updateId" }
    if (jsonKey == "message_id") { return "messageId" }
    if (jsonKey == "message_thread_id") { return "messageThreadId" }
    if (jsonKey == "direct_messages_topic_id") { return "directMessagesTopicId" }
    if (jsonKey == "business_connection_id") { return "businessConnectionId" }
    if (jsonKey == "is_bot") { return "isBot" }
    if (jsonKey == "first_name") { return "firstName" }
    if (jsonKey == "last_name") { return "lastName" }
    if (jsonKey == "language_code") { return "languageCode" }
    if (jsonKey == "migrate_to_chat_id") { return "migrateToChatId" }
    if (jsonKey == "retry_after") { return "retryAfter" }
    if (jsonKey == "error_code") { return "errorCode" }
    if (jsonKey == "is_premium") { return "isPremium" }
    if (jsonKey == "added_to_attachment_menu") { return "addedToAttachmentMenu" }
    if (jsonKey == "can_join_groups") { return "canJoinGroups" }
    if (jsonKey == "can_read_all_group_messages") { return "canReadAllGroupMessages" }
    if (jsonKey == "supports_inline_queries") { return "supportsInlineQueries" }
    if (jsonKey == "can_connect_to_business") { return "canConnectToBusiness" }
    if (jsonKey == "has_main_web_app") { return "hasMainWebApp" }
    if (jsonKey == "sender_chat") { return "senderChat" }
    if (jsonKey == "caption_entities") { return "captionEntities" }
    if (jsonKey == "reply_markup") { return "replyMarkup" }
    if (jsonKey == "edited_message") { return "editedMessage" }
    if (jsonKey == "channel_post") { return "channelPost" }
    if (jsonKey == "edited_channel_post") { return "editedChannelPost" }
    if (jsonKey == "business_connection") { return "businessConnection" }
    if (jsonKey == "business_message") { return "businessMessage" }
    if (jsonKey == "edited_business_message") { return "editedBusinessMessage" }
    if (jsonKey == "deleted_business_messages") { return "deletedBusinessMessages" }
    if (jsonKey == "message_reaction") { return "messageReaction" }
    if (jsonKey == "message_reaction_count") { return "messageReactionCount" }
    if (jsonKey == "inline_query") { return "inlineQuery" }
    if (jsonKey == "chosen_inline_result") { return "chosenInlineResult" }
    if (jsonKey == "callback_query") { return "callbackQuery" }
    if (jsonKey == "shipping_query") { return "shippingQuery" }
    if (jsonKey == "pre_checkout_query") { return "preCheckoutQuery" }
    if (jsonKey == "poll_answer") { return "pollAnswer" }
    if (jsonKey == "my_chat_member") { return "myChatMember" }
    if (jsonKey == "chat_member") { return "chatMember" }
    if (jsonKey == "managed_bot") { return "managedBot" }
    if (jsonKey == "chat_join_request") { return "chatJoinRequest" }
    if (jsonKey == "chat_boost") { return "chatBoost" }
    if (jsonKey == "removed_chat_boost") { return "removedChatBoost" }
    if (jsonKey == "purchased_paid_media") { return "purchasedPaidMedia" }
    if (jsonKey == "parse_mode") { return "parseMode" }
    if (jsonKey == "caption_entities") { return "captionEntities" }
    if (jsonKey == "show_caption_above_media") { return "showCaptionAboveMedia" }
    if (jsonKey == "has_spoiler") { return "hasSpoiler" }
    if (jsonKey == "start_timestamp") { return "startTimestamp" }
    if (jsonKey == "supports_streaming") { return "supportsStreaming" }
    if (jsonKey == "emoji_list") { return "emojiList" }
    if (jsonKey == "mask_position") { return "maskPosition" }
    jsonKey
}

private func canonicalApiMethodName(methodName: String): String {
    if (methodName == "editMessageLiveLocationInline") { return "editMessageLiveLocation" }
    if (methodName == "stopMessageLiveLocationInline") { return "stopMessageLiveLocation" }
    if (methodName == "editMessageTextInline") { return "editMessageText" }
    if (methodName == "editMessageCaptionInline") { return "editMessageCaption" }
    if (methodName == "editMessageMediaInline") { return "editMessageMedia" }
    if (methodName == "editMessageReplyMarkupInline") { return "editMessageReplyMarkup" }
    if (methodName == "setGameScoreInline") { return "setGameScore" }
    if (methodName == "getGameHighScoresInline") { return "getGameHighScores" }
    if (methodName == "kickChatMember") { return "banChatMember" }
    if (methodName == "getChatMembersCount") { return "getChatMemberCount" }
    if (methodName == "sendGiftToChannel") { return "sendGift" }
    methodName
}

private func apiPayloadTypeName(methodName: String, hasPayload: Bool): String {
    if (!hasPayload) {
        return "{}"
    }
    "Opts<" + canonicalApiMethodName(methodName) + ">"
}

private func apiResultTypeName(methodName: String): String {
    let canonical = canonicalApiMethodName(methodName)
    if (canonical == "getUpdates") { return "Array<Update>" }
    if (canonical == "getMe") { return "UserFromGetMe" }
    if (canonical == "getWebhookInfo") { return "WebhookInfo" }
    if (canonical == "getFile") { return "File" }
    if (canonical == "getChat") { return "ChatFullInfo" }
    if (canonical == "getChatAdministrators") { return "Array<ChatMember>" }
    if (canonical == "getChatMember") { return "ChatMember" }
    if (canonical == "getChatMemberCount") { return "Int64" }
    if (canonical == "getMyCommands") { return "Array<BotCommand>" }
    if (canonical == "getCustomEmojiStickers") { return "Array<Sticker>" }
    if (canonical == "getAvailableGifts") { return "Gifts" }
    if (canonical == "getGameHighScores") { return "Array<GameHighScore>" }
    if (canonical == "getUserProfilePhotos") { return "UserProfilePhotos" }
    if (canonical == "getUserProfileAudios") { return "UserProfileAudios" }
    if (canonical == "copyMessage") { return "MessageId" }
    if (canonical == "copyMessages" || canonical == "forwardMessages") { return "Array<MessageId>" }
    if (canonical.startsWith("send") || canonical.startsWith("forward") || canonical.startsWith("editMessage")) {
        return "Message"
    }
    if (methodReturnsArray(canonical)) {
        return "Array<TelegramObject>"
    }
    if (
        canonical.startsWith("answer") || canonical.startsWith("set") ||
        canonical.startsWith("delete") || canonical.startsWith("remove") ||
        canonical.startsWith("ban") || canonical.startsWith("unban") ||
        canonical.startsWith("restrict") || canonical.startsWith("promote") ||
        canonical.startsWith("approve") || canonical.startsWith("decline") ||
        canonical.startsWith("close") || canonical.startsWith("reopen") ||
        canonical.startsWith("hide") || canonical.startsWith("unhide") ||
        canonical == "logOut" || canonical == "leaveChat" ||
        canonical == "pinChatMessage" || canonical == "unpinChatMessage" ||
        canonical == "unpinAllChatMessages" || canonical == "unpinAllForumTopicMessages" ||
        canonical == "unpinAllGeneralForumTopicMessages"
    ) {
        return "Bool"
    }
    "TelegramObject"
}

private func contextPropertyNameForUpdateField(fieldName: String): String {
    cangjieFieldNameForJsonKey(fieldName)
}

private func contextAccessorNameForUpdateField(fieldName: String): String {
    if (fieldName == "update_id") {
        return "updateId()"
    }
    contextPropertyNameForUpdateField(fieldName)
}

private func contextTypeNameForUpdateField(fieldName: String): String {
    if (fieldName == "update_id") { return "Int64" }
    if (fieldName == "message") { return "Message" }
    if (fieldName == "edited_message") { return "Message" }
    if (fieldName == "channel_post") { return "Message" }
    if (fieldName == "edited_channel_post") { return "Message" }
    if (fieldName == "business_connection") { return "BusinessConnection" }
    if (fieldName == "business_message") { return "Message" }
    if (fieldName == "edited_business_message") { return "Message" }
    if (fieldName == "deleted_business_messages") { return "BusinessMessagesDeleted" }
    if (fieldName == "message_reaction") { return "MessageReactionUpdated" }
    if (fieldName == "message_reaction_count") { return "MessageReactionCountUpdated" }
    if (fieldName == "inline_query") { return "InlineQuery" }
    if (fieldName == "chosen_inline_result") { return "ChosenInlineResult" }
    if (fieldName == "callback_query") { return "CallbackQuery" }
    if (fieldName == "shipping_query") { return "ShippingQuery" }
    if (fieldName == "pre_checkout_query") { return "PreCheckoutQuery" }
    if (fieldName == "poll") { return "Poll" }
    if (fieldName == "poll_answer") { return "PollAnswer" }
    if (fieldName == "my_chat_member") { return "ChatMemberUpdated" }
    if (fieldName == "chat_member") { return "ChatMemberUpdated" }
    if (fieldName == "managed_bot") { return "ManagedBotUpdate" }
    if (fieldName == "chat_join_request") { return "ChatJoinRequest" }
    if (fieldName == "chat_boost") { return "ChatBoostUpdated" }
    if (fieldName == "removed_chat_boost") { return "ChatBoostRemoved" }
    if (fieldName == "purchased_paid_media") { return "PurchasedPaidMedia" }
    ""
}

private func firstApiImpactForType(typeName: String): String {
    let descriptor = telegramTypeModelDescriptorFor(typeName)
    if (descriptor.associatedApiMethods.isEmpty()) {
        return ""
    }
    descriptor.associatedApiMethods.split(",")[0]
}

private func firstBuilderImpactForType(typeName: String): String {
    for (mapping in telegramTypeBuilderMappingManifest()) {
        if (mapping.returnTypeName == typeName || mapping.returnTypeName.endsWith("." + typeName)) {
            return mapping.builderName + "." + mapping.methodName
        }
    }
    ""
}

private func firstContextImpactForType(typeName: String): String {
    if (typeName == "Update") {
        return "updateId()"
    }
    for (mapping in telegramTypeContextMappingManifest()) {
        if (mapping.resultTypeName == typeName) {
            return mapping.contextAccessorName
        }
    }
    ""
}

private func addCountDrift(diffs: ArrayList<TelegramTypeDryRunDiff>, name: String, expected: Int64, actual: Int64): Unit {
    if (expected != actual) {
        diffs.add(TelegramTypeDryRunDiff(
            "count_changed",
            "telegram_types",
            name,
            "expected " + expected.toString() + " actual " + actual.toString()
        ))
    }
}

private func addStringDrift(diffs: ArrayList<TelegramTypeDryRunDiff>, name: String, expected: String, actual: String): Unit {
    if (expected != actual) {
        diffs.add(TelegramTypeDryRunDiff(
            "value_changed",
            "telegram_types",
            name,
            "expected " + expected + " actual " + actual
        ))
    }
}
