package grammy4cj.filter

import std.collection.{ArrayList, HashMap}

public type FilterQuery = String
public type FilterPredicate = (String) -> Bool

private var filterQueryCache: HashMap<String, FilterPredicate> = HashMap<String, FilterPredicate>()

public func matchFilter(query: FilterQuery, updateKind: String): Bool {
    cachedPredicate([query])(updateKind)
}

public func matchFilter(queries: Array<FilterQuery>, updateKind: String): Bool {
    cachedPredicate(queries)(updateKind)
}

public func parseFilterQuery(query: FilterQuery): Array<String> {
    let parts = ArrayList<String>()
    var start: Int64 = 0
    var i: Int64 = 0
    while (i < query.size) {
        if (query[i..i + 1] == ":") {
            parts.add(query[start..i])
            start = i + 1
        }
        i += 1
    }
    parts.add(query[start..])
    parts.toArray()
}

public func expandedFilterQueries(query: FilterQuery): Array<String> {
    expandedFilterQueries([query])
}

public func expandedFilterQueries(queries: Array<FilterQuery>): Array<String> {
    let expanded = expandQueriesToParts(queries)
    let out = ArrayList<String>()
    for (parts in expanded) {
        out.add(joinParts(parts))
    }
    out.toArray()
}

public func clearFilterPredicateCache(): Unit {
    filterQueryCache.clear()
}

public func filterPredicateCacheSize(): Int64 {
    filterQueryCache.size
}

private func cachedPredicate(queries: Array<FilterQuery>): FilterPredicate {
    let key = joinQueries(queries)
    match (filterQueryCache.get(key)) {
        case Some(predicate) => predicate
        case None =>
            let predicate = compile(queries)
            filterQueryCache[key] = predicate
            predicate
    }
}

private func compile(queries: Array<FilterQuery>): FilterPredicate {
    let paths = expandedFilterQueries(queries)
    { updateKind: String =>
        if (updateKind.isEmpty()) {
            return false
        }
        for (path in paths) {
            if (kindMatches(path, updateKind)) {
                return true
            }
        }
        false
    }
}

private func kindMatches(queryPath: String, updateKind: String): Bool {
    updateKind == queryPath || updateKind.startsWith(queryPath + ":")
}

private func expandQueriesToParts(queries: Array<FilterQuery>): Array<Array<String>> {
    let out = ArrayList<Array<String>>()
    for (query in queries) {
        let parts = parseFilterQuery(query)
        let expanded = check(parts, preprocess(parts))
        for (path in expanded) {
            out.add(path)
        }
    }
    out.toArray()
}

private func preprocess(filter: Array<String>): Array<Array<String>> {
    if (filter.size > 3) {
        throw Exception("Cannot filter further than three levels, ':" + extraParts(filter, 3) + "' is invalid!")
    }
    let l1Expanded = expandL1(filter)
    let l2Expanded = ArrayList<Array<String>>()
    for (parts in l1Expanded) {
        let expanded = expandL2(parts)
        for (path in expanded) {
            l2Expanded.add(path)
        }
    }
    if (l2Expanded.size == 0) {
        throw Exception("Shortcuts in '" + joinParts(filter) + "' do not expand to any valid filter query")
    }
    l2Expanded.toArray()
}

private func check(original: Array<String>, preprocessed: Array<Array<String>>): Array<Array<String>> {
    if (preprocessed.size == 0) {
        throw Exception("Empty filter query given")
    }
    let errors = ArrayList<String>()
    for (parts in preprocessed) {
        match (checkOne(parts)) {
            case Some(err) => errors.add(err)
            case None => ()
        }
    }
    if (errors.size == 0) {
        return preprocessed
    }
    if (errors.size == 1) {
        throw Exception(errors[0])
    }
    throw Exception("Invalid filter query '" + joinParts(original) + "'. There are " + errors.size.toString() + " errors after expanding the contained shortcuts: " + joinStrings(errors.toArray(), "; "))
}

private func checkOne(filter: Array<String>): Option<String> {
    if (filter.size == 0 || filter[0].isEmpty()) {
        return Some("Empty filter query given")
    }
    let l1 = filter[0]
    if (!isValidL1(l1)) {
        return Some("Invalid L1 filter '" + l1 + "' given in '" + joinParts(filter) + "'.")
    }
    if (filter.size == 1) {
        return None<String>
    }
    let l2 = filter[1]
    if (!isValidL2(l1, l2)) {
        return Some("Invalid L2 filter '" + l2 + "' given in '" + joinParts(filter) + "'.")
    }
    if (filter.size == 2) {
        return None<String>
    }
    let l3 = filter[2]
    if (!isValidL3(l1, l2, l3)) {
        return Some("Invalid L3 filter '" + l3 + "' given in '" + joinParts(filter) + "'.")
    }
    None<String>
}

