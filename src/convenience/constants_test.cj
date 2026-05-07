package grammy4cj.convenience

import std.unittest.*

@Test
public class ApiConstantsTest {
    @TestCase
    public func upstream001ApiConstantsFrozenEquivalentGolden(): Unit {
        @Expect(API_CONSTANTS.isFrozen(), true)
        @Expect(TELEGRAM_BOT_API_VERSION, "9.6")
        @Expect(GRAMMY_TYPES_VERSION, "v3.26.0")
        @Expect(GRAMMY_UPSTREAM_BASELINE_HEAD, "c865dd3a4d26911b01c83695e3845c7245870a5d")
        @Expect(GRAMMY_UPSTREAM_BASELINE_TAG, "v1.42.0-5-gc865dd3")
        @Expect(
            API_CONSTANTS.toJSON(),
            "{\"DEFAULT_UPDATE_TYPES\":[\"message\",\"edited_message\",\"channel_post\",\"edited_channel_post\",\"business_connection\",\"business_message\",\"edited_business_message\",\"deleted_business_messages\",\"inline_query\",\"chosen_inline_result\",\"callback_query\",\"shipping_query\",\"pre_checkout_query\",\"purchased_paid_media\",\"poll\",\"poll_answer\",\"my_chat_member\",\"managed_bot\",\"chat_join_request\",\"chat_boost\",\"removed_chat_boost\"],\"ALL_UPDATE_TYPES\":[\"message\",\"edited_message\",\"channel_post\",\"edited_channel_post\",\"business_connection\",\"business_message\",\"edited_business_message\",\"deleted_business_messages\",\"inline_query\",\"chosen_inline_result\",\"callback_query\",\"shipping_query\",\"pre_checkout_query\",\"purchased_paid_media\",\"poll\",\"poll_answer\",\"my_chat_member\",\"managed_bot\",\"chat_join_request\",\"chat_boost\",\"removed_chat_boost\",\"chat_member\",\"message_reaction\",\"message_reaction_count\"],\"ALL_CHAT_PERMISSIONS\":{\"can_send_messages\":true,\"can_send_audios\":true,\"can_send_documents\":true,\"can_send_photos\":true,\"can_send_videos\":true,\"can_send_video_notes\":true,\"can_send_voice_notes\":true,\"can_send_polls\":true,\"can_send_other_messages\":true,\"can_add_web_page_previews\":true,\"can_change_info\":true,\"can_invite_users\":true,\"can_edit_tag\":true,\"can_pin_messages\":true,\"can_manage_topics\":true}}"
        )
    }

    @TestCase
    public func upstream002AllUpdateTypesCoverDefaultAndOptionalUpdates(): Unit {
        @Expect(API_CONSTANTS.DEFAULT_UPDATE_TYPES.size, 21)
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES.size, 24)
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES[0], "message")
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES[20], "removed_chat_boost")
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES[21], "chat_member")
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES[22], "message_reaction")
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES[23], "message_reaction_count")
    }

    @TestCase
    public func upstream003AllChatPermissionsCoverEveryPermission(): Unit {
        @Expect(allChatPermissionKeys().size, 15)
        @Expect(allChatPermissionKeys()[0], "can_send_messages")
        @Expect(allChatPermissionKeys()[14], "can_manage_topics")
        @Expect(API_CONSTANTS.ALL_CHAT_PERMISSIONS.hasField("can_send_audios"), true)
        @Expect(API_CONSTANTS.ALL_CHAT_PERMISSIONS.rawField("can_send_audios"), "true")
        @Expect(
            API_CONSTANTS.ALL_CHAT_PERMISSIONS.toJSON(),
            "{\"can_send_messages\":true,\"can_send_audios\":true,\"can_send_documents\":true,\"can_send_photos\":true,\"can_send_videos\":true,\"can_send_video_notes\":true,\"can_send_voice_notes\":true,\"can_send_polls\":true,\"can_send_other_messages\":true,\"can_add_web_page_previews\":true,\"can_change_info\":true,\"can_invite_users\":true,\"can_edit_tag\":true,\"can_pin_messages\":true,\"can_manage_topics\":true}"
        )
    }
}
