package grammy4cj.filter

import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{Chat, ChatMemberUpdated, Message, MessageEntity, MessageReactionCountUpdated, MessageReactionUpdated, ReactionType, Update, User, UserFromGetMe}
import std.collection.ArrayList
import std.unittest.*

private func contains(values: Array<String>, needle: String): Bool {
    for (value in values) {
        if (value == needle) {
            return true
        }
    }
    false
}

private func throwsFor(query: String): Bool {
    try {
        expandedFilterQueries(query)
        false
    } catch (_: Exception) {
        true
    }
}

private func errorMessageFor(query: String): String {
    try {
        expandedFilterQueries(query)
        ""
    } catch (err: Exception) {
        err.message
    }
}

private func botInfo(): UserFromGetMe {
    UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
}

private func testContext(update: Update): Context {
    Context(update, Api("fake-token"), botInfo())
}

private func testChat(): Chat {
    Chat(10, "private")
}

private func messageContext(kind: String): Context {
    let update = Update(1, kind)
    update.message = Message(100, testChat(), "")
    testContext(update)
}

private func channelPostContext(kind: String): Context {
    let update = Update(1, kind)
    update.channelPost = Message(100, testChat(), "")
    testContext(update)
}

private func editedMessageContext(kind: String): Context {
    let update = Update(1, kind)
    let message = Message(100, testChat(), "")
    message.caption = "caption"
    update.editedMessage = message
    testContext(update)
}

private func entityContext(kind: String, entityKind: String): Context {
    let update = Update(1, kind)
    update.message = Message(100, testChat(), "").addEntity(MessageEntity(entityKind, 0, 3))
    testContext(update)
}

private func permittedValuesGolden(values: Array<String>): String {
    let quoted = ArrayList<String>()
    for (value in values) {
        quoted.add("'" + value + "'")
    }
    joinGolden(quoted.toArray(), ", ")
}

private func joinGolden(values: Array<String>, separator: String): String {
    var out = ""
    var first = true
    for (value in values) {
        if (!first) {
            out += separator
        }
        out += value
        first = false
    }
    out
}

private func messageL2Golden(): Array<String> {
    [
        "forward_origin", "is_topic_message", "is_automatic_forward",
        "business_connection_id", "text", "animation", "audio", "document",
        "paid_media", "photo", "sticker", "story", "video", "video_note",
        "voice", "contact", "dice", "game", "poll", "venue", "location",
        "entities", "caption_entities", "caption", "link_preview_options",
        "effect_id", "paid_star_count", "has_media_spoiler", "new_chat_title",
        "new_chat_photo", "delete_chat_photo", "message_auto_delete_timer_changed",
        "pinned_message", "invoice", "proximity_alert_triggered",
        "chat_background_set", "giveaway_created", "giveaway", "giveaway_winners",
        "giveaway_completed", "gift", "gift_upgrade_sent", "unique_gift",
        "paid_message_price_changed", "video_chat_scheduled", "video_chat_started",
        "video_chat_ended", "video_chat_participants_invited", "web_app_data",
        "direct_messages_topic", "chat_owner_left", "chat_owner_changed",
        "new_chat_members", "left_chat_member", "group_chat_created",
        "supergroup_chat_created", "migrate_to_chat_id", "migrate_from_chat_id",
        "successful_payment", "refunded_payment", "users_shared", "chat_shared",
        "connected_website", "managed_bot_created", "write_access_allowed",
        "passport_data", "boost_added", "forum_topic_created",
        "forum_topic_edited", "forum_topic_closed", "forum_topic_reopened",
        "general_forum_topic_hidden", "general_forum_topic_unhidden",
        "checklist", "checklist_tasks_done", "checklist_tasks_added",
        "poll_option_added", "poll_option_deleted", "suggested_post_info",
        "suggested_post_approved", "suggested_post_approval_failed",
        "suggested_post_declined", "suggested_post_paid",
        "suggested_post_refunded", "sender_boost_count"
    ]
}

