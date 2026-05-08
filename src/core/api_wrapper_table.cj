package grammy4cj.core

import std.collection.ArrayList

public func apiWrapperMethodNames(): Array<String> {
    [
        "getUpdates",
        "setWebhook",
        "deleteWebhook",
        "getWebhookInfo",
        "getMe",
        "logOut",
        "close",
        "sendMessage",
        "sendMessageDraft",
        "forwardMessage",
        "forwardMessages",
        "copyMessage",
        "copyMessages",
        "sendPhoto",
        "sendAudio",
        "sendDocument",
        "sendVideo",
        "sendAnimation",
        "sendVoice",
        "sendVideoNote",
        "sendMediaGroup",
        "sendLocation",
        "editMessageLiveLocation",
        "editMessageLiveLocationInline",
        "stopMessageLiveLocation",
        "stopMessageLiveLocationInline",
        "sendPaidMedia",
        "sendVenue",
        "sendContact",
        "sendPoll",
        "sendChecklist",
        "editMessageChecklist",
        "sendDice",
        "setMessageReaction",
        "sendChatAction",
        "getUserProfilePhotos",
        "getUserProfileAudios",
        "setUserEmojiStatus",
        "getUserChatBoosts",
        "getUserGifts",
        "getChatGifts",
        "getBusinessConnection",
        "getFile",
        "kickChatMember",
        "banChatMember",
        "unbanChatMember",
        "restrictChatMember",
        "promoteChatMember",
        "setChatAdministratorCustomTitle",
        "setChatMemberTag",
        "banChatSenderChat",
        "unbanChatSenderChat",
        "setChatPermissions",
        "exportChatInviteLink",
        "createChatInviteLink",
        "editChatInviteLink",
        "createChatSubscriptionInviteLink",
        "editChatSubscriptionInviteLink",
        "revokeChatInviteLink",
        "getManagedBotToken",
        "replaceManagedBotToken",
        "approveChatJoinRequest",
        "declineChatJoinRequest",
        "approveSuggestedPost",
        "declineSuggestedPost",
        "setChatPhoto",
        "deleteChatPhoto",
        "setChatTitle",
        "setChatDescription",
        "pinChatMessage",
        "unpinChatMessage",
        "unpinAllChatMessages",
        "leaveChat",
        "getChat",
        "getChatAdministrators",
        "getChatMembersCount",
        "getChatMemberCount",
        "getChatMember",
        "setChatStickerSet",
        "deleteChatStickerSet",
        "getForumTopicIconStickers",
        "createForumTopic",
        "editForumTopic",
        "closeForumTopic",
        "reopenForumTopic",
        "deleteForumTopic",
        "unpinAllForumTopicMessages",
        "editGeneralForumTopic",
        "closeGeneralForumTopic",
        "reopenGeneralForumTopic",
        "hideGeneralForumTopic",
        "unhideGeneralForumTopic",
        "unpinAllGeneralForumTopicMessages",
        "answerCallbackQuery",
        "setMyName",
        "getMyName",
        "setMyCommands",
        "deleteMyCommands",
        "getMyCommands",
        "setMyDescription",
        "getMyDescription",
        "setMyShortDescription",
        "getMyShortDescription",
        "setMyProfilePhoto",
        "removeMyProfilePhoto",
        "setChatMenuButton",
        "getChatMenuButton",
        "setMyDefaultAdministratorRights",
        "getMyDefaultAdministratorRights",
        "getMyStarBalance",
        "editMessageText",
        "editMessageTextInline",
        "editMessageCaption",
        "editMessageCaptionInline",
        "editMessageMedia",
        "editMessageMediaInline",
        "editMessageReplyMarkup",
        "editMessageReplyMarkupInline",
        "stopPoll",
        "deleteMessage",
        "deleteMessages",
        "deleteBusinessMessages",
        "setBusinessAccountName",
        "setBusinessAccountUsername",
        "setBusinessAccountBio",
        "setBusinessAccountProfilePhoto",
        "removeBusinessAccountProfilePhoto",
        "setBusinessAccountGiftSettings",
        "getBusinessAccountStarBalance",
        "transferBusinessAccountStars",
        "getBusinessAccountGifts",
        "convertGiftToStars",
        "upgradeGift",
        "transferGift",
        "postStory",
        "repostStory",
        "editStory",
        "deleteStory",
        "sendSticker",
        "getStickerSet",
        "getCustomEmojiStickers",
        "uploadStickerFile",
        "createNewStickerSet",
        "addStickerToSet",
        "setStickerPositionInSet",
        "deleteStickerFromSet",
        "replaceStickerInSet",
        "setStickerEmojiList",
        "setStickerKeywords",
        "setStickerMaskPosition",
        "setStickerSetTitle",
        "deleteStickerSet",
        "setStickerSetThumbnail",
        "setCustomEmojiStickerSetThumbnail",
        "getAvailableGifts",
        "sendGift",
        "giftPremiumSubscription",
        "sendGiftToChannel",
        "answerInlineQuery",
        "answerWebAppQuery",
        "savePreparedInlineMessage",
        "savePreparedKeyboardButton",
        "sendInvoice",
        "createInvoiceLink",
        "answerShippingQuery",
        "answerPreCheckoutQuery",
        "getStarTransactions",
        "refundStarPayment",
        "editUserStarSubscription",
        "verifyUser",
        "verifyChat",
        "removeUserVerification",
        "removeChatVerification",
        "readBusinessMessage",
        "setPassportDataErrors",
        "sendGame",
        "setGameScore",
        "setGameScoreInline",
        "getGameHighScores",
        "getGameHighScoresInline"
    ]
}

