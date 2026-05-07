package grammy4cj.core

public class ApiClientOptions {
    public let apiRoot: String
    public let environment: String
    public let timeoutSeconds: Int64
    public let sensitiveLogs: Bool
    public let canUseWebhookReply: Bool

    public init() {
        this.apiRoot = "https://api.telegram.org"
        this.environment = "prod"
        this.timeoutSeconds = 500
        this.sensitiveLogs = false
        this.canUseWebhookReply = false
    }

    public init(apiRoot: String, environment: String) {
        if (apiRoot.endsWith("/")) {
            throw Exception("apiRoot must not end with a slash.")
        }
        this.apiRoot = apiRoot
        this.environment = environment
        this.timeoutSeconds = 500
        this.sensitiveLogs = false
        this.canUseWebhookReply = false
    }

    public init(apiRoot: String, environment: String, timeoutSeconds: Int64, sensitiveLogs: Bool, canUseWebhookReply: Bool) {
        if (apiRoot.endsWith("/")) {
            throw Exception("apiRoot must not end with a slash.")
        }
        this.apiRoot = apiRoot
        this.environment = environment
        this.timeoutSeconds = timeoutSeconds
        this.sensitiveLogs = sensitiveLogs
        this.canUseWebhookReply = canUseWebhookReply
    }

    public func buildUrl(token: String, method: String): String {
        let prefix = if (this.environment == "test") {
            "test/"
        } else {
            ""
        }
        this.apiRoot + "/bot" + token + "/" + prefix + method
    }
}

public class Api {
    public let token: String
    public let config: ApiClientOptions

    public init(token: String) {
        this.token = token
        this.config = ApiClientOptions()
    }

    public init(token: String, config: ApiClientOptions) {
        this.token = token
        this.config = config
    }

    public func endpointFor(method: String): String {
        this.config.buildUrl(this.token, method)
    }

    public func call(method: String, payload: Payload): Payload {
        Payload("").addValue("__method", method).addValue("__payload", createJsonPayload(payload).body)
    }