private func entityL3Golden(): Array<String> {
    [
        "mention", "hashtag", "cashtag", "bot_command", "url", "email",
        "phone_number", "bold", "italic", "underline", "strikethrough",
        "spoiler", "blockquote", "expandable_blockquote", "code", "pre",
        "text_link", "text_mention", "custom_emoji", "date_time"
    ]
}

@Test
public class FilterQueryTest {
    @TestCase
    public func parsePreservesEmptyShortcutLevels(): Unit {
        let parsed = parseFilterQuery("::url")

        @Expect(parsed.size, 3)
        @Expect(parsed[0], "")
        @Expect(parsed[1], "")
        @Expect(parsed[2], "url")
    }

    @TestCase
    public func parseReturnsUpstreamTwoDimensionalShape(): Unit {
        let parsed = parse(["message:text", "::url"])

        @Expect(parsed.size, 2)
        @Expect(parsed[0].size, 2)
        @Expect(parsed[0][0], "message")
        @Expect(parsed[0][1], "text")
        @Expect(parsed[1].size, 3)
        @Expect(parsed[1][0], "")
        @Expect(parsed[1][1], "")
        @Expect(parsed[1][2], "url")
    }

    @TestCase
    public func legacyKindMatcherKeepsComposerCompatibility(): Unit {
        clearFilterPredicateCache()

        @Expect(matchFilter("message", "message:text"), true)
        @Expect(matchFilter("message:text", "message:text"), true)
        @Expect(matchFilter("message:entities:url", "message:entities:url"), true)
        @Expect(matchFilter("message:entities:url", "message:entities:email"), false)
        @Expect(matchFilter(["message:text", "channel_post:text"], "channel_post:text"), true)
    }

    @TestCase
    public func invalidQueriesAreRejected(): Unit {
        @Expect(throwsFor(""), true)
        @Expect(throwsFor(":"), true)
        @Expect(throwsFor("::"), true)
        @Expect(throwsFor("  "), true)
        @Expect(throwsFor("unknown"), true)
        @Expect(throwsFor("message:"), true)
        @Expect(throwsFor("::me"), true)
        @Expect(throwsFor("message:unknown"), true)
        @Expect(throwsFor("message:text:url"), true)
        @Expect(throwsFor("message:entities:url:extra"), true)
    }

    @TestCase
    public func invalidQueryMessagesMirrorUpstreamShape(): Unit {
        @Expect(errorMessageFor(":"), "Shortcuts in ':' do not expand to any valid filter query")
        @Expect(errorMessageFor("::"), "Shortcuts in '::' do not expand to any valid filter query")
        @Expect(errorMessageFor("message:"), "Invalid L2 filter '' given in 'message:'. Permitted values are: " + permittedValuesGolden(messageL2Golden()) + ".")
        @Expect(errorMessageFor("unknown").startsWith("Invalid L1 filter 'unknown' given in 'unknown'. Permitted values are: 'message'"), true)
        @Expect(errorMessageFor("message:unknown").startsWith("Invalid L2 filter 'unknown' given in 'message:unknown'. Permitted values are: 'forward_origin'"), true)
        @Expect(errorMessageFor("message:text:url"), "Invalid L3 filter 'url' given in 'message:text:url'. No further filtering is possible after 'message:text'.")
        @Expect(errorMessageFor("message:entities:url:extra"), "Cannot filter further than three levels, ':extra' is invalid!")
        @Expect(errorMessageFor("::me"), "Shortcuts in '::me' do not expand to any valid filter query")
        @Expect(errorMessageFor(":entities:me"), "Invalid filter query ':entities:me'. There are 2 errors after expanding the contained shortcuts: Invalid L3 filter 'me' given in 'message:entities:me'. Permitted values are: " + permittedValuesGolden(entityL3Golden()) + ".; Invalid L3 filter 'me' given in 'channel_post:entities:me'. Permitted values are: " + permittedValuesGolden(entityL3Golden()) + ".")
    }

