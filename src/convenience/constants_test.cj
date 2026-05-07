package grammy4cj.convenience

import std.unittest.*

@Test
public class ApiConstantsTest {
    @TestCase
    public func apiConstantsKeepUpstreamOrder(): Unit {
        @Expect(
            API_CONSTANTS.toJSON(),
            "{\"DEFAULT_UPDATE_TYPES\":[\"message\",\"edited_message\",\"channel_post\",\"edited_channel_post\",\"business_connection\",\"business_message\",\"edited_business_message\",\"deleted_business_messages\",\"inline_query\",\"chosen_inline_result\",\"callback_query\",\"shipping_query\",\"pre_checkout_query\",\"purchased_paid_media\",\"poll\",\"poll_answer\",\"my_chat_member\",\"managed_bot\",\"chat_join_request\",\"chat_boost\",\"removed_chat_boost\"],\"ALL_UPDATE_TYPES\":[\"message\",\"edited_message\",\"channel_post\",\"edited_channel_post\",\"business_connection\",\"business_message\",\"edited_business_message\",\"deleted_business_messages\",\"inline_query\",\"chosen_inline_result\",\"callback_query\",\"shipping_query\",\"pre_checkout_query\",\"purchased_paid_media\",\"poll\",\"poll_answer\",\"my_chat_member\",\"managed_bot\",\"chat_join_request\",\"chat_boost\",\"removed_chat_boost\",\"chat_member\",\"message_reaction\",\"message_reaction_count\"],\"ALL_CHAT_PERMISSIONS\":{\"can_send_messages\":true,\"can_send_audios\":true,\"can_send_documents\":true,\"can_send_photos\":true,\"can_send_videos\":true,\"can_send_video_notes\":true,\"can_send_voice_notes\":true,\"can_send_polls\":true,\"can_send_other_messages\":true,\"can_add_web_page_previews\":true,\"can_change_info\":true,\"can_invite_users\":true,\"can_edit_tag\":true,\"can_pin_messages\":true,\"can_manage_topics\":true}}"
        )
        @Expect(API_CONSTANTS.DEFAULT_UPDATE_TYPES[0], "message")
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES[21], "chat_member")
        @Expect(API_CONSTANTS.ALL_CHAT_PERMISSIONS.toJSON().contains("\"can_manage_topics\":true"), true)
        @Expect(allChatPermissionKeys()[14], "can_manage_topics")
    }

    @TestCase
    public func telegramObjectOptionsOverrideEarlierFieldsLikeObjectSpread(): Unit {
        let object = TelegramObject()
        object.addString("thumbnail_url", "https://example.test/default.jpg")
        object.addString("caption", "old")

        let options = TelegramObject()
        options.addString("thumbnail_url", "https://example.test/explicit.jpg")
        options.addString("parse_mode", "HTML")
        object.addAll(options)

        @Expect(
            object.toJSON(),
            "{\"thumbnail_url\":\"https://example.test/explicit.jpg\",\"caption\":\"old\",\"parse_mode\":\"HTML\"}"
        )
    }
}
