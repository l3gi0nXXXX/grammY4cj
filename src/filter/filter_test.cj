package grammy4cj.filter

import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{Chat, ChatMemberUpdated, Message, MessageEntity, MessageReactionUpdated, ReactionType, Update, User, UserFromGetMe}
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
        @Expect(errorMessageFor("unknown").startsWith("Invalid L1 filter 'unknown' given in 'unknown'. Permitted values are: 'message'"), true)
        @Expect(errorMessageFor("message:unknown").startsWith("Invalid L2 filter 'unknown' given in 'message:unknown'. Permitted values are: 'forward_origin'"), true)
        @Expect(errorMessageFor("message:text:url"), "Invalid L3 filter 'url' given in 'message:text:url'. No further filtering is possible after 'message:text'.")
        @Expect(errorMessageFor("message:entities:url:extra"), "Cannot filter further than three levels, ':extra' is invalid!")
        @Expect(errorMessageFor("::me"), "Shortcuts in '::me' do not expand to any valid filter query")
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
