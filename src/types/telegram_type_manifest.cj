package grammy4cj.types

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

public func telegramTypeGateRequiresCompleteManifest(): Bool {
    telegramTypeExportManifestCount() == 306 &&
        telegramApiMethodManifestCount() == 169 &&
        telegramInputFileBoundAliasManifestCount() == 18
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