public func apiWrapperCount(): Int64 {
    apiWrapperMethodNames().size
}

public func apiRawFacadeMethodNames(): Array<String> {
    apiWrapperMethodNames()
}

public func apiRawFacadeCount(): Int64 {
    apiRawFacadeMethodNames().size
}

public func apiRawZeroArgMethodNames(): Array<String> {
    [
        "getMe",
        "getWebhookInfo",
        "getForumTopicIconStickers",
        "getAvailableGifts",
        "logOut",
        "close",
        "getMyStarBalance",
        "removeMyProfilePhoto"
    ]
}

private func hasTraceFlag(flags: String, flag: String): Bool {
    ("," + flags + ",").contains("," + flag + ",")
}

private func traceFieldCount(fields: String): Int64 {
    if (fields == "") {
        return 0
    }
    fields.split(",").size
}

private func containsTraceField(fields: String, field: String): Bool {
    ("," + fields + ",").contains("," + field + ",")
}

private func joinTraceFields(fields: ArrayList<String>): String {
    var out = ""
    var first = true
    for (field in fields) {
        if (!first) {
            out += ","
        }
        out += field
        first = false
    }
    out
}

private func concatTraceFields(left: String, right: String): String {
    if (left == "") {
        return right
    }
    if (right == "") {
        return left
    }
    left + "," + right
}

private func optionalArgumentTraceFor(publicMethodName: String): String {
    if (publicMethodName == "setChatDescription") {
        return "description"
    }
    if (publicMethodName == "unpinChatMessage") {
        return "message_id"
    }
    if (publicMethodName == "setStickerMaskPosition") {
        return "mask_position"
    }
    ""
}

private func removeOptionalArguments(pulledPayloadFieldTrace: String, optionalArgumentTrace: String): String {
    if (pulledPayloadFieldTrace == "" || optionalArgumentTrace == "") {
        return pulledPayloadFieldTrace
    }
    let fields = ArrayList<String>()
    for (field in pulledPayloadFieldTrace.split(",")) {
        if (field != "" && !containsTraceField(optionalArgumentTrace, field)) {
            fields.add(field)
        }
    }
    joinTraceFields(fields)
}

public class ApiWrapperSchemaTrace {
    public let publicMethodName: String
    public let rawMethodName: String
    public let pulledPayloadFieldTrace: String
    public let requiredPayloadFieldTrace: String
    public let optionalPayloadFieldTrace: String
    public let returnTypeTrace: String
    public let aliasOf: String
    public let flags: String
    public let isInlineVariant: Bool
    public let isAlias: Bool
    public let isRawVariant: Bool
    public let isZeroArgRaw: Bool

    public init(row: String) {
        let parts = row.split("~")
        this.publicMethodName = parts[0]
        this.rawMethodName = parts[1]
        this.pulledPayloadFieldTrace = parts[2]
        this.requiredPayloadFieldTrace = parts[3]
        this.optionalPayloadFieldTrace = parts[4]
        this.returnTypeTrace = parts[5]
        this.aliasOf = parts[6]
        this.flags = parts[7]
        this.isInlineVariant = hasTraceFlag(this.flags, "inline")
        this.isAlias = hasTraceFlag(this.flags, "alias")
        this.isRawVariant = hasTraceFlag(this.flags, "raw_variant")
        this.isZeroArgRaw = hasTraceFlag(this.flags, "zero")
    }

    public func hasPayloadField(field: String): Bool {
        ("," + this.requiredPayloadFieldTrace + ",").contains("," + field + ",") ||
            ("," + this.optionalPayloadFieldTrace + ",").contains("," + field + ",")
    }

    public func payloadFieldTrace(): String {
        concatTraceFields(this.requiredPayloadFieldTrace, this.optionalPayloadFieldTrace)
    }

    public func requiredPayloadFieldCount(): Int64 {
        traceFieldCount(this.requiredPayloadFieldTrace)
    }

    public func optionalPayloadFieldCount(): Int64 {
        traceFieldCount(this.optionalPayloadFieldTrace)
    }
}

public class ApiWrapperSignatureTrace {
    public let publicMethodName: String
    public let rawMethodName: String
    public let requiredParameterTrace: String
    public let optionalParameterTrace: String
    public let otherPayloadFieldTrace: String
    public let signalTrace: String
    public let cancelTrace: String
    public let requiredPayloadFieldTrace: String
    public let optionalPayloadFieldTrace: String
    public let payloadFieldTrace: String
    public let returnTypeTrace: String
    public let flags: String

    public init(schema: ApiWrapperSchemaTrace) {
        this.publicMethodName = schema.publicMethodName
        this.rawMethodName = schema.rawMethodName
        this.optionalParameterTrace = optionalArgumentTraceFor(schema.publicMethodName)
        this.requiredParameterTrace = removeOptionalArguments(
            schema.pulledPayloadFieldTrace,
            this.optionalParameterTrace
        )
        this.otherPayloadFieldTrace = schema.optionalPayloadFieldTrace
        this.signalTrace = "AbortSignal"
        this.cancelTrace = "CancelSignal"
        this.requiredPayloadFieldTrace = schema.requiredPayloadFieldTrace
        this.optionalPayloadFieldTrace = schema.optionalPayloadFieldTrace
        this.payloadFieldTrace = schema.payloadFieldTrace()
        this.returnTypeTrace = schema.returnTypeTrace
        this.flags = schema.flags
    }

