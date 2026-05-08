package grammy4cj.filter

import std.collection.{ArrayList, HashMap}

import grammy4cj.types.{CallbackQuery, ChatMemberUpdated, Message, MessageEntity, ReactionType, Update, User, UserFromGetMe}

public type FilterQuery = String
public type FilterPredicate = (FilterContextView) -> Bool

public interface FilterContextView {
    func filterUpdate(): Update
    func filterBotUser(): UserFromGetMe
}

private class CompiledFilter {
    public let contextPredicate: FilterPredicate
    public let kindPredicate: (String) -> Bool

    public init(contextPredicate: FilterPredicate, kindPredicate: (String) -> Bool) {
        this.contextPredicate = contextPredicate
        this.kindPredicate = kindPredicate
    }
}

private class L2Node {
    public let key: String
    public let l3Keys: ArrayList<String> = ArrayList<String>()

    public init(key: String) {
        this.key = key
    }
}

private class L1Node {
    public let key: String
    public let l2Nodes: ArrayList<L2Node> = ArrayList<L2Node>()

    public init(key: String) {
        this.key = key
    }
}

private class FilterTree {
    public let l1Nodes: ArrayList<L1Node> = ArrayList<L1Node>()

    public init() {}
}

private var filterQueryCache: HashMap<String, CompiledFilter> = HashMap<String, CompiledFilter>()

public func matchFilter(query: FilterQuery): FilterPredicate {
    cachedFilter([query]).contextPredicate
}

public func matchFilter(queries: Array<FilterQuery>): FilterPredicate {
    cachedFilter(queries).contextPredicate
}

public func matchFilter(query: FilterQuery, ctx: FilterContextView): Bool {
    cachedFilter([query]).contextPredicate(ctx)
}

public func matchFilter(queries: Array<FilterQuery>, ctx: FilterContextView): Bool {
    cachedFilter(queries).contextPredicate(ctx)
}

public func matchFilter(query: FilterQuery, updateKind: String): Bool {
    cachedFilter([query]).kindPredicate(updateKind)
}

