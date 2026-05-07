package grammy4cj.core

import std.unittest.*

private func methodName(payload: Payload): String {
    for (field in payload.fields) {
        if (field.key == "__method") {
            return field.value
        }
    }
    ""
}

private func hasApiWrapperMethod(name: String): Bool {
    for (method in apiWrapperMethodNames()) {
        if (method == name) {
            return true
        }
    }
    false
}

private func callWrapper(api: Api, name: String, payload: Payload): Payload {
    if (name == "getUpdates") { return api.getUpdates(payload) }
    if (name == "setWebhook") { return api.setWebhook(payload) }
    if (name == "deleteWebhook") { return api.deleteWebhook(payload) }
    if (name == "getWebhookInfo") { return api.getWebhookInfo(payload) }
    if (name == "getMe") { return api.getMe(payload) }
    if (name == "logOut") { return api.logOut(payload) }
    if (name == "close") { return api.close(payload) }
    if (name == "sendMessage") { return api.sendMessage(payload) }
    if (name == "sendMessageDraft") { return api.sendMessageDraft(payload) }
    if (name == "forwardMessage") { return api.forwardMessage(payload) }
    if (name == "forwardMessages") { return api.forwardMessages(payload) }
    if (name == "copyMessage") { return api.copyMessage(payload) }
    if (name == "copyMessages") { return api.copyMessages(payload) }
    if (name == "sendPhoto") { return api.sendPhoto(payload) }
    if (name == "sendAudio") { return api.sendAudio(payload) }
    if (name == "sendDocument") { return api.sendDocument(payload) }
    if (name == "sendVideo") { return api.sendVideo(payload) }
    if (name == "sendAnimation") { return api.sendAnimation(payload) }
    if (name == "sendVoice") { return api.sendVoice(payload) }
    if (name == "sendVideoNote") { return api.sendVideoNote(payload) }
    if (name == "sendMediaGroup") { return api.sendMediaGroup(payload) }
    if (name == "sendLocation") { return api.sendLocation(payload) }
    if (name == "editMessageLiveLocation") { return api.editMessageLiveLocation(payload) }
    if (name == "editMessageLiveLocationInline") { return api.editMessageLiveLocationInline(payload) }
    if (name == "stopMessageLiveLocation") { return api.stopMessageLiveLocation(payload) }
    if (name == "stopMessageLiveLocationInline") { return api.stopMessageLiveLocationInline(payload) }
    if (name == "sendPaidMedia") { return api.sendPaidMedia(payload) }
    if (name == "sendVenue") { return api.sendVenue(payload) }
    if (name == "sendContact") { return api.sendContact(payload) }
    if (name == "sendPoll") { return api.sendPoll(payload) }
    if (name == "sendChecklist") { return api.sendChecklist(payload) }
    if (name == "editMessageChecklist") { return api.editMessageChecklist(payload) }
    if (name == "sendDice") { return api.sendDice(payload) }
    if (name == "setMessageReaction") { return api.setMessageReaction(payload) }
    if (name == "sendChatAction") { return api.sendChatAction(payload) }
    if (name == "getUserProfilePhotos") { return api.getUserProfilePhotos(payload) }
    if (name == "getUserProfileAudios") { return api.getUserProfileAudios(payload) }
    if (name == "setUserEmojiStatus") { return api.setUserEmojiStatus(payload) }
    if (name == "getUserChatBoosts") { return api.getUserChatBoosts(payload) }
    if (name == "getUserGifts") { return api.getUserGifts(payload) }
    if (name == "getChatGifts") { return api.getChatGifts(payload) }
    if (name == "getBusinessConnection") { return api.getBusinessConnection(payload) }
    if (name == "getFile") { return api.getFile(payload) }
    if (name == "kickChatMember") { return api.kickChatMember(payload) }
    if (name == "banChatMember") { return api.banChatMember(payload) }
    if (name == "unbanChatMember") { return api.unbanChatMember(payload) }
    if (name == "restrictChatMember") { return api.restrictChatMember(payload) }
    if (name == "promoteChatMember") { return api.promoteChatMember(payload) }
    if (name == "setChatAdministratorCustomTitle") { return api.setChatAdministratorCustomTitle(payload) }
    if (name == "setChatMemberTag") { return api.setChatMemberTag(payload) }
    if (name == "banChatSenderChat") { return api.banChatSenderChat(payload) }
    if (name == "unbanChatSenderChat") { return api.unbanChatSenderChat(payload) }
    if (name == "setChatPermissions") { return api.setChatPermissions(payload) }
    if (name == "exportChatInviteLink") { return api.exportChatInviteLink(payload) }
    if (name == "createChatInviteLink") { return api.createChatInviteLink(payload) }
    if (name == "editChatInviteLink") { return api.editChatInviteLink(payload) }
    if (name == "createChatSubscriptionInviteLink") { return api.createChatSubscriptionInviteLink(payload) }
    if (name == "editChatSubscriptionInviteLink") { return api.editChatSubscriptionInviteLink(payload) }
    if (name == "revokeChatInviteLink") { return api.revokeChatInviteLink(payload) }
    if (name == "getManagedBotToken") { return api.getManagedBotToken(payload) }
    if (name == "replaceManagedBotToken") { return api.replaceManagedBotToken(payload) }
    if (name == "approveChatJoinRequest") { return api.approveChatJoinRequest(payload) }
    if (name == "declineChatJoinRequest") { return api.declineChatJoinRequest(payload) }
    if (name == "approveSuggestedPost") { return api.approveSuggestedPost(payload) }
    if (name == "declineSuggestedPost") { return api.declineSuggestedPost(payload) }
    if (name == "setChatPhoto") { return api.setChatPhoto(payload) }
    if (name == "deleteChatPhoto") { return api.deleteChatPhoto(payload) }
    if (name == "setChatTitle") { return api.setChatTitle(payload) }
    if (name == "setChatDescription") { return api.setChatDescription(payload) }
    if (name == "pinChatMessage") { return api.pinChatMessage(payload) }
    if (name == "unpinChatMessage") { return api.unpinChatMessage(payload) }
    if (name == "unpinAllChatMessages") { return api.unpinAllChatMessages(payload) }
    if (name == "leaveChat") { return api.leaveChat(payload) }
    if (name == "getChat") { return api.getChat(payload) }
    if (name == "getChatAdministrators") { return api.getChatAdministrators(payload) }
    if (name == "getChatMembersCount") { return api.getChatMembersCount(payload) }
    if (name == "getChatMemberCount") { return api.getChatMemberCount(payload) }
    if (name == "getChatMember") { return api.getChatMember(payload) }
    if (name == "setChatStickerSet") { return api.setChatStickerSet(payload) }
    if (name == "deleteChatStickerSet") { return api.deleteChatStickerSet(payload) }
    if (name == "getForumTopicIconStickers") { return api.getForumTopicIconStickers(payload) }
    if (name == "createForumTopic") { return api.createForumTopic(payload) }
    if (name == "editForumTopic") { return api.editForumTopic(payload) }
    if (name == "closeForumTopic") { return api.closeForumTopic(payload) }
    if (name == "reopenForumTopic") { return api.reopenForumTopic(payload) }
    if (name == "deleteForumTopic") { return api.deleteForumTopic(payload) }
    if (name == "unpinAllForumTopicMessages") { return api.unpinAllForumTopicMessages(payload) }
    if (name == "editGeneralForumTopic") { return api.editGeneralForumTopic(payload) }
    if (name == "closeGeneralForumTopic") { return api.closeGeneralForumTopic(payload) }
    if (name == "reopenGeneralForumTopic") { return api.reopenGeneralForumTopic(payload) }
    if (name == "hideGeneralForumTopic") { return api.hideGeneralForumTopic(payload) }
    if (name == "unhideGeneralForumTopic") { return api.unhideGeneralForumTopic(payload) }
    if (name == "unpinAllGeneralForumTopicMessages") { return api.unpinAllGeneralForumTopicMessages(payload) }
    if (name == "answerCallbackQuery") { return api.answerCallbackQuery(payload) }
    if (name == "setMyName") { return api.setMyName(payload) }
    if (name == "getMyName") { return api.getMyName(payload) }
    if (name == "setMyCommands") { return api.setMyCommands(payload) }
    if (name == "deleteMyCommands") { return api.deleteMyCommands(payload) }
    if (name == "getMyCommands") { return api.getMyCommands(payload) }
    if (name == "setMyDescription") { return api.setMyDescription(payload) }
    if (name == "getMyDescription") { return api.getMyDescription(payload) }
    if (name == "setMyShortDescription") { return api.setMyShortDescription(payload) }
    if (name == "getMyShortDescription") { return api.getMyShortDescription(payload) }
    if (name == "setMyProfilePhoto") { return api.setMyProfilePhoto(payload) }
    if (name == "removeMyProfilePhoto") { return api.removeMyProfilePhoto(payload) }
    if (name == "setChatMenuButton") { return api.setChatMenuButton(payload) }
    if (name == "getChatMenuButton") { return api.getChatMenuButton(payload) }
    if (name == "setMyDefaultAdministratorRights") { return api.setMyDefaultAdministratorRights(payload) }
    if (name == "getMyDefaultAdministratorRights") { return api.getMyDefaultAdministratorRights(payload) }
    if (name == "getMyStarBalance") { return api.getMyStarBalance(payload) }
    if (name == "editMessageText") { return api.editMessageText(payload) }
    if (name == "editMessageTextInline") { return api.editMessageTextInline(payload) }
    if (name == "editMessageCaption") { return api.editMessageCaption(payload) }
    if (name == "editMessageCaptionInline") { return api.editMessageCaptionInline(payload) }
    if (name == "editMessageMedia") { return api.editMessageMedia(payload) }
    if (name == "editMessageMediaInline") { return api.editMessageMediaInline(payload) }
    if (name == "editMessageReplyMarkup") { return api.editMessageReplyMarkup(payload) }
    if (name == "editMessageReplyMarkupInline") { return api.editMessageReplyMarkupInline(payload) }
    if (name == "stopPoll") { return api.stopPoll(payload) }
    if (name == "deleteMessage") { return api.deleteMessage(payload) }
    if (name == "deleteMessages") { return api.deleteMessages(payload) }
    if (name == "deleteBusinessMessages") { return api.deleteBusinessMessages(payload) }
    if (name == "setBusinessAccountName") { return api.setBusinessAccountName(payload) }
    if (name == "setBusinessAccountUsername") { return api.setBusinessAccountUsername(payload) }
    if (name == "setBusinessAccountBio") { return api.setBusinessAccountBio(payload) }
    if (name == "setBusinessAccountProfilePhoto") { return api.setBusinessAccountProfilePhoto(payload) }
    if (name == "removeBusinessAccountProfilePhoto") { return api.removeBusinessAccountProfilePhoto(payload) }
    if (name == "setBusinessAccountGiftSettings") { return api.setBusinessAccountGiftSettings(payload) }
    if (name == "getBusinessAccountStarBalance") { return api.getBusinessAccountStarBalance(payload) }
    if (name == "transferBusinessAccountStars") { return api.transferBusinessAccountStars(payload) }
    if (name == "getBusinessAccountGifts") { return api.getBusinessAccountGifts(payload) }
    if (name == "convertGiftToStars") { return api.convertGiftToStars(payload) }
    if (name == "upgradeGift") { return api.upgradeGift(payload) }
    if (name == "transferGift") { return api.transferGift(payload) }
    if (name == "postStory") { return api.postStory(payload) }
    if (name == "repostStory") { return api.repostStory(payload) }
    if (name == "editStory") { return api.editStory(payload) }
    if (name == "deleteStory") { return api.deleteStory(payload) }
    if (name == "sendSticker") { return api.sendSticker(payload) }
    if (name == "getStickerSet") { return api.getStickerSet(payload) }
    if (name == "getCustomEmojiStickers") { return api.getCustomEmojiStickers(payload) }
    if (name == "uploadStickerFile") { return api.uploadStickerFile(payload) }
    if (name == "createNewStickerSet") { return api.createNewStickerSet(payload) }
    if (name == "addStickerToSet") { return api.addStickerToSet(payload) }
    if (name == "setStickerPositionInSet") { return api.setStickerPositionInSet(payload) }
    if (name == "deleteStickerFromSet") { return api.deleteStickerFromSet(payload) }
    if (name == "replaceStickerInSet") { return api.replaceStickerInSet(payload) }
    if (name == "setStickerEmojiList") { return api.setStickerEmojiList(payload) }
    if (name == "setStickerKeywords") { return api.setStickerKeywords(payload) }
    if (name == "setStickerMaskPosition") { return api.setStickerMaskPosition(payload) }
    if (name == "setStickerSetTitle") { return api.setStickerSetTitle(payload) }
    if (name == "deleteStickerSet") { return api.deleteStickerSet(payload) }
    if (name == "setStickerSetThumbnail") { return api.setStickerSetThumbnail(payload) }
    if (name == "setCustomEmojiStickerSetThumbnail") { return api.setCustomEmojiStickerSetThumbnail(payload) }
    if (name == "getAvailableGifts") { return api.getAvailableGifts(payload) }
    if (name == "sendGift") { return api.sendGift(payload) }
    if (name == "giftPremiumSubscription") { return api.giftPremiumSubscription(payload) }
    if (name == "sendGiftToChannel") { return api.sendGiftToChannel(payload) }
    if (name == "answerInlineQuery") { return api.answerInlineQuery(payload) }
    if (name == "answerWebAppQuery") { return api.answerWebAppQuery(payload) }
    if (name == "savePreparedInlineMessage") { return api.savePreparedInlineMessage(payload) }
    if (name == "savePreparedKeyboardButton") { return api.savePreparedKeyboardButton(payload) }
    if (name == "sendInvoice") { return api.sendInvoice(payload) }
    if (name == "createInvoiceLink") { return api.createInvoiceLink(payload) }
    if (name == "answerShippingQuery") { return api.answerShippingQuery(payload) }
    if (name == "answerPreCheckoutQuery") { return api.answerPreCheckoutQuery(payload) }
    if (name == "getStarTransactions") { return api.getStarTransactions(payload) }
    if (name == "refundStarPayment") { return api.refundStarPayment(payload) }
    if (name == "editUserStarSubscription") { return api.editUserStarSubscription(payload) }
    if (name == "verifyUser") { return api.verifyUser(payload) }
    if (name == "verifyChat") { return api.verifyChat(payload) }
    if (name == "removeUserVerification") { return api.removeUserVerification(payload) }
    if (name == "removeChatVerification") { return api.removeChatVerification(payload) }
    if (name == "readBusinessMessage") { return api.readBusinessMessage(payload) }
    if (name == "setPassportDataErrors") { return api.setPassportDataErrors(payload) }
    if (name == "sendGame") { return api.sendGame(payload) }
    if (name == "setGameScore") { return api.setGameScore(payload) }
    if (name == "setGameScoreInline") { return api.setGameScoreInline(payload) }
    if (name == "getGameHighScores") { return api.getGameHighScores(payload) }
    if (name == "getGameHighScoresInline") { return api.getGameHighScoresInline(payload) }
    throw Exception("No API wrapper for " + name)
}

