package grammy4cj.core

import std.collection.ArrayList
import std.unittest.*

import grammy4cj.types.ApiResponse
import grammy4cj.types.InputFile
import grammy4cj.types.Message
import grammy4cj.types.Update
import grammy4cj.types.User

private class ApiTestFakeFetch <: CoreFetch {
    public var called: Bool = false
    public var method: String = ""
    public var url: String = ""
    public var headers: String = ""
    public var body: String = ""
    public let result: String

    public init(result: String) {
        this.result = result
    }

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        signal.throwIfCancelled()
        this.called = true
        this.method = request.method
        this.url = request.url
        this.headers = request.headers
        this.body = if (request.payload.bodyKind == "stream" && !request.payload.stream.hasError) {
            request.payload.drainBody()
        } else {
            request.body
        }
        CoreFetchResponse.api(ApiResponse.success(this.result))
    }
}

private func methodName(payload: Payload): String {
    for (field in payload.fields) {
        if (field.key == "__method") {
            return field.value
        }
    }
    ""
}

private func methodName<T>(result: ApiResult<T>): String {
    for (field in result.fields) {
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

private func payloadBody<T>(result: ApiResult<T>): String {
    for (field in result.fields) {
        if (field.key == "__payload") {
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

private func goldenRowFor(rows: ArrayList<String>, method: String): String {
    for (row in rows) {
        if (row.startsWith(method + "~")) {
            return row
        }
    }
    ""
}

private func tracePulledFieldsAreInPayloadSchema(trace: ApiWrapperSchemaTrace): Bool {
    if (trace.pulledPayloadFieldTrace == "") {
        return true
    }
    for (field in trace.pulledPayloadFieldTrace.split(",")) {
        if (field != "" && !trace.hasPayloadField(field)) {
            return false
        }
    }
    true
}

@Test
public class ApiWrapperTest {
    @TestCase
    public func wrapperTableCountsUpstreamMethods(): Unit {
        @Expect(apiWrapperMethodNames().size, 180)
        @Expect(apiWrapperCount(), 180)
        @Expect(apiRawFacadeMethodNames().size, 180)
        @Expect(apiRawFacadeCount(), 180)
        @Expect(apiWrapperGenerationSkeletonCount(), 180)
        @Expect(apiWrapperSchemaTraceCount(), 180)
        @Expect(apiWrapperSignatureTraceCount(), 180)
        @Expect(apiWrapperSchemaTraceRows().size, 180)
        @Expect(apiWrapperMinimalPayloadGoldenRows().size, 180)
        @Expect(apiWrapperPublicOutputGoldenRows().size, 180)
        @Expect(apiWrapperTypedResultRows().size, 180)
        @Expect(apiWrapperOtherPayloadSchemaTraceCount(), 180)
        @Expect(apiWrapperOtherPayloadSchemaRows().size, 180)
        @Expect(apiWrapperMissingReturnTypeCount(), 0)
        @Expect(apiRawZeroArgMethodNames().size, 8)
        @Expect(apiWrapperMethodNames()[0], "getUpdates")
        @Expect(apiWrapperMethodNames()[179], "getGameHighScoresInline")
    }

    @TestCase
    public func everyWrapperDispatchesToUpstreamRawMethod(): Unit {
        let api = Api.trace("token")
        let payload = Payload("").addValue("chat_id", "42").addValue("payload_matrix", "kept")

        for (method in apiWrapperMethodNames()) {
            let trace = apiWrapperSchemaTraceFor(method)
            let output = callWrapper(api, method, payload)
            @Expect(methodName(output), trace.rawMethodName)
            if (!trace.isZeroArgRaw) {
                @Expect(payloadBody(output).contains("\"payload_matrix\":\"kept\""), true)
            }
        }
    }

    @TestCase
    public func schemaTraceCoversEveryWrapperPayloadAndReturn(): Unit {
        for (trace in apiWrapperSchemaTraces()) {
            @Expect(hasApiWrapperMethod(trace.publicMethodName), true)
            @Expect(trace.rawMethodName != "", true)
            @Expect(trace.returnTypeTrace != "", true)
            @Expect(tracePulledFieldsAreInPayloadSchema(trace), true)
        }
    }

    @TestCase
    public func signatureMatrixTracksRequiredPayloadSignalAndReturnTotals(): Unit {
        @Expect(apiWrapperRequiredParameterTotal(), 327)
        @Expect(apiWrapperOptionalParameterTotal(), 3)
        @Expect(apiWrapperRequiredPayloadFieldTotal(), 289)
        @Expect(apiWrapperOptionalPayloadFieldTotal(), 622)
        @Expect(apiWrapperReturnTypeKindCount(), 61)

        for (trace in apiWrapperSignatureTraces()) {
            @Expect(hasApiWrapperMethod(trace.publicMethodName), true)
            @Expect(trace.rawMethodName != "", true)
            @Expect(trace.signalTrace, "AbortSignal")
            @Expect(trace.cancelTrace, "CancelSignal")
            @Expect(trace.returnTypeTrace != "", true)
        }

        let sendMessage = apiWrapperSignatureTraceFor("sendMessage")
        @Expect(sendMessage.requiredParameterTrace, "chat_id,text")
        @Expect(sendMessage.optionalParameterTrace, "")
        @Expect(sendMessage.otherPayloadFieldTrace.contains("reply_markup"), true)

        let description = apiWrapperSignatureTraceFor("setChatDescription")
        @Expect(description.requiredParameterTrace, "chat_id")
        @Expect(description.optionalParameterTrace, "description")

        let unpin = apiWrapperSignatureTraceFor("unpinChatMessage")
        @Expect(unpin.requiredParameterTrace, "chat_id")
        @Expect(unpin.optionalParameterTrace, "message_id")

        let business = apiWrapperSignatureTraceFor("setBusinessAccountName")
        @Expect(business.requiredParameterTrace, "business_connection_id,first_name")
        @Expect(business.otherPayloadFieldTrace, "last_name")
    }

    @TestCase
    public func minimalPayloadGoldensCoverAllWrappers(): Unit {
        let rows = apiWrapperMinimalPayloadGoldenRows()
        @Expect(rows.size, 180)
        @Expect(goldenRowFor(rows, "getMe"), "getMe~{}")
        @Expect(
            goldenRowFor(rows, "sendMessage"),
            "sendMessage~{\"chat_id\":\"chat_id_value\",\"text\":\"text_value\"}"
        )
        @Expect(
            goldenRowFor(rows, "editMessageTextInline"),
            "editMessageTextInline~{\"inline_message_id\":\"inline_message_id_value\",\"text\":\"text_value\"}"
        )
        @Expect(goldenRowFor(rows, "sendInvoice").contains("\"prices\":\"prices_value\""), true)

        let api = Api.trace("token")
        for (method in apiWrapperMethodNames()) {
            let output = callWrapper(api, method, apiWrapperMinimalPayloadFor(method))
            @Expect(methodName(output), apiWrapperSchemaTraceFor(method).rawMethodName)
            @Expect(payloadBody(output), goldenRowFor(rows, method).split("~")[1])
        }
    }

    @TestCase
    public func publicOutputGoldenCapturesRawRequiredOtherSignalAndReturn(): Unit {
        let rows = apiWrapperPublicOutputGoldenRows()
        @Expect(rows.size, 180)
        @Expect(goldenRowFor(rows, "getUpdates").contains("getUpdates~getUpdates~~~offset,limit,timeout,allowed_updates~AbortSignal~CancelSignal~Update[]"), true)
        @Expect(goldenRowFor(rows, "sendMessage").contains("sendMessage~sendMessage~chat_id,text~~"), true)
        @Expect(goldenRowFor(rows, "sendMessage").contains("AbortSignal~CancelSignal~Message.TextMessage"), true)
        @Expect(goldenRowFor(rows, "editMessageTextInline").contains("editMessageTextInline~editMessageText~inline_message_id,text~~"), true)
        @Expect(goldenRowFor(rows, "kickChatMember").contains("kickChatMember~banChatMember~chat_id,user_id~~until_date,revoke_messages"), true)
        @Expect(goldenRowFor(rows, "getGameHighScoresInline").contains("getGameHighScoresInline~getGameHighScores~inline_message_id,user_id~~"), true)
    }

    @TestCase
    public func otherPayloadSchemaSubstitutesTypescriptOtherContract(): Unit {
        let rows = apiWrapperOtherPayloadSchemaRows()
        @Expect(rows.size, 180)

        let sendMessage = apiWrapperOtherPayloadSchemaTraceFor("sendMessage")
        @Expect(sendMessage.rawMethodName, "sendMessage")
        @Expect(sendMessage.pulledParameterTrace, "chat_id,text")
        @Expect(sendMessage.excludesPulledParameter("chat_id"), true)
        @Expect(sendMessage.excludesPulledParameter("text"), true)
        @Expect(sendMessage.allowsPayloadField("reply_markup"), true)
        @Expect(sendMessage.allowsOtherPayload, true)

        let getMe = apiWrapperOtherPayloadSchemaTraceFor("getMe")
        @Expect(getMe.allowsOtherPayload, false)
        @Expect(getMe.excludedOtherFieldTrace, "")

        let inlineEdit = apiWrapperOtherPayloadSchemaTraceFor("editMessageTextInline")
        @Expect(inlineEdit.rawMethodName, "editMessageText")
        @Expect(inlineEdit.excludesPulledParameter("inline_message_id"), true)
        @Expect(inlineEdit.excludesPulledParameter("text"), true)
        @Expect(inlineEdit.allowsPayloadField("chat_id"), true)
        @Expect(inlineEdit.allowsPayloadField("reply_markup"), true)
    }

    @TestCase
    public func inlineVariantsAliasesAndRawZeroArgTableAreTraced(): Unit {
        var inlineCount = 0
        var aliasCount = 0
        var rawVariantCount = 0
        var zeroArgCount = 0

        for (trace in apiWrapperSchemaTraces()) {
            if (trace.isInlineVariant) {
                inlineCount += 1
            }
            if (trace.isAlias) {
                aliasCount += 1
            }
            if (trace.isRawVariant) {
                rawVariantCount += 1
            }
            if (trace.isZeroArgRaw) {
                zeroArgCount += 1
            }
        }

        @Expect(inlineCount, 8)
        @Expect(aliasCount, 2)
        @Expect(rawVariantCount, 9)
        @Expect(zeroArgCount, 8)
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
        @Expect(hasApiWrapperMethod("sendGiftToChannel"), true)
        @Expect(apiWrapperSchemaTraceFor("getMe").isZeroArgRaw, true)
        @Expect(apiWrapperSchemaTraceFor("getWebhookInfo").isZeroArgRaw, true)
        @Expect(apiWrapperSchemaTraceFor("getForumTopicIconStickers").isZeroArgRaw, true)
        @Expect(apiWrapperSchemaTraceFor("getAvailableGifts").isZeroArgRaw, true)
        @Expect(apiWrapperSchemaTraceFor("removeMyProfilePhoto").isZeroArgRaw, true)
    }

    @TestCase
    public func apiResultRowsTrackRepresentativeTypedReturnShape(): Unit {
        @Expect(goldenRowFor(apiWrapperTypedResultRows(), "getMe"), "getMe~ApiResult<User>")
        @Expect(goldenRowFor(apiWrapperTypedResultRows(), "sendMessage"), "sendMessage~ApiResult<Message.TextMessage>")
        @Expect(goldenRowFor(apiWrapperTypedResultRows(), "getUpdates"), "getUpdates~ApiResult<Update[]>")
    }

    @TestCase
    public func complexWrapperPayloadSchemaMatchesUpstreamOptionsMerge(): Unit {
        let sendMessage = apiWrapperSchemaTraceFor("sendMessage")
        @Expect(sendMessage.rawMethodName, "sendMessage")
        @Expect(sendMessage.hasPayloadField("chat_id"), true)
        @Expect(sendMessage.hasPayloadField("text"), true)
        @Expect(sendMessage.hasPayloadField("reply_markup"), true)
        @Expect(sendMessage.returnTypeTrace, "Message.TextMessage")

        let sendPoll = apiWrapperSchemaTraceFor("sendPoll")
        @Expect(sendPoll.hasPayloadField("chat_id"), true)
        @Expect(sendPoll.hasPayloadField("question"), true)
        @Expect(sendPoll.hasPayloadField("options"), true)
        @Expect(sendPoll.hasPayloadField("question_parse_mode"), true)
        @Expect(sendPoll.hasPayloadField("reply_markup"), true)
        @Expect(sendPoll.returnTypeTrace, "Message.PollMessage")

        let inlineEdit = apiWrapperSchemaTraceFor("editMessageTextInline")
        @Expect(inlineEdit.rawMethodName, "editMessageText")
        @Expect(inlineEdit.isInlineVariant, true)
        @Expect(inlineEdit.hasPayloadField("inline_message_id"), true)
        @Expect(inlineEdit.hasPayloadField("text"), true)
        @Expect(inlineEdit.hasPayloadField("chat_id"), true)
        @Expect(inlineEdit.returnTypeTrace, "(Update.Edited & Message.TextMessage) | true")

        let kick = apiWrapperSchemaTraceFor("kickChatMember")
        @Expect(kick.rawMethodName, "banChatMember")
        @Expect(kick.aliasOf, "banChatMember")
        @Expect(kick.isAlias, true)

        let countAlias = apiWrapperSchemaTraceFor("getChatMembersCount")
        @Expect(countAlias.rawMethodName, "getChatMemberCount")
        @Expect(countAlias.aliasOf, "getChatMemberCount")
        @Expect(countAlias.returnTypeTrace, "number")

        let channelGift = apiWrapperSchemaTraceFor("sendGiftToChannel")
        @Expect(channelGift.rawMethodName, "sendGift")
        @Expect(channelGift.hasPayloadField("chat_id"), true)
        @Expect(channelGift.hasPayloadField("gift_id"), true)
        @Expect(channelGift.hasPayloadField("user_id"), true)
        @Expect(channelGift.returnTypeTrace, "true")
    }

    @TestCase
    public func typedWrapperPayloadGoldensMergeRequiredAndOtherOptions(): Unit {
        let api = Api.trace("token")

        let messageOptions = Payload("").addValue("parse_mode", "MarkdownV2").addBool("disable_notification", true)
        let message = api.sendMessage(42, "hi", messageOptions)
        @Expect(methodName(message), "sendMessage")
        @Expect(payloadBody(message), "{\"chat_id\":42,\"text\":\"hi\",\"parse_mode\":\"MarkdownV2\",\"disable_notification\":true}")

        let photo = api.sendPhoto(42, InputFile.fromBytes("abc", "photo.jpg"))
        @Expect(methodName(photo), "sendPhoto")
        @Expect(payloadBody(photo), "{\"chat_id\":42,\"photo\":\"abc\"}")

        let pollOptions = Payload("").addBool("is_anonymous", false)
        let poll = api.sendPoll(42, "question", ["yes", "no"], pollOptions)
        @Expect(methodName(poll), "sendPoll")
        @Expect(payloadBody(poll), "{\"chat_id\":42,\"question\":\"question\",\"options\":[{\"text\":\"yes\"},{\"text\":\"no\"}],\"is_anonymous\":false}")

        let editInline = api.editMessageTextInline("inline-id", "new text")
        @Expect(methodName(editInline), "editMessageText")
        @Expect(payloadBody(editInline), "{\"inline_message_id\":\"inline-id\",\"text\":\"new text\"}")

        let promoted = api.promoteChatMember(42, 7, Payload("").addBool("can_manage_chat", true))
        @Expect(methodName(promoted), "promoteChatMember")
        @Expect(payloadBody(promoted), "{\"chat_id\":42,\"user_id\":7,\"can_manage_chat\":true}")

        let forum = api.createForumTopic(42, "topic")
        @Expect(methodName(forum), "createForumTopic")
        @Expect(payloadBody(forum), "{\"chat_id\":42,\"name\":\"topic\"}")

        let business = api.setBusinessAccountName("bcid", "Ada", Payload("").addValue("last_name", "Lovelace"))
        @Expect(methodName(business), "setBusinessAccountName")
        @Expect(payloadBody(business), "{\"business_connection_id\":\"bcid\",\"first_name\":\"Ada\",\"last_name\":\"Lovelace\"}")
    }

    @TestCase
    public func zeroArgPublicWrappersAndCallPublicMapToRawMethods(): Unit {
        let api = Api.trace("token")

        @Expect(methodName(api.getWebhookInfo()), "getWebhookInfo")
        @Expect(payloadBody(api.getWebhookInfo()), "{}")
        @Expect(methodName(api.logOut()), "logOut")
        @Expect(methodName(api.close()), "close")
        @Expect(methodName(api.getForumTopicIconStickers()), "getForumTopicIconStickers")
        @Expect(methodName(api.getAvailableGifts()), "getAvailableGifts")
        @Expect(methodName(api.getMyStarBalance()), "getMyStarBalance")
        @Expect(methodName(api.removeMyProfilePhoto()), "removeMyProfilePhoto")

        let publicAlias = api.callPublic("kickChatMember", Payload("").addInt("chat_id", 42).addInt("user_id", 7))
        @Expect(methodName(publicAlias), "banChatMember")
        @Expect(payloadBody(publicAlias), "{\"chat_id\":42,\"user_id\":7}")
    }

    @TestCase
    public func apiWrapperUsesRawApiAndReturnsTelegramResultWhenFetcherInjected(): Unit {
        let fake = ApiTestFakeFetch("{\"message_id\":1,\"chat\":{\"id\":42,\"type\":\"private\"},\"text\":\"hi\"}")
        let api = Api("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        let result = api.sendMessage(42, "hi")

        let typed: ApiResult<Message> = result
        @Expect(typed.body, "{\"message_id\":1,\"chat\":{\"id\":42,\"type\":\"private\"},\"text\":\"hi\"}")
        @Expect(typed.value.messageId, 1)
        @Expect(typed.value.chat.id, 42)
        @Expect(typed.value.text, "hi")
        @Expect(typed.typeTrace, "Message.TextMessage")
        @Expect(fake.called, true)
        @Expect(fake.url, "https://api.telegram.org/bottoken/sendMessage")
        @Expect(fake.body, "{\"chat_id\":42,\"text\":\"hi\"}")
        @Expect(api.raw.call("getMe", Payload("{}")), "{\"message_id\":1,\"chat\":{\"id\":42,\"type\":\"private\"},\"text\":\"hi\"}")
    }

    @TestCase
    public func allPayloadWrappersReturnRawTelegramResultWhenFetcherInjected(): Unit {
        let fake = ApiTestFakeFetch("{\"result\":\"ok\"}")
        let api = Api("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        for (method in apiWrapperMethodNames()) {
            let trace = apiWrapperSchemaTraceFor(method)
            let result = callWrapper(api, method, apiWrapperMinimalPayloadFor(method))
            @Expect(result.body, "{\"result\":\"ok\"}")
            @Expect(fake.url, "https://api.telegram.org/bottoken/" + trace.rawMethodName)
        }
    }

    @TestCase
    public func rawModeWrappersMapAliasesInlineAndMultipartPayloads(): Unit {
        let fake = ApiTestFakeFetch("{\"ok\":true}")
        let api = Api("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        @Expect(api.kickChatMember(Payload("").addInt("chat_id", 42).addInt("user_id", 7)).body, "{\"ok\":true}")
        @Expect(fake.url, "https://api.telegram.org/bottoken/banChatMember")
        @Expect(api.editMessageTextInline("inline-id", "new text").body, "{\"ok\":true}")
        @Expect(fake.url, "https://api.telegram.org/bottoken/editMessageText")
        @Expect(api.sendPhoto(42, InputFile.fromBytes("photo-bytes", "photo.jpg")).body, "{\"ok\":true}")
        @Expect(fake.url, "https://api.telegram.org/bottoken/sendPhoto")
        @Expect(fake.headers.contains("multipart/form-data; boundary=----------"), true)
        @Expect(fake.body.contains("name=\"photo\"\r\n\r\nattach://"), true)
        @Expect(fake.body.contains("filename=photo.jpg"), true)
    }

    @TestCase
    public func apiUseInstallsTransformersThatWrapWrapperCalls(): Unit {
        let fake = ApiTestFakeFetch("{\"message_id\":1,\"chat\":{\"id\":42,\"type\":\"private\"},\"text\":\"hi\"}")
        let api = Api("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        api.config.use("annotate", { prev: ApiCallFn, method: String, payload: Payload, signal: CancelSignal =>
            @Expect(method, "sendMessage")
            prev(method, payload.addValue("via_transformer", "yes"), signal)
        })

        @Expect(api.sendMessage(42, "hi").body, "{\"message_id\":1,\"chat\":{\"id\":42,\"type\":\"private\"},\"text\":\"hi\"}")
        @Expect(api.config.installedTransformers().size, 1)
        @Expect(api.config.installedTransformers()[0], "annotate")
        @Expect(fake.body, "{\"chat_id\":42,\"text\":\"hi\",\"via_transformer\":\"yes\"}")
    }

    @TestCase
    public func typedWrapperOtherPayloadAndCancelSignalOverloadDispatches(): Unit {
        let fake = ApiTestFakeFetch("{\"message_id\":2,\"chat\":{\"id\":42,\"type\":\"private\"},\"text\":\"hi\"}")
        let api = Api("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)
        let signal = CancelSignal()

        let result = api.sendMessage(42, "hi", Payload("").addValue("parse_mode", "HTML"), signal)

        @Expect(result.value.messageId, 2)
        @Expect(fake.body, "{\"chat_id\":42,\"text\":\"hi\",\"parse_mode\":\"HTML\"}")
    }

    @TestCase
    public func apiConfigNamespaceReturnsTransformerCopiesAndCanSeedNewApi(): Unit {
        let api = Api("token")

        api.config.use("first").use("second")
        api.config.use("fn", { prev: ApiCallFn, method: String, payload: Payload, signal: CancelSignal =>
            prev(method, payload.addValue("copied_fn", "yes"), signal)
        })
        let installed = api.config.installedTransformers()
        installed[0] = "mutated"
        let fake = ApiTestFakeFetch("{\"ok\":true}")
        let copied = Api("other-token", api.config)
        let copiedWithFetch = Api("other-token", api.config, fake)
        api.config.use("third")

        @Expect(api.config.installedTransformers()[0], "first")
        @Expect(api.config.installedTransformers().size, 4)
        @Expect(api.config.installedTransformerFunctions().size, 1)
        @Expect(copied.config.installedTransformers().size, 3)
        @Expect(copied.config.installedTransformers()[0], "first")
        @Expect(copied.config.installedTransformers()[1], "second")
        @Expect(copied.config.installedTransformerFunctions().size, 1)
        @Expect(copied.endpointFor("getMe"), "https://api.telegram.org/botother-token/getMe")
        @Expect(copiedWithFetch.sendMessage(42, "hi").body, "{\"ok\":true}")
        @Expect(fake.body, "{\"chat_id\":42,\"text\":\"hi\",\"copied_fn\":\"yes\"}")
    }

    @TestCase
    public func representativeApiMethodsReturnTypedResults(): Unit {
        let fake = ApiTestFakeFetch("{\"id\":7,\"is_bot\":true,\"first_name\":\"Ada\",\"username\":\"ada_bot\"}")
        let api = Api("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        let me: ApiResult<User> = api.getMe()

        @Expect(me.body, "{\"id\":7,\"is_bot\":true,\"first_name\":\"Ada\",\"username\":\"ada_bot\"}")
        @Expect(me.value.id, 7)
        @Expect(me.value.isBot, true)
        @Expect(me.value.firstName, "Ada")
        @Expect(me.typeTrace, "User")
    }

    @TestCase
    public func getUpdatesReturnsTypedUpdateArrayResult(): Unit {
        let fake = ApiTestFakeFetch("[{\"update_id\":11,\"message\":{}},{\"update_id\":12,\"edited_message\":{}}]")
        let api = Api("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        let updates: ApiResult<ArrayList<Update>> = api.getUpdates()

        @Expect(updates.value.size, 2)
        @Expect(updates.value[0].updateId, 11)
        @Expect(updates.value[1].updateId, 12)
        @Expect(updates.typeTrace, "Update[]")
    }

    @TestCase
    public func typedWrapperCancelSignalFailsBeforeDispatch(): Unit {
        let api = Api("token")
        let controller = CancelController()
        controller.cancel("abort send")

        try {
            api.sendMessage(42, "hi", controller.signal)
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message, "Network request for 'sendMessage' failed!")
            @Expect(err.error.contains("Operation cancelled: abort send"), true)
        }
    }

    @TestCase
    public func payloadBuilderRejectsMissingRequiredParameters(): Unit {
        try {
            ApiWrapperPayloadBuilder("sendMessage").setInt("chat_id", 42).build()
            @Expect(true, false)
        } catch (err: Exception) {
            @Expect(err.message.contains("Missing required API wrapper parameter 'text' for sendMessage"), true)
        }

        let payload = ApiWrapperPayloadBuilder("sendMessage")
            .setInt("chat_id", 42)
            .setString("text", "hi")
            .build()
        @Expect(createJsonPayload(payload).body, "{\"chat_id\":42,\"text\":\"hi\"}")
    }
}