private func expandL1(filter: Array<String>): Array<Array<String>> {
    let l1 = filter[0]
    let hasL2 = filter.size >= 2
    let hasL3 = filter.size >= 3
    let l2 = if (hasL2) { filter[1] } else { "" }
    let l3 = if (hasL3) { filter[2] } else { "" }
    if (!isL1Shortcut(l1)) {
        return [filter]
    }
    if (l1.isEmpty() && !hasL2 && !hasL3) {
        return [filter]
    }
    let out = ArrayList<Array<String>>()
    for (target in l1ShortcutTargets(l1)) {
        out.add(pathWith(target, l2, l3, filter.size))
    }
    if (!hasL2) {
        return out.toArray()
    }
    if (isL2Shortcut(l2) && (!l2.isEmpty() || hasL3)) {
        return out.toArray()
    }
    let filtered = ArrayList<Array<String>>()
    for (path in out) {
        if (isValidL2(path[0], l2)) {
            filtered.add(path)
        }
    }
    filtered.toArray()
}

private func expandL2(filter: Array<String>): Array<Array<String>> {
    if (filter.size < 2) {
        return [filter]
    }
    let l1 = filter[0]
    let l2 = filter[1]
    let hasL3 = filter.size >= 3
    let l3 = if (hasL3) { filter[2] } else { "" }
    if (!isL2Shortcut(l2)) {
        return [filter]
    }
    if (l2.isEmpty() && !hasL3) {
        return [filter]
    }
    let out = ArrayList<Array<String>>()
    for (target in l2ShortcutTargets(l2)) {
        out.add(pathWith(l1, target, l3, filter.size))
    }
    if (!hasL3) {
        return out.toArray()
    }
    let filtered = ArrayList<Array<String>>()
    for (path in out) {
        if (isValidL3(l1, path[1], l3)) {
            filtered.add(path)
        }
    }
    filtered.toArray()
}

private func pathWith(l1: String, l2: String, l3: String, size: Int64): Array<String> {
    if (size == 1) {
        return [l1]
    }
    if (size == 2) {
        return [l1, l2]
    }
    [l1, l2, l3]
}

private func isL1Shortcut(value: String): Bool {
    value == "" || value == "msg" || value == "edit"
}

private func l1ShortcutTargets(value: String): Array<String> {
    if (value == "" || value == "msg") {
        return ["message", "channel_post"]
    }
    if (value == "edit") {
        return ["edited_message", "edited_channel_post"]
    }
    [value]
}

private func isL2Shortcut(value: String): Bool {
    value == "" || value == "media" || value == "file"
}

private func l2ShortcutTargets(value: String): Array<String> {
    if (value == "") {
        return ["entities", "caption_entities"]
    }
    if (value == "media") {
        return ["photo", "video"]
    }
    if (value == "file") {
        return ["photo", "animation", "audio", "document", "video", "video_note", "voice", "sticker"]
    }
    [value]
}

private func isValidL1(value: String): Bool {
    containsString(l1Keys(), value)
}

private func isValidL2(l1: String, l2: String): Bool {
    containsString(l2Keys(l1), l2)
}

private func isValidL3(l1: String, l2: String, l3: String): Bool {
    containsString(l3Keys(l1, l2), l3)
}

private func l1Keys(): Array<String> {
    [
        "message", "edited_message", "channel_post", "edited_channel_post",
        "business_connection", "business_message", "edited_business_message",
        "deleted_business_messages", "inline_query", "chosen_inline_result",
        "callback_query", "shipping_query", "pre_checkout_query", "poll",
        "poll_answer", "my_chat_member", "chat_member", "managed_bot",
        "chat_join_request", "message_reaction", "message_reaction_count",
        "chat_boost", "removed_chat_boost", "purchased_paid_media"
    ]
}