    public func requiredParameterCount(): Int64 {
        traceFieldCount(this.requiredParameterTrace)
    }

    public func optionalParameterCount(): Int64 {
        traceFieldCount(this.optionalParameterTrace)
    }

    public func hasRequiredParameter(field: String): Bool {
        containsTraceField(this.requiredParameterTrace, field)
    }
}

public func apiWrapperSchemaTraceRows(): Array<String> {
    [
        "getUpdates~getUpdates~~~offset,limit,timeout,allowed_updates~Update[]~~",
        "setWebhook~setWebhook~url~url~certificate,ip_address,max_connections,allowed_updates,drop_pending_updates,secret_token~true~~",
        "deleteWebhook~deleteWebhook~~~drop_pending_updates~true~~",
        "getWebhookInfo~getWebhookInfo~~~~WebhookInfo~~zero",
        "getMe~getMe~~~~UserFromGetMe~~zero",
        "logOut~logOut~~~~true~~zero",
        "close~close~~~~true~~zero",
        "sendMessage~sendMessage~chat_id,text~chat_id,text~business_connection_id,message_thread_id,direct_messages_topic_id,parse_mode,entities,link_preview_options,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.TextMessage~~",
        "sendMessageDraft~sendMessageDraft~chat_id,draft_id,text~chat_id,draft_id,text~message_thread_id,parse_mode,entities~true~~",
        "forwardMessage~forwardMessage~chat_id,from_chat_id,message_id~chat_id,from_chat_id,message_id~message_thread_id,direct_messages_topic_id,video_start_timestamp,message_effect_id,suggested_post_parameters,disable_notification,protect_content~Message~~",
        "forwardMessages~forwardMessages~chat_id,from_chat_id,message_ids~chat_id,from_chat_id,message_ids~message_thread_id,direct_messages_topic_id,disable_notification,protect_content~MessageId[]~~",
        "copyMessage~copyMessage~chat_id,from_chat_id,message_id~chat_id,from_chat_id,message_id~message_thread_id,direct_messages_topic_id,video_start_timestamp,caption,parse_mode,caption_entities,show_caption_above_media,disable_notification,protect_content,allow_paid_broadcast,message_effect_id,suggested_post_parameters,reply_parameters,reply_markup,reply_to_message_id~MessageId~~",
        "copyMessages~copyMessages~chat_id,from_chat_id,message_ids~chat_id,from_chat_id,message_ids~message_thread_id,direct_messages_topic_id,disable_notification,protect_content,remove_caption~MessageId[]~~",
        "sendPhoto~sendPhoto~chat_id,photo~chat_id,photo~business_connection_id,message_thread_id,direct_messages_topic_id,caption,parse_mode,caption_entities,show_caption_above_media,has_spoiler,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.PhotoMessage~~",
        "sendAudio~sendAudio~chat_id,audio~chat_id,audio~business_connection_id,message_thread_id,direct_messages_topic_id,caption,parse_mode,caption_entities,duration,performer,title,thumbnail,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.AudioMessage~~",
        "sendDocument~sendDocument~chat_id,document~chat_id,document~business_connection_id,message_thread_id,direct_messages_topic_id,thumbnail,caption,parse_mode,caption_entities,disable_content_type_detection,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.DocumentMessage~~",
        "sendVideo~sendVideo~chat_id,video~chat_id,video~business_connection_id,message_thread_id,direct_messages_topic_id,duration,width,height,thumbnail,cover,start_timestamp,caption,parse_mode,caption_entities,show_caption_above_media,has_spoiler,supports_streaming,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.VideoMessage~~",
        "sendAnimation~sendAnimation~chat_id,animation~chat_id,animation~business_connection_id,message_thread_id,direct_messages_topic_id,duration,width,height,thumbnail,caption,parse_mode,caption_entities,show_caption_above_media,has_spoiler,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.AnimationMessage~~",
        "sendVoice~sendVoice~chat_id,voice~chat_id,voice~business_connection_id,message_thread_id,direct_messages_topic_id,caption,parse_mode,caption_entities,duration,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.VoiceMessage~~",
        "sendVideoNote~sendVideoNote~chat_id,video_note~chat_id,video_note~business_connection_id,message_thread_id,direct_messages_topic_id,duration,length,thumbnail,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.VideoNoteMessage~~",
        "sendMediaGroup~sendMediaGroup~chat_id,media~chat_id,media~business_connection_id,message_thread_id,direct_messages_topic_id,disable_notification,protect_content,allow_paid_broadcast,message_effect_id,reply_parameters,reply_to_message_id~Array< | Message.AudioMessage | Message.DocumentMessage | Message.PhotoMessage | Message.VideoMessage >~~",
        "sendLocation~sendLocation~chat_id,latitude,longitude~chat_id,latitude,longitude~business_connection_id,message_thread_id,direct_messages_topic_id,horizontal_accuracy,live_period,heading,proximity_alert_radius,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.LocationMessage~~",
        "editMessageLiveLocation~editMessageLiveLocation~chat_id,message_id,latitude,longitude~latitude,longitude~business_connection_id,chat_id,message_id,inline_message_id,live_period,horizontal_accuracy,heading,proximity_alert_radius,reply_markup~(Update.Edited & Message.LocationMessage) | true~~",
        "editMessageLiveLocationInline~editMessageLiveLocation~inline_message_id,latitude,longitude~latitude,longitude~business_connection_id,chat_id,message_id,inline_message_id,live_period,horizontal_accuracy,heading,proximity_alert_radius,reply_markup~(Update.Edited & Message.LocationMessage) | true~~raw_variant,inline",
        "stopMessageLiveLocation~stopMessageLiveLocation~chat_id,message_id~~business_connection_id,chat_id,message_id,inline_message_id,reply_markup~(Update.Edited & Message.LocationMessage) | true~~",
        "stopMessageLiveLocationInline~stopMessageLiveLocation~inline_message_id~~business_connection_id,chat_id,message_id,inline_message_id,reply_markup~(Update.Edited & Message.LocationMessage) | true~~raw_variant,inline",
        "sendPaidMedia~sendPaidMedia~chat_id,star_count,media~chat_id,star_count,media~business_connection_id,message_thread_id,direct_messages_topic_id,payload,caption,parse_mode,caption_entities,show_caption_above_media,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,reply_parameters,reply_markup~Message.PaidMediaMessage~~",
        "sendVenue~sendVenue~chat_id,latitude,longitude,title,address~chat_id,latitude,longitude,title,address~business_connection_id,message_thread_id,direct_messages_topic_id,foursquare_id,foursquare_type,google_place_id,google_place_type,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.VenueMessage~~",
        "sendContact~sendContact~chat_id,phone_number,first_name~chat_id,phone_number,first_name~business_connection_id,message_thread_id,direct_messages_topic_id,last_name,vcard,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.ContactMessage~~",
        "sendPoll~sendPoll~chat_id,question,options~chat_id,question,options~business_connection_id,message_thread_id,question_parse_mode,question_entities,is_anonymous,type,allows_multiple_answers,allows_revoting,shuffle_options,allow_adding_options,hide_results_until_closes,correct_option_ids,explanation,explanation_parse_mode,explanation_entities,description,description_parse_mode,description_entities,open_period,close_date,is_closed,disable_notification,protect_content,allow_paid_broadcast,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.PollMessage~~",
        "sendChecklist~sendChecklist~business_connection_id,chat_id,checklist~business_connection_id,chat_id,checklist~disable_notification,protect_content,message_effect_id,reply_parameters,reply_markup~Message.ChecklistMessage~~",
        "editMessageChecklist~editMessageChecklist~business_connection_id,chat_id,message_id,checklist~business_connection_id,chat_id,message_id,checklist~reply_markup~Message.ChecklistMessage~~",
        "sendDice~sendDice~chat_id,emoji~chat_id~business_connection_id,message_thread_id,direct_messages_topic_id,emoji,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.DiceMessage~~",
        "setMessageReaction~setMessageReaction~chat_id,message_id,reaction~chat_id,message_id~reaction,is_big~true~~",
        "sendChatAction~sendChatAction~chat_id,action~chat_id,action~business_connection_id,message_thread_id~true~~",
        "getUserProfilePhotos~getUserProfilePhotos~user_id~user_id~offset,limit~UserProfilePhotos~~",
        "getUserProfileAudios~getUserProfileAudios~user_id~user_id~offset,limit~UserProfileAudios~~",
        "setUserEmojiStatus~setUserEmojiStatus~user_id~user_id~emoji_status_custom_emoji_id,emoji_status_expiration_date~true~~",
        "getUserChatBoosts~getUserChatBoosts~chat_id,user_id~chat_id,user_id~~UserChatBoosts~~",
        "getUserGifts~getUserGifts~user_id~user_id~exclude_unlimited,exclude_limited_upgradable,exclude_limited_non_upgradable,exclude_from_blockchain,exclude_unique,sort_by_price,offset,limit~OwnedGifts~~",
        "getChatGifts~getChatGifts~chat_id~chat_id~exclude_unsaved,exclude_saved,exclude_unlimited,exclude_limited_upgradable,exclude_limited_non_upgradable,exclude_from_blockchain,exclude_unique,sort_by_price,offset,limit~OwnedGifts~~",
        "getBusinessConnection~getBusinessConnection~business_connection_id~business_connection_id~~BusinessConnection~~",
        "getFile~getFile~file_id~file_id~~File~~",
        "kickChatMember~banChatMember~chat_id,user_id~chat_id,user_id~until_date,revoke_messages~true~banChatMember~alias",
        "banChatMember~banChatMember~chat_id,user_id~chat_id,user_id~until_date,revoke_messages~true~~",
        "unbanChatMember~unbanChatMember~chat_id,user_id~chat_id,user_id~only_if_banned~true~~",
        "restrictChatMember~restrictChatMember~chat_id,user_id,permissions~chat_id,user_id,permissions~use_independent_chat_permissions,until_date~true~~",
        "promoteChatMember~promoteChatMember~chat_id,user_id~chat_id,user_id~is_anonymous,can_manage_chat,can_delete_messages,can_manage_video_chats,can_restrict_members,can_promote_members,can_change_info,can_invite_users,can_manage_tags,can_post_stories,can_edit_stories,can_delete_stories,can_post_messages,can_edit_messages,can_pin_messages,can_manage_topics,can_manage_direct_messages~true~~",
        "setChatAdministratorCustomTitle~setChatAdministratorCustomTitle~chat_id,user_id,custom_title~chat_id,user_id,custom_title~~true~~",
        "setChatMemberTag~setChatMemberTag~chat_id,user_id,tag~chat_id,user_id~tag~true~~",
        "banChatSenderChat~banChatSenderChat~chat_id,sender_chat_id~chat_id,sender_chat_id~~true~~",
        "unbanChatSenderChat~unbanChatSenderChat~chat_id,sender_chat_id~chat_id,sender_chat_id~~true~~",
        "setChatPermissions~setChatPermissions~chat_id,permissions~chat_id,permissions~use_independent_chat_permissions~true~~",
        "exportChatInviteLink~exportChatInviteLink~chat_id~chat_id~~string~~",
        "createChatInviteLink~createChatInviteLink~chat_id~chat_id~name,expire_date,member_limit,creates_join_request~ChatInviteLink~~",
        "editChatInviteLink~editChatInviteLink~chat_id,invite_link~chat_id,invite_link~name,expire_date,member_limit,creates_join_request~ChatInviteLink~~",
        "createChatSubscriptionInviteLink~createChatSubscriptionInviteLink~chat_id,subscription_period,subscription_price~chat_id,subscription_period,subscription_price~name~ChatInviteLink~~",
        "editChatSubscriptionInviteLink~editChatSubscriptionInviteLink~chat_id,invite_link~chat_id,invite_link~name~ChatInviteLink~~",
        "revokeChatInviteLink~revokeChatInviteLink~chat_id,invite_link~chat_id,invite_link~~ChatInviteLink~~",
        "getManagedBotToken~getManagedBotToken~user_id~user_id~~string~~",
        "replaceManagedBotToken~replaceManagedBotToken~user_id~user_id~~string~~",
        "approveChatJoinRequest~approveChatJoinRequest~chat_id,user_id~chat_id,user_id~~true~~",
        "declineChatJoinRequest~declineChatJoinRequest~chat_id,user_id~chat_id,user_id~~true~~",
        "approveSuggestedPost~approveSuggestedPost~chat_id,message_id~chat_id,message_id~send_date~true~~",
        "declineSuggestedPost~declineSuggestedPost~chat_id,message_id~chat_id,message_id~comment~true~~",
        "setChatPhoto~setChatPhoto~chat_id,photo~chat_id,photo~~true~~",
        "deleteChatPhoto~deleteChatPhoto~chat_id~chat_id~~true~~",
        "setChatTitle~setChatTitle~chat_id,title~chat_id,title~~true~~",
        "setChatDescription~setChatDescription~chat_id,description~chat_id~description~true~~",
        "pinChatMessage~pinChatMessage~chat_id,message_id~chat_id,message_id~business_connection_id,disable_notification~true~~",
        "unpinChatMessage~unpinChatMessage~chat_id,message_id~chat_id~business_connection_id,message_id~true~~",
        "unpinAllChatMessages~unpinAllChatMessages~chat_id~chat_id~~true~~",
        "leaveChat~leaveChat~chat_id~chat_id~~true~~",
        "getChat~getChat~chat_id~chat_id~~ChatFullInfo~~",
        "getChatAdministrators~getChatAdministrators~chat_id~chat_id~~Array<ChatMemberOwner | ChatMemberAdministrator>~~",
        "getChatMembersCount~getChatMemberCount~chat_id~chat_id~~number~getChatMemberCount~alias",
        "getChatMemberCount~getChatMemberCount~chat_id~chat_id~~number~~",
        "getChatMember~getChatMember~chat_id,user_id~chat_id,user_id~~ChatMember~~",
        "setChatStickerSet~setChatStickerSet~chat_id,sticker_set_name~chat_id,sticker_set_name~~true~~",
        "deleteChatStickerSet~deleteChatStickerSet~chat_id~chat_id~~true~~",
        "getForumTopicIconStickers~getForumTopicIconStickers~~~~Sticker[]~~zero",
        "createForumTopic~createForumTopic~chat_id,name~chat_id,name~icon_color,icon_custom_emoji_id~ForumTopic~~",
        "editForumTopic~editForumTopic~chat_id,message_thread_id~chat_id,message_thread_id~name,icon_custom_emoji_id~true~~",
        "closeForumTopic~closeForumTopic~chat_id,message_thread_id~chat_id,message_thread_id~~true~~",
        "reopenForumTopic~reopenForumTopic~chat_id,message_thread_id~chat_id,message_thread_id~~true~~",
        "deleteForumTopic~deleteForumTopic~chat_id,message_thread_id~chat_id,message_thread_id~~true~~",
        "unpinAllForumTopicMessages~unpinAllForumTopicMessages~chat_id,message_thread_id~chat_id,message_thread_id~~true~~",
        "editGeneralForumTopic~editGeneralForumTopic~chat_id,name~chat_id,name~~true~~",
        "closeGeneralForumTopic~closeGeneralForumTopic~chat_id~chat_id~~true~~",
        "reopenGeneralForumTopic~reopenGeneralForumTopic~chat_id~chat_id~~true~~",
        "hideGeneralForumTopic~hideGeneralForumTopic~chat_id~chat_id~~true~~",
        "unhideGeneralForumTopic~unhideGeneralForumTopic~chat_id~chat_id~~true~~",
        "unpinAllGeneralForumTopicMessages~unpinAllGeneralForumTopicMessages~chat_id~chat_id~~true~~",
        "answerCallbackQuery~answerCallbackQuery~callback_query_id~callback_query_id~text,show_alert,url,cache_time~true~~",
        "setMyName~setMyName~name~~name,language_code~true~~",
        "getMyName~getMyName~~~language_code~BotName~~",
        "setMyCommands~setMyCommands~commands~commands~scope,language_code~true~~",
        "deleteMyCommands~deleteMyCommands~~~scope,language_code~true~~",
        "getMyCommands~getMyCommands~~~scope,language_code~BotCommand[]~~",
        "setMyDescription~setMyDescription~description~~description,language_code~true~~",
        "getMyDescription~getMyDescription~~~language_code~BotDescription~~",
        "setMyShortDescription~setMyShortDescription~short_description~~short_description,language_code~true~~",
        "getMyShortDescription~getMyShortDescription~~~language_code~BotShortDescription~~",
        "setMyProfilePhoto~setMyProfilePhoto~photo~photo~~true~~",
        "removeMyProfilePhoto~removeMyProfilePhoto~~~~true~~zero",
        "setChatMenuButton~setChatMenuButton~~~chat_id,menu_button~true~~",
        "getChatMenuButton~getChatMenuButton~~~chat_id~MenuButton~~",
        "setMyDefaultAdministratorRights~setMyDefaultAdministratorRights~~~rights,for_channels~true~~",
        "getMyDefaultAdministratorRights~getMyDefaultAdministratorRights~~~for_channels~ChatAdministratorRights~~",
        "getMyStarBalance~getMyStarBalance~~~~StarAmount~~zero",
        "editMessageText~editMessageText~chat_id,message_id,text~text~business_connection_id,chat_id,message_id,inline_message_id,parse_mode,entities,link_preview_options,reply_markup~(Update.Edited & Message.TextMessage) | true~~",
        "editMessageTextInline~editMessageText~inline_message_id,text~text~business_connection_id,chat_id,message_id,inline_message_id,parse_mode,entities,link_preview_options,reply_markup~(Update.Edited & Message.TextMessage) | true~~raw_variant,inline",
        "editMessageCaption~editMessageCaption~chat_id,message_id~~business_connection_id,chat_id,message_id,inline_message_id,caption,parse_mode,caption_entities,show_caption_above_media,reply_markup~(Update.Edited & Message.CaptionableMessage) | true~~",
        "editMessageCaptionInline~editMessageCaption~inline_message_id~~business_connection_id,chat_id,message_id,inline_message_id,caption,parse_mode,caption_entities,show_caption_above_media,reply_markup~(Update.Edited & Message.CaptionableMessage) | true~~raw_variant,inline",
        "editMessageMedia~editMessageMedia~chat_id,message_id,media~media~business_connection_id,chat_id,message_id,inline_message_id,reply_markup~(Update.Edited & Message) | true~~",
        "editMessageMediaInline~editMessageMedia~inline_message_id,media~media~business_connection_id,chat_id,message_id,inline_message_id,reply_markup~(Update.Edited & Message) | true~~raw_variant,inline",
        "editMessageReplyMarkup~editMessageReplyMarkup~chat_id,message_id~~business_connection_id,chat_id,message_id,inline_message_id,reply_markup~(Update.Edited & Message) | true~~",
        "editMessageReplyMarkupInline~editMessageReplyMarkup~inline_message_id~~business_connection_id,chat_id,message_id,inline_message_id,reply_markup~(Update.Edited & Message) | true~~raw_variant,inline",
        "stopPoll~stopPoll~chat_id,message_id~chat_id,message_id~business_connection_id,reply_markup~Poll~~",
        "deleteMessage~deleteMessage~chat_id,message_id~chat_id,message_id~~true~~",
        "deleteMessages~deleteMessages~chat_id,message_ids~chat_id,message_ids~~true~~",
        "deleteBusinessMessages~deleteBusinessMessages~business_connection_id,message_ids~business_connection_id,message_ids~~true~~",
        "setBusinessAccountName~setBusinessAccountName~business_connection_id,first_name~business_connection_id,first_name~last_name~true~~",
        "setBusinessAccountUsername~setBusinessAccountUsername~business_connection_id,username~business_connection_id~username~true~~",
        "setBusinessAccountBio~setBusinessAccountBio~business_connection_id,bio~business_connection_id~bio~true~~",
        "setBusinessAccountProfilePhoto~setBusinessAccountProfilePhoto~business_connection_id,photo~business_connection_id,photo~is_public~true~~",
        "removeBusinessAccountProfilePhoto~removeBusinessAccountProfilePhoto~business_connection_id~business_connection_id~is_public~true~~",
        "setBusinessAccountGiftSettings~setBusinessAccountGiftSettings~business_connection_id,show_gift_button,accepted_gift_types~business_connection_id,show_gift_button,accepted_gift_types~~true~~",
        "getBusinessAccountStarBalance~getBusinessAccountStarBalance~business_connection_id~business_connection_id~~StarAmount~~",
        "transferBusinessAccountStars~transferBusinessAccountStars~business_connection_id,star_count~business_connection_id,star_count~~true~~",
        "getBusinessAccountGifts~getBusinessAccountGifts~business_connection_id~business_connection_id~exclude_unsaved,exclude_saved,exclude_unlimited,exclude_limited_upgradable,exclude_limited_non_upgradable,exclude_from_blockchain,exclude_unique,sort_by_price,offset,limit~OwnedGifts~~",
        "convertGiftToStars~convertGiftToStars~business_connection_id,owned_gift_id~business_connection_id,owned_gift_id~~true~~",
        "upgradeGift~upgradeGift~business_connection_id,owned_gift_id~business_connection_id,owned_gift_id~keep_original_details,star_count~true~~",
        "transferGift~transferGift~business_connection_id,owned_gift_id,new_owner_chat_id,star_count~business_connection_id,owned_gift_id,new_owner_chat_id,star_count~~true~~",
        "postStory~postStory~business_connection_id,content,active_period~business_connection_id,content,active_period~caption,parse_mode,caption_entities,areas,post_to_chat_page,protect_content~Story~~",
        "repostStory~repostStory~business_connection_id,from_chat_id,from_story_id,active_period~business_connection_id,from_chat_id,from_story_id,active_period~post_to_chat_page,protect_content~Story~~",
        "editStory~editStory~business_connection_id,story_id,content~business_connection_id,story_id,content~caption,parse_mode,caption_entities,areas~Story~~",
        "deleteStory~deleteStory~business_connection_id,story_id~business_connection_id,story_id~~true~~",
        "sendSticker~sendSticker~chat_id,sticker~chat_id,sticker~business_connection_id,message_thread_id,direct_messages_topic_id,emoji,disable_notification,protect_content,allow_paid_broadcast,suggested_post_parameters,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.StickerMessage~~",
        "getStickerSet~getStickerSet~name~name~~StickerSet~~",
        "getCustomEmojiStickers~getCustomEmojiStickers~custom_emoji_ids~custom_emoji_ids~~Sticker[]~~",
        "uploadStickerFile~uploadStickerFile~user_id,sticker_format,sticker~user_id,sticker_format,sticker~~File~~",
        "createNewStickerSet~createNewStickerSet~user_id,name,title,stickers~user_id,name,title,stickers~sticker_type,needs_repainting~true~~",
        "addStickerToSet~addStickerToSet~user_id,name,sticker~user_id,name,sticker~~true~~",
        "setStickerPositionInSet~setStickerPositionInSet~sticker,position~sticker,position~~true~~",
        "deleteStickerFromSet~deleteStickerFromSet~sticker~sticker~~true~~",
        "replaceStickerInSet~replaceStickerInSet~user_id,name,old_sticker,sticker~user_id,name,old_sticker,sticker~~true~~",
        "setStickerEmojiList~setStickerEmojiList~sticker,emoji_list~sticker,emoji_list~~true~~",
        "setStickerKeywords~setStickerKeywords~sticker,keywords~sticker~keywords~true~~",
        "setStickerMaskPosition~setStickerMaskPosition~sticker,mask_position~sticker~mask_position~true~~",
        "setStickerSetTitle~setStickerSetTitle~name,title~name,title~~true~~",
        "deleteStickerSet~deleteStickerSet~name~name~~true~~",
        "setStickerSetThumbnail~setStickerSetThumbnail~name,user_id,thumbnail,format~name,user_id,format~thumbnail~true~~",
        "setCustomEmojiStickerSetThumbnail~setCustomEmojiStickerSetThumbnail~name,custom_emoji_id~name~custom_emoji_id~true~~",
        "getAvailableGifts~getAvailableGifts~~~~Gifts~~zero",
        "sendGift~sendGift~user_id,gift_id~gift_id~user_id,chat_id,pay_for_upgrade,text,text_parse_mode,text_entities~true~~",
        "giftPremiumSubscription~giftPremiumSubscription~user_id,month_count,star_count~user_id,month_count,star_count~text,text_parse_mode,text_entities~true~~",
        "sendGiftToChannel~sendGift~chat_id,gift_id~gift_id~user_id,chat_id,pay_for_upgrade,text,text_parse_mode,text_entities~true~~raw_variant",
        "answerInlineQuery~answerInlineQuery~inline_query_id,results~inline_query_id,results~cache_time,is_personal,next_offset,button~true~~",
        "answerWebAppQuery~answerWebAppQuery~web_app_query_id,result~web_app_query_id,result~~SentWebAppMessage~~",
        "savePreparedInlineMessage~savePreparedInlineMessage~user_id,result~user_id,result~allow_user_chats,allow_bot_chats,allow_group_chats,allow_channel_chats~PreparedInlineMessage~~",
        "savePreparedKeyboardButton~savePreparedKeyboardButton~user_id,button~user_id,button~~PreparedKeyboardButton~~",
        "sendInvoice~sendInvoice~chat_id,title,description,payload,currency,prices~chat_id,title,description,payload,currency,prices~message_thread_id,direct_messages_topic_id,provider_token,max_tip_amount,suggested_tip_amounts,start_parameter,provider_data,photo_url,photo_size,photo_width,photo_height,need_name,need_phone_number,need_email,need_shipping_address,send_phone_number_to_provider,send_email_to_provider,is_flexible,suggested_post_parameters,disable_notification,protect_content,allow_paid_broadcast,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.InvoiceMessage~~",
        "createInvoiceLink~createInvoiceLink~title,description,payload,provider_token,currency,prices~title,description,payload,currency,prices~business_connection_id,provider_token,subscription_period,max_tip_amount,suggested_tip_amounts,provider_data,photo_url,photo_size,photo_width,photo_height,need_name,need_phone_number,need_email,need_shipping_address,send_phone_number_to_provider,send_email_to_provider,is_flexible~string~~",
        "answerShippingQuery~answerShippingQuery~shipping_query_id,ok~shipping_query_id,ok~shipping_options,error_message~true~~",
        "answerPreCheckoutQuery~answerPreCheckoutQuery~pre_checkout_query_id,ok~pre_checkout_query_id,ok~error_message~true~~",
        "getStarTransactions~getStarTransactions~~~offset,limit~StarTransactions~~",
        "refundStarPayment~refundStarPayment~user_id,telegram_payment_charge_id~user_id,telegram_payment_charge_id~~true~~",
        "editUserStarSubscription~editUserStarSubscription~user_id,telegram_payment_charge_id,is_canceled~user_id,telegram_payment_charge_id,is_canceled~~true~~",
        "verifyUser~verifyUser~user_id~user_id~custom_description~true~~",
        "verifyChat~verifyChat~chat_id~chat_id~custom_description~true~~",
        "removeUserVerification~removeUserVerification~user_id~user_id~~true~~",
        "removeChatVerification~removeChatVerification~chat_id~chat_id~~true~~",
        "readBusinessMessage~readBusinessMessage~business_connection_id,chat_id,message_id~business_connection_id,chat_id,message_id~~true~~",
        "setPassportDataErrors~setPassportDataErrors~user_id,errors~user_id,errors~~true~~",
        "sendGame~sendGame~chat_id,game_short_name~chat_id,game_short_name~business_connection_id,message_thread_id,disable_notification,protect_content,allow_paid_broadcast,message_effect_id,reply_parameters,reply_markup,reply_to_message_id~Message.GameMessage~~",
        "setGameScore~setGameScore~chat_id,message_id,user_id,score~user_id,score~force,disable_edit_message,chat_id,message_id,inline_message_id~(Update.Edited & Message.GameMessage) | true~~",
        "setGameScoreInline~setGameScore~inline_message_id,user_id,score~user_id,score~force,disable_edit_message,chat_id,message_id,inline_message_id~(Update.Edited & Message.GameMessage) | true~~raw_variant,inline",
        "getGameHighScores~getGameHighScores~chat_id,message_id,user_id~user_id~chat_id,message_id,inline_message_id~GameHighScore[]~~",
        "getGameHighScoresInline~getGameHighScores~inline_message_id,user_id~user_id~chat_id,message_id,inline_message_id~GameHighScore[]~~raw_variant,inline"
    ]
}