    public func getUpdates(payload: Payload): Payload { this.call("getUpdates", payload) }
    public func setWebhook(payload: Payload): Payload { this.call("setWebhook", payload) }
    public func deleteWebhook(payload: Payload): Payload { this.call("deleteWebhook", payload) }
    public func getWebhookInfo(payload: Payload): Payload { this.call("getWebhookInfo", payload) }
    public func getMe(payload: Payload): Payload { this.call("getMe", payload) }
    public func logOut(payload: Payload): Payload { this.call("logOut", payload) }
    public func close(payload: Payload): Payload { this.call("close", payload) }
    public func sendMessage(payload: Payload): Payload { this.call("sendMessage", payload) }
    public func sendMessageDraft(payload: Payload): Payload { this.call("sendMessageDraft", payload) }
    public func forwardMessage(payload: Payload): Payload { this.call("forwardMessage", payload) }
    public func forwardMessages(payload: Payload): Payload { this.call("forwardMessages", payload) }
    public func copyMessage(payload: Payload): Payload { this.call("copyMessage", payload) }
    public func copyMessages(payload: Payload): Payload { this.call("copyMessages", payload) }
    public func sendPhoto(payload: Payload): Payload { this.call("sendPhoto", payload) }
    public func sendAudio(payload: Payload): Payload { this.call("sendAudio", payload) }
    public func sendDocument(payload: Payload): Payload { this.call("sendDocument", payload) }
    public func sendVideo(payload: Payload): Payload { this.call("sendVideo", payload) }
    public func sendAnimation(payload: Payload): Payload { this.call("sendAnimation", payload) }
    public func sendVoice(payload: Payload): Payload { this.call("sendVoice", payload) }
    public func sendVideoNote(payload: Payload): Payload { this.call("sendVideoNote", payload) }
    public func sendMediaGroup(payload: Payload): Payload { this.call("sendMediaGroup", payload) }
    public func sendLocation(payload: Payload): Payload { this.call("sendLocation", payload) }
    public func editMessageLiveLocation(payload: Payload): Payload { this.call("editMessageLiveLocation", payload) }
    public func editMessageLiveLocationInline(payload: Payload): Payload { this.call("editMessageLiveLocation", payload) }
    public func stopMessageLiveLocation(payload: Payload): Payload { this.call("stopMessageLiveLocation", payload) }
    public func stopMessageLiveLocationInline(payload: Payload): Payload { this.call("stopMessageLiveLocation", payload) }
    public func sendPaidMedia(payload: Payload): Payload { this.call("sendPaidMedia", payload) }
    public func sendVenue(payload: Payload): Payload { this.call("sendVenue", payload) }
    public func sendContact(payload: Payload): Payload { this.call("sendContact", payload) }
    public func sendPoll(payload: Payload): Payload { this.call("sendPoll", payload) }
    public func sendChecklist(payload: Payload): Payload { this.call("sendChecklist", payload) }
    public func editMessageChecklist(payload: Payload): Payload { this.call("editMessageChecklist", payload) }
    public func sendDice(payload: Payload): Payload { this.call("sendDice", payload) }
    public func setMessageReaction(payload: Payload): Payload { this.call("setMessageReaction", payload) }
    public func sendChatAction(payload: Payload): Payload { this.call("sendChatAction", payload) }
    public func getUserProfilePhotos(payload: Payload): Payload { this.call("getUserProfilePhotos", payload) }
    public func getUserProfileAudios(payload: Payload): Payload { this.call("getUserProfileAudios", payload) }
    public func setUserEmojiStatus(payload: Payload): Payload { this.call("setUserEmojiStatus", payload) }
    public func getUserChatBoosts(payload: Payload): Payload { this.call("getUserChatBoosts", payload) }
    public func getUserGifts(payload: Payload): Payload { this.call("getUserGifts", payload) }
    public func getChatGifts(payload: Payload): Payload { this.call("getChatGifts", payload) }
    public func getBusinessConnection(payload: Payload): Payload { this.call("getBusinessConnection", payload) }
    public func getFile(payload: Payload): Payload { this.call("getFile", payload) }
    public func kickChatMember(payload: Payload): Payload { this.call("banChatMember", payload) }
    public func banChatMember(payload: Payload): Payload { this.call("banChatMember", payload) }
    public func unbanChatMember(payload: Payload): Payload { this.call("unbanChatMember", payload) }
    public func restrictChatMember(payload: Payload): Payload { this.call("restrictChatMember", payload) }
    public func promoteChatMember(payload: Payload): Payload { this.call("promoteChatMember", payload) }
    public func setChatAdministratorCustomTitle(payload: Payload): Payload { this.call("setChatAdministratorCustomTitle", payload) }
    public func setChatMemberTag(payload: Payload): Payload { this.call("setChatMemberTag", payload) }
    public func banChatSenderChat(payload: Payload): Payload { this.call("banChatSenderChat", payload) }
    public func unbanChatSenderChat(payload: Payload): Payload { this.call("unbanChatSenderChat", payload) }
    public func setChatPermissions(payload: Payload): Payload { this.call("setChatPermissions", payload) }
    public func exportChatInviteLink(payload: Payload): Payload { this.call("exportChatInviteLink", payload) }
    public func createChatInviteLink(payload: Payload): Payload { this.call("createChatInviteLink", payload) }
    public func editChatInviteLink(payload: Payload): Payload { this.call("editChatInviteLink", payload) }
    public func createChatSubscriptionInviteLink(payload: Payload): Payload { this.call("createChatSubscriptionInviteLink", payload) }
    public func editChatSubscriptionInviteLink(payload: Payload): Payload { this.call("editChatSubscriptionInviteLink", payload) }
    public func revokeChatInviteLink(payload: Payload): Payload { this.call("revokeChatInviteLink", payload) }
    public func getManagedBotToken(payload: Payload): Payload { this.call("getManagedBotToken", payload) }
    public func replaceManagedBotToken(payload: Payload): Payload { this.call("replaceManagedBotToken", payload) }
    public func approveChatJoinRequest(payload: Payload): Payload { this.call("approveChatJoinRequest", payload) }
    public func declineChatJoinRequest(payload: Payload): Payload { this.call("declineChatJoinRequest", payload) }
    public func approveSuggestedPost(payload: Payload): Payload { this.call("approveSuggestedPost", payload) }
    public func declineSuggestedPost(payload: Payload): Payload { this.call("declineSuggestedPost", payload) }
    public func setChatPhoto(payload: Payload): Payload { this.call("setChatPhoto", payload) }
    public func deleteChatPhoto(payload: Payload): Payload { this.call("deleteChatPhoto", payload) }
    public func setChatTitle(payload: Payload): Payload { this.call("setChatTitle", payload) }
    public func setChatDescription(payload: Payload): Payload { this.call("setChatDescription", payload) }
    public func pinChatMessage(payload: Payload): Payload { this.call("pinChatMessage", payload) }
    public func unpinChatMessage(payload: Payload): Payload { this.call("unpinChatMessage", payload) }
    public func unpinAllChatMessages(payload: Payload): Payload { this.call("unpinAllChatMessages", payload) }
    public func leaveChat(payload: Payload): Payload { this.call("leaveChat", payload) }
    public func getChat(payload: Payload): Payload { this.call("getChat", payload) }
    public func getChatAdministrators(payload: Payload): Payload { this.call("getChatAdministrators", payload) }
    public func getChatMembersCount(payload: Payload): Payload { this.call("getChatMemberCount", payload) }
    public func getChatMemberCount(payload: Payload): Payload { this.call("getChatMemberCount", payload) }
    public func getChatMember(payload: Payload): Payload { this.call("getChatMember", payload) }
    public func setChatStickerSet(payload: Payload): Payload { this.call("setChatStickerSet", payload) }
    public func deleteChatStickerSet(payload: Payload): Payload { this.call("deleteChatStickerSet", payload) }
    public func getForumTopicIconStickers(payload: Payload): Payload { this.call("getForumTopicIconStickers", payload) }
    public func createForumTopic(payload: Payload): Payload { this.call("createForumTopic", payload) }
    public func editForumTopic(payload: Payload): Payload { this.call("editForumTopic", payload) }
    public func closeForumTopic(payload: Payload): Payload { this.call("closeForumTopic", payload) }
    public func reopenForumTopic(payload: Payload): Payload { this.call("reopenForumTopic", payload) }
    public func deleteForumTopic(payload: Payload): Payload { this.call("deleteForumTopic", payload) }
    public func unpinAllForumTopicMessages(payload: Payload): Payload { this.call("unpinAllForumTopicMessages", payload) }
    public func editGeneralForumTopic(payload: Payload): Payload { this.call("editGeneralForumTopic", payload) }
    public func closeGeneralForumTopic(payload: Payload): Payload { this.call("closeGeneralForumTopic", payload) }
    public func reopenGeneralForumTopic(payload: Payload): Payload { this.call("reopenGeneralForumTopic", payload) }
    public func hideGeneralForumTopic(payload: Payload): Payload { this.call("hideGeneralForumTopic", payload) }
    public func unhideGeneralForumTopic(payload: Payload): Payload { this.call("unhideGeneralForumTopic", payload) }
    public func unpinAllGeneralForumTopicMessages(payload: Payload): Payload { this.call("unpinAllGeneralForumTopicMessages", payload) }
    public func answerCallbackQuery(payload: Payload): Payload { this.call("answerCallbackQuery", payload) }
    public func setMyName(payload: Payload): Payload { this.call("setMyName", payload) }
    public func getMyName(payload: Payload): Payload { this.call("getMyName", payload) }
    public func setMyCommands(payload: Payload): Payload { this.call("setMyCommands", payload) }
    public func deleteMyCommands(payload: Payload): Payload { this.call("deleteMyCommands", payload) }
    public func getMyCommands(payload: Payload): Payload { this.call("getMyCommands", payload) }
    public func setMyDescription(payload: Payload): Payload { this.call("setMyDescription", payload) }
    public func getMyDescription(payload: Payload): Payload { this.call("getMyDescription", payload) }
    public func setMyShortDescription(payload: Payload): Payload { this.call("setMyShortDescription", payload) }
    public func getMyShortDescription(payload: Payload): Payload { this.call("getMyShortDescription", payload) }
    public func setMyProfilePhoto(payload: Payload): Payload { this.call("setMyProfilePhoto", payload) }
    public func removeMyProfilePhoto(payload: Payload): Payload { this.call("removeMyProfilePhoto", payload) }
    public func setChatMenuButton(payload: Payload): Payload { this.call("setChatMenuButton", payload) }
    public func getChatMenuButton(payload: Payload): Payload { this.call("getChatMenuButton", payload) }
    public func setMyDefaultAdministratorRights(payload: Payload): Payload { this.call("setMyDefaultAdministratorRights", payload) }
    public func getMyDefaultAdministratorRights(payload: Payload): Payload { this.call("getMyDefaultAdministratorRights", payload) }
    public func getMyStarBalance(payload: Payload): Payload { this.call("getMyStarBalance", payload) }
    public func editMessageText(payload: Payload): Payload { this.call("editMessageText", payload) }
    public func editMessageTextInline(payload: Payload): Payload { this.call("editMessageText", payload) }
    public func editMessageCaption(payload: Payload): Payload { this.call("editMessageCaption", payload) }
    public func editMessageCaptionInline(payload: Payload): Payload { this.call("editMessageCaption", payload) }
    public func editMessageMedia(payload: Payload): Payload { this.call("editMessageMedia", payload) }
    public func editMessageMediaInline(payload: Payload): Payload { this.call("editMessageMedia", payload) }
    public func editMessageReplyMarkup(payload: Payload): Payload { this.call("editMessageReplyMarkup", payload) }
    public func editMessageReplyMarkupInline(payload: Payload): Payload { this.call("editMessageReplyMarkup", payload) }
    public func stopPoll(payload: Payload): Payload { this.call("stopPoll", payload) }
    public func deleteMessage(payload: Payload): Payload { this.call("deleteMessage", payload) }
    public func deleteMessages(payload: Payload): Payload { this.call("deleteMessages", payload) }
    public func deleteBusinessMessages(payload: Payload): Payload { this.call("deleteBusinessMessages", payload) }
    public func setBusinessAccountName(payload: Payload): Payload { this.call("setBusinessAccountName", payload) }
    public func setBusinessAccountUsername(payload: Payload): Payload { this.call("setBusinessAccountUsername", payload) }
    public func setBusinessAccountBio(payload: Payload): Payload { this.call("setBusinessAccountBio", payload) }
    public func setBusinessAccountProfilePhoto(payload: Payload): Payload { this.call("setBusinessAccountProfilePhoto", payload) }
    public func removeBusinessAccountProfilePhoto(payload: Payload): Payload { this.call("removeBusinessAccountProfilePhoto", payload) }
    public func setBusinessAccountGiftSettings(payload: Payload): Payload { this.call("setBusinessAccountGiftSettings", payload) }
    public func getBusinessAccountStarBalance(payload: Payload): Payload { this.call("getBusinessAccountStarBalance", payload) }
    public func transferBusinessAccountStars(payload: Payload): Payload { this.call("transferBusinessAccountStars", payload) }
    public func getBusinessAccountGifts(payload: Payload): Payload { this.call("getBusinessAccountGifts", payload) }
    public func convertGiftToStars(payload: Payload): Payload { this.call("convertGiftToStars", payload) }
    public func upgradeGift(payload: Payload): Payload { this.call("upgradeGift", payload) }
    public func transferGift(payload: Payload): Payload { this.call("transferGift", payload) }
    public func postStory(payload: Payload): Payload { this.call("postStory", payload) }
    public func repostStory(payload: Payload): Payload { this.call("repostStory", payload) }
    public func editStory(payload: Payload): Payload { this.call("editStory", payload) }
    public func deleteStory(payload: Payload): Payload { this.call("deleteStory", payload) }
    public func sendSticker(payload: Payload): Payload { this.call("sendSticker", payload) }
    public func getStickerSet(payload: Payload): Payload { this.call("getStickerSet", payload) }
    public func getCustomEmojiStickers(payload: Payload): Payload { this.call("getCustomEmojiStickers", payload) }
    public func uploadStickerFile(payload: Payload): Payload { this.call("uploadStickerFile", payload) }
    public func createNewStickerSet(payload: Payload): Payload { this.call("createNewStickerSet", payload) }
    public func addStickerToSet(payload: Payload): Payload { this.call("addStickerToSet", payload) }
    public func setStickerPositionInSet(payload: Payload): Payload { this.call("setStickerPositionInSet", payload) }
    public func deleteStickerFromSet(payload: Payload): Payload { this.call("deleteStickerFromSet", payload) }
    public func replaceStickerInSet(payload: Payload): Payload { this.call("replaceStickerInSet", payload) }
    public func setStickerEmojiList(payload: Payload): Payload { this.call("setStickerEmojiList", payload) }
    public func setStickerKeywords(payload: Payload): Payload { this.call("setStickerKeywords", payload) }
    public func setStickerMaskPosition(payload: Payload): Payload { this.call("setStickerMaskPosition", payload) }
    public func setStickerSetTitle(payload: Payload): Payload { this.call("setStickerSetTitle", payload) }
    public func deleteStickerSet(payload: Payload): Payload { this.call("deleteStickerSet", payload) }
    public func setStickerSetThumbnail(payload: Payload): Payload { this.call("setStickerSetThumbnail", payload) }
    public func setCustomEmojiStickerSetThumbnail(payload: Payload): Payload { this.call("setCustomEmojiStickerSetThumbnail", payload) }
    public func getAvailableGifts(payload: Payload): Payload { this.call("getAvailableGifts", payload) }
    public func sendGift(payload: Payload): Payload { this.call("sendGift", payload) }
    public func giftPremiumSubscription(payload: Payload): Payload { this.call("giftPremiumSubscription", payload) }
    public func sendGiftToChannel(payload: Payload): Payload { this.call("sendGift", payload) }
    public func answerInlineQuery(payload: Payload): Payload { this.call("answerInlineQuery", payload) }
    public func answerWebAppQuery(payload: Payload): Payload { this.call("answerWebAppQuery", payload) }
    public func savePreparedInlineMessage(payload: Payload): Payload { this.call("savePreparedInlineMessage", payload) }
    public func savePreparedKeyboardButton(payload: Payload): Payload { this.call("savePreparedKeyboardButton", payload) }
    public func sendInvoice(payload: Payload): Payload { this.call("sendInvoice", payload) }
    public func createInvoiceLink(payload: Payload): Payload { this.call("createInvoiceLink", payload) }
    public func answerShippingQuery(payload: Payload): Payload { this.call("answerShippingQuery", payload) }
    public func answerPreCheckoutQuery(payload: Payload): Payload { this.call("answerPreCheckoutQuery", payload) }
    public func getStarTransactions(payload: Payload): Payload { this.call("getStarTransactions", payload) }
    public func refundStarPayment(payload: Payload): Payload { this.call("refundStarPayment", payload) }
    public func editUserStarSubscription(payload: Payload): Payload { this.call("editUserStarSubscription", payload) }
    public func verifyUser(payload: Payload): Payload { this.call("verifyUser", payload) }
    public func verifyChat(payload: Payload): Payload { this.call("verifyChat", payload) }
    public func removeUserVerification(payload: Payload): Payload { this.call("removeUserVerification", payload) }
    public func removeChatVerification(payload: Payload): Payload { this.call("removeChatVerification", payload) }
    public func readBusinessMessage(payload: Payload): Payload { this.call("readBusinessMessage", payload) }
    public func setPassportDataErrors(payload: Payload): Payload { this.call("setPassportDataErrors", payload) }
    public func sendGame(payload: Payload): Payload { this.call("sendGame", payload) }
    public func setGameScore(payload: Payload): Payload { this.call("setGameScore", payload) }
    public func setGameScoreInline(payload: Payload): Payload { this.call("setGameScore", payload) }
    public func getGameHighScores(payload: Payload): Payload { this.call("getGameHighScores", payload) }
    public func getGameHighScoresInline(payload: Payload): Payload { this.call("getGameHighScores", payload) }
}

public func apiWrapperGenerationSkeletonCount(): Int64 {
    apiWrapperCount()
}