private func l2Keys(l1: String): Array<String> {
    if (isMessageLike(l1)) {
        if (l1 == "channel_post" || l1 == "edited_channel_post") {
            return channelPostKeys()
        }
        return messageKeys()
    }
    if (l1 == "business_connection") {
        return ["can_reply", "is_enabled"]
    }
    if (l1 == "callback_query") {
        return ["data", "game_short_name"]
    }
    if (l1 == "my_chat_member" || l1 == "chat_member") {
        return ["from"]
    }
    if (l1 == "message_reaction") {
        return ["old_reaction", "new_reaction"]
    }
    if (l1 == "message_reaction_count") {
        return ["reactions"]
    }
    []
}

private func l3Keys(l1: String, l2: String): Array<String> {
    if (isMessageLike(l1)) {
        if (l2 == "entities" || l2 == "caption_entities") {
            return entityKeys()
        }
        if (l2 == "forward_origin") {
            return ["user", "hidden_user", "chat", "channel"]
        }
        if (l2 == "sticker") {
            return ["is_video", "is_animated", "premium_animation"]
        }
        if (l2 == "new_chat_members" || l2 == "left_chat_member") {
            return userKeys()
        }
        if (l2 == "chat_owner_left") {
            return ["new_owner"]
        }
        if (l2 == "forum_topic_created") {
            return ["is_name_implicit"]
        }
        if (l2 == "forum_topic_edited") {
            return ["name", "icon_custom_emoji_id"]
        }
        if (l2 == "giveaway") {
            return ["only_new_members", "has_public_winners"]
        }
        if (l2 == "giveaway_winners") {
            return ["only_new_members", "was_refunded"]
        }
        if (l2 == "gift" || l2 == "gift_upgrade_sent") {
            return ["can_be_upgraded", "is_upgrade_separate", "is_private"]
        }
        if (l2 == "unique_gift") {
            return ["transfer_star_count"]
        }
        if (l2 == "link_preview_options") {
            return ["url", "prefer_small_media", "prefer_large_media", "show_above_text"]
        }
        if (l2 == "checklist") {
            return ["others_can_add_tasks", "others_can_mark_tasks_as_done"]
        }
    }
    if (l1 == "my_chat_member" || l1 == "chat_member") {
        if (l2 == "from") {
            return userKeys()
        }
    }
    if (l1 == "message_reaction" && (l2 == "old_reaction" || l2 == "new_reaction")) {
        return reactionKeys()
    }
    if (l1 == "message_reaction_count" && l2 == "reactions") {
        return reactionKeys()
    }
    []
}

private func isMessageLike(l1: String): Bool {
    l1 == "message" || l1 == "edited_message" || l1 == "channel_post" ||
        l1 == "edited_channel_post" || l1 == "business_message" ||
        l1 == "edited_business_message"
}

private func commonMessageKeys(): Array<String> {
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
        "video_chat_ended", "video_chat_participants_invited", "web_app_data"
    ]
}

private func messageKeys(): Array<String> {
    let out = ArrayList<String>()
    addAll(out, commonMessageKeys())
    addAll(out, [
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
    ])
    out.toArray()
}

private func channelPostKeys(): Array<String> {
    let out = ArrayList<String>()
    addAll(out, commonMessageKeys())
    addAll(out, ["channel_chat_created", "direct_message_price_changed", "is_paid_post"])
    out.toArray()
}

private func entityKeys(): Array<String> {
    [
        "mention", "hashtag", "cashtag", "bot_command", "url", "email",
        "phone_number", "bold", "italic", "underline", "strikethrough",
        "spoiler", "blockquote", "expandable_blockquote", "code", "pre",
        "text_link", "text_mention", "custom_emoji", "date_time"
    ]
}

private func userKeys(): Array<String> {
    ["me", "is_bot", "is_premium", "added_to_attachment_menu"]
}

private func reactionKeys(): Array<String> {
    ["emoji", "custom_emoji", "paid"]
}

private func addAll(out: ArrayList<String>, values: Array<String>): Unit {
    for (value in values) {
        out.add(value)
    }
}

private func containsString(values: Array<String>, needle: String): Bool {
    for (value in values) {
        if (value == needle) {
            return true
        }
    }
    false
}

private func joinQueries(queries: Array<FilterQuery>): String {
    joinStrings(queries, ",")
}

private func joinParts(parts: Array<String>): String {
    joinStrings(parts, ":")
}

private func joinStrings(values: Array<String>, separator: String): String {
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

private func extraParts(parts: Array<String>, start: Int64): String {
    let out = ArrayList<String>()
    var i = start
    while (i < parts.size) {
        out.add(parts[i])
        i += 1
    }
    joinParts(out.toArray())
}