public func apiWrapperSchemaTraces(): ArrayList<ApiWrapperSchemaTrace> {
    let traces = ArrayList<ApiWrapperSchemaTrace>()
    for (row in apiWrapperSchemaTraceRows()) {
        traces.add(ApiWrapperSchemaTrace(row))
    }
    traces
}

public func apiWrapperSchemaTraceCount(): Int64 {
    apiWrapperSchemaTraceRows().size
}

public func apiWrapperSchemaTraceFor(publicMethodName: String): ApiWrapperSchemaTrace {
    for (trace in apiWrapperSchemaTraces()) {
        if (trace.publicMethodName == publicMethodName) {
            return trace
        }
    }
    throw Exception("No API wrapper schema trace for " + publicMethodName)
}

public func apiWrapperSignatureTraces(): ArrayList<ApiWrapperSignatureTrace> {
    let traces = ArrayList<ApiWrapperSignatureTrace>()
    for (schema in apiWrapperSchemaTraces()) {
        traces.add(ApiWrapperSignatureTrace(schema))
    }
    traces
}

public func apiWrapperSignatureTraceCount(): Int64 {
    apiWrapperSignatureTraces().size
}

public func apiWrapperSignatureTraceFor(publicMethodName: String): ApiWrapperSignatureTrace {
    for (trace in apiWrapperSignatureTraces()) {
        if (trace.publicMethodName == publicMethodName) {
            return trace
        }
    }
    throw Exception("No API wrapper signature trace for " + publicMethodName)
}