@Test
public class ApiWrapperTest {
    @TestCase
    public func wrapperTableCountsUpstreamMethods(): Unit {
        @Expect(apiWrapperMethodNames().size, 180)
        @Expect(apiWrapperCount(), 180)
        @Expect(apiWrapperGenerationSkeletonCount(), 180)
        @Expect(apiWrapperMethodNames()[0], "getUpdates")
        @Expect(apiWrapperMethodNames()[179], "getGameHighScoresInline")
    }

    @TestCase
    public func everyWrapperOutputsItsPublicMethodName(): Unit {
        let api = Api("token")
        let payload = Payload("").addValue("chat_id", "42")

        for (method in apiWrapperMethodNames()) {
            @Expect(methodName(callWrapper(api, method, payload)), method)
        }
    }

    @TestCase
    public func inlineVariantsAndAliasesAreNotOmitted(): Unit {
        @Expect(hasApiWrapperMethod("editMessageLiveLocationInline"), true)
        @Expect(hasApiWrapperMethod("stopMessageLiveLocationInline"), true)
        @Expect(hasApiWrapperMethod("editMessageTextInline"), true)
        @Expect(hasApiWrapperMethod("editMessageCaptionInline"), true)
        @Expect(hasApiWrapperMethod("editMessageMediaInline"), true)
        @Expect(hasApiWrapperMethod("editMessageReplyMarkupInline"), true)
        @Expect(hasApiWrapperMethod("setGameScoreInline"), true)
        @Expect(hasApiWrapperMethod("getGameHighScoresInline"), true)
        @Expect(hasApiWrapperMethod("kickChatMember"), true)
        @Expect(hasApiWrapperMethod("getChatMembersCount"), true)
        @Expect(hasApiWrapperMethod("getChatMemberCount"), true)
    }
}