    @TestCase
    public func shortcutsExpandAcrossL1L2AndL3(): Unit {
        let text = expandedFilterQueries(":text")
        let url = expandedFilterQueries("::url")
        let file = expandedFilterQueries("msg:file")
        let onlyMessage = expandedFilterQueries(":new_chat_members")

        @Expect(contains(text, "message:text"), true)
        @Expect(contains(text, "channel_post:text"), true)
        @Expect(contains(url, "message:entities:url"), true)
        @Expect(contains(url, "message:caption_entities:url"), true)
        @Expect(contains(url, "channel_post:entities:url"), true)
        @Expect(contains(url, "channel_post:caption_entities:url"), true)
        @Expect(contains(file, "message:photo"), true)
        @Expect(contains(file, "message:sticker"), true)
        @Expect(contains(file, "channel_post:video"), true)
        @Expect(onlyMessage.size, 1)
        @Expect(onlyMessage[0], "message:new_chat_members")
    }

    @TestCase
    public func objectMatcherPerformsL1AndL2Filtering(): Unit {
        let ctx = messageContext("message:text")

        @Expect(matchFilter("message", ctx), true)
        @Expect(matchFilter("edited_message", ctx), false)
        @Expect(matchFilter("message:text", ctx), true)
        @Expect(matchFilter("edited_message:text", ctx), false)
    }

    @TestCase
    public func objectMatcherFillsDefaultL1AndL2Shortcuts(): Unit {
        let textCtx = messageContext("message:text")
        let entityCtx = entityContext("message", "url")

        @Expect(matchFilter(":text", textCtx), true)
        @Expect(matchFilter(":entities", textCtx), false)
        @Expect(matchFilter(":caption", textCtx), false)
        @Expect(matchFilter("message::url", entityCtx), true)
        @Expect(matchFilter("::url", entityCtx), true)
        @Expect(matchFilter("message::email", entityCtx), false)
        @Expect(matchFilter("edited_message", entityCtx), false)
    }

    @TestCase
    public func objectMatcherExpandsL1AndL2Shortcuts(): Unit {
        let ctxNew = messageContext("message:text")
        let ctxEdited = editedMessageContext("edited_message:photo")

        @Expect(matchFilter("msg", ctxNew), true)
        @Expect(matchFilter("msg:text", ctxNew), true)
        @Expect(matchFilter("msg:entities", ctxNew), false)
        @Expect(matchFilter(":audio", ctxNew), false)
        @Expect(matchFilter(":text", ctxEdited), false)
        @Expect(matchFilter("edit", ctxEdited), true)
        @Expect(matchFilter("edit:photo", ctxEdited), true)
        @Expect(matchFilter("edit:caption", ctxEdited), true)
        @Expect(matchFilter("edited_message:media", ctxEdited), true)
        @Expect(matchFilter("edited_message:file", ctxEdited), true)
        @Expect(matchFilter(":media", ctxEdited), false)
        @Expect(matchFilter(":file", ctxEdited), false)
    }

    @TestCase
    public func objectMatcherPerformsL3EntityAndUserFiltering(): Unit {
        let entityCtx = entityContext("message", "url")
        let member = ChatMemberUpdated(testChat(), User(42, true, "Bot", "bot"))
        let otherMember = ChatMemberUpdated(testChat(), User(7, false, "User", "user"))

        @Expect(matchFilter("message:entities:url", entityCtx), true)
        @Expect(matchFilter("message:entities:email", entityCtx), false)
        @Expect(matchFilter("chat_member:from:me", testContext(Update.withChatMember(2, member))), true)
        @Expect(matchFilter("chat_member:from:is_bot", testContext(Update.withChatMember(2, member))), true)
        @Expect(matchFilter("chat_member:from:me", testContext(Update.withChatMember(3, otherMember))), false)
    }

    @TestCase
    public func objectMatcherPerformsMessageUserMeShortcutFiltering(): Unit {
        let message = Message(100, testChat(), "", User(42, true, "Bot", "bot"))
        let update = Update(4, "message")
        update.message = message

        @Expect(matchFilter(":left_chat_member:me", testContext(update)), true)
        @Expect(matchFilter(":left_chat_member:is_bot", testContext(update)), true)
    }