public func apiWrapperRequiredParameterTotal(): Int64 {
    var total = 0
    for (trace in apiWrapperSignatureTraces()) {
        total += trace.requiredParameterCount()
    }
    total
}

public func apiWrapperOptionalParameterTotal(): Int64 {
    var total = 0
    for (trace in apiWrapperSignatureTraces()) {
        total += trace.optionalParameterCount()
    }
    total
}

public func apiWrapperRequiredPayloadFieldTotal(): Int64 {
    var total = 0
    for (trace in apiWrapperSchemaTraces()) {
        total += trace.requiredPayloadFieldCount()
    }
    total
}

public func apiWrapperOptionalPayloadFieldTotal(): Int64 {
    var total = 0
    for (trace in apiWrapperSchemaTraces()) {
        total += trace.optionalPayloadFieldCount()
    }
    total
}

public func apiWrapperReturnTypeKindCount(): Int64 {
    let returnTypes = ArrayList<String>()
    for (trace in apiWrapperSchemaTraces()) {
        if (!containsTraceField(joinTraceFields(returnTypes), trace.returnTypeTrace)) {
            returnTypes.add(trace.returnTypeTrace)
        }
    }
    returnTypes.size
}

public func apiWrapperMissingReturnTypeCount(): Int64 {
    var missing: Int64 = 0
    for (trace in apiWrapperSchemaTraces()) {
        if (trace.returnTypeTrace == "") {
            missing += 1
        }
    }
    missing
}

public func apiWrapperTypedResultRows(): ArrayList<String> {
    let rows = ArrayList<String>()
    for (trace in apiWrapperSchemaTraces()) {
        let resultType = if (trace.publicMethodName == "getMe" && trace.returnTypeTrace == "UserFromGetMe") {
            "User"
        } else {
            trace.returnTypeTrace
        }
        rows.add(trace.publicMethodName + "~ApiResult<" + resultType + ">")
    }
    rows
}

public func apiWrapperPublicOutputGoldenRows(): ArrayList<String> {
    let rows = ArrayList<String>()
    for (trace in apiWrapperSignatureTraces()) {
        rows.add(
            trace.publicMethodName + "~" +
            trace.rawMethodName + "~" +
            trace.requiredParameterTrace + "~" +
            trace.optionalParameterTrace + "~" +
            trace.otherPayloadFieldTrace + "~" +
            trace.signalTrace + "~" +
            trace.cancelTrace + "~" +
            trace.returnTypeTrace
        )
    }
    rows
}
