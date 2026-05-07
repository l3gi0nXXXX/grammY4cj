package grammy4cj.convenience

import std.unittest.*

@Test
public class ApiConstantsTest {
    @TestCase
    public func apiConstantsKeepUpstreamOrder(): Unit {
        @Expect(
            API_CONSTANTS.toJSON(),
            "{\"DEFAULT_UPDATE_TYPES\":[\"message\",\"edited_message\",\"channel_post\",\"edited_channel_post\",\"business_connection\",\"business_message\",\"edited_business_message\",\"deleted_business_messages\",\"inline_query\",\"chosen_inline_result\",\"callback_query\",\"shipping_query\",\"pre_checkout_query\",\"purchased_paid_media\",\"poll\",\"poll_answer\",\"my_chat_member\",\"managed_bot\",\"chat_join_request\",\"chat_boost\",\"removed_chat_boost\"],\"ALL_UPDATE_TYPES\":[\"message\",\"edited_message\",\"channel_post\",\"edited_channel_post\",\"business_connection\",\"business_message\",\"edited_business_message\",\"deleted_business_messages\",\"inline_query\",\"chosen_inline_result\",\"callback_query\",\"shipping_query\",\"pre_checkout_query\",\"purchased_paid_media\",\"poll\",\"poll_answer\",\"my_chat_member\",\"managed_bot\",\"chat_join_request\",\"chat_boost\",\"removed_chat_boost\",\"chat_member\",\"message_reaction\",\"message_reaction_count\"],\"ALL_CHAT_PERMISSIONS\":[\"can_send_messages\",\"can_send_audios\",\"can_send_documents\",\"can_send_photos\",\"can_send_videos\",\"can_send_video_notes\",\"can_send_voice_notes\",\"can_send_polls\",\"can_send_other_messages\",\"can_add_web_page_previews\",\"can_change_info\",\"can_invite_users\",\"can_edit_tag\",\"can_pin_messages\",\"can_manage_topics\"]}"
        )
        @Expect(API_CONSTANTS.DEFAULT_UPDATE_TYPES[0], "message")
        @Expect(API_CONSTANTS.ALL_UPDATE_TYPES[21], "chat_member")
        @Expect(API_CONSTANTS.ALL_CHAT_PERMISSIONS[14], "can_manage_topics")
    }
}