    @TestCase
    public func objectMatcherMatchesEntityArraysAcrossMultipleFilters(): Unit {
        let entity = MessageEntity("", 0, 0)
        let message = Message(100, testChat(), "").addEntity(MessageEntity("italic", 0, 1)).addEntity(entity)
        let update = Update(1, "message")
        update.message = message
        let ctx = testContext(update)

        for (kind in ["url", "bold", "bot_command", "cashtag", "code"]) {
            entity.kind = kind
            @Expect(matchFilter(["::url", "::bold", "::bot_command", "::cashtag", "::code"], ctx), true)
        }
        entity.kind = "text_link"
        @Expect(matchFilter(["::email", "::phone_number"], ctx), false)
    }

    @TestCase
    public func objectMatcherMatchesReactionArrays(): Unit {
        let reactionUpdate = MessageReactionUpdated(
            testChat(),
            User(7, false, "User", "user"),
            100,
            [ReactionType.emojiReaction("ok")],
            [ReactionType.customEmojiReaction("custom"), ReactionType.paidReaction()],
        )
        let ctx = testContext(Update.withMessageReaction(4, reactionUpdate))

        @Expect(matchFilter("message_reaction", ctx), true)
        @Expect(matchFilter("message_reaction:old_reaction:emoji", ctx), true)
        @Expect(matchFilter("message_reaction:new_reaction:custom_emoji", ctx), true)
        @Expect(matchFilter("message_reaction:new_reaction:paid", ctx), true)
        @Expect(matchFilter("message_reaction:new_reaction:emoji", ctx), false)
    }

    @TestCase
    public func objectMatcherMatchesReactionCountL2AndKindBackedL3(): Unit {
        let update = Update(5, "message_reaction_count:reactions:paid")
        update.messageReactionCount = MessageReactionCountUpdated(testChat(), 100)
        let ctx = testContext(update)

        @Expect(matchFilter("message_reaction_count", ctx), true)
        @Expect(matchFilter("message_reaction_count:reactions", ctx), true)
        @Expect(matchFilter("message_reaction_count:reactions:paid", ctx), true)
        @Expect(matchFilter("message_reaction_count:reactions:emoji", ctx), false)
    }

    @TestCase
    public func objectMatcherKeepsNestedL3SchemaPathsKindBacked(): Unit {
        let forward = testContext(Update(6, "message:forward_origin:channel"))
        let sticker = testContext(Update(7, "message:sticker:is_animated"))
        let giveaway = testContext(Update(8, "message:giveaway:has_public_winners"))
        let linkPreview = testContext(Update(9, "message:link_preview_options:url"))

        @Expect(matchFilter("message:forward_origin:channel", forward), true)
        @Expect(matchFilter("message:forward_origin:user", forward), false)
        @Expect(matchFilter("message:sticker:is_animated", sticker), true)
        @Expect(matchFilter("message:sticker:is_video", sticker), false)
        @Expect(matchFilter("message:giveaway:has_public_winners", giveaway), true)
        @Expect(matchFilter("message:link_preview_options:url", linkPreview), true)
    }

    @TestCase
    public func predicateCompilationIsCachedByQueryKeyAcrossMatchers(): Unit {
        clearFilterPredicateCache()

        @Expect(filterPredicateCacheSize(), 0)
        @Expect(matchFilter("message:text", "message:text"), true)
        @Expect(filterPredicateCacheSize(), 1)
        @Expect(matchFilter("message:text", messageContext("message:text")), true)
        @Expect(filterPredicateCacheSize(), 1)
        @Expect(matchFilter("message:text", "channel_post:text"), false)
        @Expect(filterPredicateCacheSize(), 1)
        @Expect(matchFilter(["message:text", "channel_post:text"], channelPostContext("channel_post:text")), true)
        @Expect(filterPredicateCacheSize(), 2)
    }
}