public func matchFilter(queries: Array<FilterQuery>, updateKind: String): Bool {
    cachedFilter(queries).kindPredicate(updateKind)
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

public func parse(query: FilterQuery): Array<Array<String>> {
    [parseFilterQuery(query)]
}

public func parse(queries: Array<FilterQuery>): Array<Array<String>> {
    let out = ArrayList<Array<String>>()
    for (query in queries) {
        out.add(parseFilterQuery(query))
    }
    out.toArray()
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

private func cachedFilter(queries: Array<FilterQuery>): CompiledFilter {
    let key = joinQueries(queries)
    match (filterQueryCache.get(key)) {
        case Some(compiled) => compiled
        case None =>
            let compiled = compile(queries)
            filterQueryCache[key] = compiled
            compiled
    }
}

private func compile(queries: Array<FilterQuery>): CompiledFilter {
    let paths = expandQueriesToParts(queries)
    let tree = treeify(paths)
    CompiledFilter(arborist(tree), compileKindPredicate(paths))
}

private func compileKindPredicate(paths: Array<Array<String>>): (String) -> Bool {
    { updateKind: String =>
        if (updateKind.isEmpty()) {
            return false
        }
        for (path in paths) {
            if (kindMatches(joinParts(path), updateKind)) {
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
        if (filter.size == 0) {
            return Some("Empty filter query given")
        }
    }
    let l1 = filter[0]
    if (!isValidL1(l1)) {
        return Some("Invalid L1 filter '" + l1 + "' given in '" + joinParts(filter) + "'. Permitted values are: " + permittedValues(l1Keys()) + ".")
    }
    if (filter.size == 1) {
        return None<String>
    }
    let l2 = filter[1]
    if (!isValidL2(l1, l2)) {
        return Some("Invalid L2 filter '" + l2 + "' given in '" + joinParts(filter) + "'. Permitted values are: " + permittedValues(l2Keys(l1)) + ".")
    }
    if (filter.size == 2) {
        return None<String>
    }
    let l3 = filter[2]
    if (!isValidL3(l1, l2, l3)) {
        let permitted = l3Keys(l1, l2)
        if (permitted.size == 0) {
            return Some("Invalid L3 filter '" + l3 + "' given in '" + joinParts(filter) + "'. No further filtering is possible after '" + l1 + ":" + l2 + "'.")
        }
        return Some("Invalid L3 filter '" + l3 + "' given in '" + joinParts(filter) + "'. Permitted values are: " + permittedValues(permitted) + ".")
    }
    if (filter.size > 3) {
        return Some("Cannot filter further than three levels, ':" + extraParts(filter, 3) + "' is invalid!")
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
        out.add(pathWith(filter, target, l2, l3))
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
        out.add(pathWith(filter, l1, target, l3))
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

private func pathWith(source: Array<String>, l1: String, l2: String, l3: String): Array<String> {
    if (source.size == 1) {
        return [l1]
    }
    if (source.size == 2) {
        return [l1, l2]
    }
    let out = ArrayList<String>()
    out.add(l1)
    out.add(l2)
    out.add(l3)
    var i: Int64 = 3
    while (i < source.size) {
        out.add(source[i])
        i += 1
    }
    out.toArray()
}

private func treeify(paths: Array<Array<String>>): FilterTree {
    let tree = FilterTree()
    for (path in paths) {
        if (path.size == 0) {
            continue
        }
        let l1Node = ensureL1Node(tree, path[0])
        if (path.size >= 2) {
            let l2Node = ensureL2Node(l1Node, path[1])
            if (path.size >= 3 && !containsString(l2Node.l3Keys.toArray(), path[2])) {
                l2Node.l3Keys.add(path[2])
            }
        }
    }
    tree
}

private func ensureL1Node(tree: FilterTree, key: String): L1Node {
    for (node in tree.l1Nodes) {
        if (node.key == key) {
            return node
        }
    }
    let node = L1Node(key)
    tree.l1Nodes.add(node)
    node
}

private func ensureL2Node(l1Node: L1Node, key: String): L2Node {
    for (node in l1Node.l2Nodes) {
        if (node.key == key) {
            return node
        }
    }
    let node = L2Node(key)
    l1Node.l2Nodes.add(node)
    node
}

private func arborist(tree: FilterTree): FilterPredicate {
    if (tree.l1Nodes.size == 0) {
        throw Exception("Cannot create filter function for empty query")
    }
    { ctx: FilterContextView =>
        for (node in tree.l1Nodes) {
            if (matchesL1Node(ctx, node)) {
                return true
            }
        }
        false
    }
}

private func matchesL1Node(ctx: FilterContextView, node: L1Node): Bool {
    if (!l1Present(ctx.filterUpdate(), node.key)) {
        return false
    }
    if (node.l2Nodes.size == 0) {
        return true
    }
    for (l2Node in node.l2Nodes) {
        if (matchesL2Node(ctx, node.key, l2Node)) {
            return true
        }
    }
    false
}

private func matchesL2Node(ctx: FilterContextView, l1: String, node: L2Node): Bool {
    if (!l2Present(ctx.filterUpdate(), l1, node.key)) {
        return false
    }
    if (node.l3Keys.size == 0) {
        return true
    }
    for (l3 in node.l3Keys) {
        if (l3Present(ctx, l1, node.key, l3)) {
            return true
        }
    }
    false
}

private func l1Present(update: Update, l1: String): Bool {
    if (l1 == "message") { return update.message.isPresent }
    if (l1 == "edited_message") { return update.editedMessage.isPresent }
    if (l1 == "channel_post") { return update.channelPost.isPresent }
    if (l1 == "edited_channel_post") { return update.editedChannelPost.isPresent }
    if (l1 == "business_connection") { return update.businessConnection.isPresent }
    if (l1 == "business_message") { return update.businessMessage.isPresent }
    if (l1 == "edited_business_message") { return update.editedBusinessMessage.isPresent }
    if (l1 == "deleted_business_messages") { return update.deletedBusinessMessages.isPresent }
    if (l1 == "inline_query") { return update.inlineQuery.isPresent }
    if (l1 == "chosen_inline_result") { return update.chosenInlineResult.isPresent }
    if (l1 == "callback_query") { return update.callbackQuery.isPresent }
    if (l1 == "shipping_query") { return update.shippingQuery.isPresent }
    if (l1 == "pre_checkout_query") { return update.preCheckoutQuery.isPresent }
    if (l1 == "poll") { return update.poll.isPresent }
    if (l1 == "poll_answer") { return update.pollAnswer.isPresent }
    if (l1 == "my_chat_member") { return update.myChatMember.isPresent }
    if (l1 == "chat_member") { return update.chatMember.isPresent }
    if (l1 == "managed_bot") { return update.managedBot.isPresent }
    if (l1 == "chat_join_request") { return update.chatJoinRequest.isPresent }
    if (l1 == "message_reaction") { return update.messageReaction.isPresent }
    if (l1 == "message_reaction_count") { return update.messageReactionCount.isPresent }
    if (l1 == "chat_boost") { return update.chatBoost.isPresent }
    if (l1 == "removed_chat_boost") { return update.removedChatBoost.isPresent }
    if (l1 == "purchased_paid_media") { return update.purchasedPaidMedia.isPresent }
    false
}

private func l2Present(update: Update, l1: String, l2: String): Bool {
    if (isMessageLike(l1)) {
        return messageL2Present(messageFor(update, l1), l2)
    }
    if (l1 == "callback_query") {
        return callbackQueryL2Present(update.callbackQuery, l2)
    }
    if (l1 == "my_chat_member") {
        return chatMemberL2Present(update.myChatMember, l2)
    }
    if (l1 == "chat_member") {
        return chatMemberL2Present(update.chatMember, l2)
    }
    if (l1 == "message_reaction") {
        if (!update.messageReaction.isPresent) {
            return false
        }
        return l2 == "old_reaction" || l2 == "new_reaction"
    }
    if (l1 == "message_reaction_count") {
        return update.messageReactionCount.isPresent && l2 == "reactions"
    }
    false
}

private func l3Present(ctx: FilterContextView, l1: String, l2: String, l3: String): Bool {
    let update = ctx.filterUpdate()
    if (isMessageLike(l1)) {
        let message = messageFor(update, l1)
        if (l2 == "entities") {
            return entitiesHaveKind(message.entities.toArray(), l3)
        }
        if (l2 == "caption_entities") {
            return entitiesHaveKind(message.captionEntities.toArray(), l3)
        }
        if (l2 == "new_chat_members" || l2 == "left_chat_member") {
            return userL3Present(ctx, message.user, l3)
        }
        return messageNestedFieldPresent(message, l2, l3)
    }
    if (l1 == "my_chat_member" && l2 == "from") {
        return userL3Present(ctx, update.myChatMember.user, l3)
    }
    if (l1 == "chat_member" && l2 == "from") {
        return userL3Present(ctx, update.chatMember.user, l3)
    }
    if (l1 == "message_reaction") {
        if (l2 == "old_reaction") {
            return reactionsHaveKind(update.messageReaction.oldReaction, l3)
        }
        if (l2 == "new_reaction") {
            return reactionsHaveKind(update.messageReaction.newReaction, l3)
        }
    }
    if (l1 == "message_reaction_count" && l2 == "reactions") {
        return reactionsHaveKind(update.messageReactionCount.reactions, l3)
    }
    false
}

private func messageFor(update: Update, l1: String): Message {
    if (l1 == "message") { return update.message }
    if (l1 == "edited_message") { return update.editedMessage }
    if (l1 == "channel_post") { return update.channelPost }
    if (l1 == "edited_channel_post") { return update.editedChannelPost }
    if (l1 == "business_message") { return update.businessMessage }
    if (l1 == "edited_business_message") { return update.editedBusinessMessage }
    Message()
}

private func messageL2Present(message: Message, l2: String): Bool {
    if (!message.isPresent) {
        return false
    }
    if (messageObjectFieldPresent(message, l2)) { return true }
    if (l2 == "text") { return !message.text.isEmpty() }
    if (l2 == "caption") { return !message.caption.isEmpty() }
    if (l2 == "entities") { return message.entities.size > 0 }
    if (l2 == "caption_entities") { return message.captionEntities.size > 0 }
    if (l2 == "new_chat_members" || l2 == "left_chat_member") { return message.user.isPresent }
    if (l2 == "business_connection_id") { return !message.businessConnectionId.isEmpty() }
    if (l2 == "is_topic_message") { return message.isTopicMessage }
    if (l2 == "direct_messages_topic") { return message.directMessagesTopicId != 0 }
    false
}

private func messageObjectFieldPresent(message: Message, key: String): Bool {
    containsString(message.objectFields.toArray(), key)
}

private func messageNestedFieldPresent(message: Message, key: String, nestedKey: String): Bool {
    if (!messageObjectFieldPresent(message, key)) {
        return false
    }
    containsString(message.objectNestedFields.toArray(), key + ":" + nestedKey)
}

private func callbackQueryL2Present(callbackQuery: CallbackQuery, l2: String): Bool {
    if (!callbackQuery.isPresent) {
        return false
    }
    if (l2 == "data") { return !callbackQuery.data.isEmpty() }
    if (l2 == "game_short_name") { return !callbackQuery.gameShortName.isEmpty() }
    false
}

private func chatMemberL2Present(chatMember: ChatMemberUpdated, l2: String): Bool {
    chatMember.isPresent && l2 == "from" && chatMember.user.isPresent
}

private func userL3Present(ctx: FilterContextView, user: User, l3: String): Bool {
    if (!user.isPresent) {
        return false
    }
    if (l3 == "me") {
        return user.id == ctx.filterBotUser().id
    }
    if (l3 == "is_bot") {
        return user.isBot
    }
    false
}

private func entitiesHaveKind(entities: Array<MessageEntity>, kind: String): Bool {
    testMaybeArray<MessageEntity>(entities, { entity: MessageEntity => entity.kind == kind })
}

private func reactionsHaveKind(reactions: Array<ReactionType>, kind: String): Bool {
    testMaybeArray<ReactionType>(reactions, { reaction: ReactionType => reaction.kind == kind })
}

private func testMaybeArray<T>(value: T, pred: (T) -> Bool): Bool {
    pred(value)
}

private func testMaybeArray<T>(values: Array<T>, pred: (T) -> Bool): Bool {
    for (value in values) {
        if (pred(value)) {
            return true
        }
    }
    false
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

private func permittedValues(values: Array<String>): String {
    let quoted = ArrayList<String>()
    for (value in values) {
        quoted.add("'" + value + "'")
    }
    joinStrings(quoted.toArray(), ", ")
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
