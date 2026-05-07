package grammy4cj.filter

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
    public func matchFilterUsesCompiledPrefixPredicates(): Unit {
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
        @Expect(throwsFor("unknown"), true)
        @Expect(throwsFor("message:unknown"), true)
        @Expect(throwsFor("message:text:url"), true)
        @Expect(throwsFor("message:entities:url:extra"), true)
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
    public func predicateCompilationIsCachedByQueryKey(): Unit {
        clearFilterPredicateCache()

        @Expect(filterPredicateCacheSize(), 0)
        @Expect(matchFilter("message:text", "message:text"), true)
        @Expect(filterPredicateCacheSize(), 1)
        @Expect(matchFilter("message:text", "channel_post:text"), false)
        @Expect(filterPredicateCacheSize(), 1)
        @Expect(matchFilter(["message:text", "channel_post:text"], "channel_post:text"), true)
        @Expect(filterPredicateCacheSize(), 2)
    }
}
