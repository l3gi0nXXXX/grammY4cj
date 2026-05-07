package grammy4cj.convenience

import std.collection.ArrayList
import std.unittest.*

@Test
public class KeyboardBuilderTest {
    @TestCase
    public func upstreamKeyboard001TakesInitialButtonsGolden(): Unit {
        let rows = ArrayList<ArrayList<KeyboardButton>>()
        let row = ArrayList<KeyboardButton>()
        row.add(Keyboard.textButton("button"))
        rows.add(row)

        @Expect(
            Keyboard(rows).toJSON(),
            "{\"keyboard\":[[{\"text\":\"button\"}]]}"
        )
    }

    @TestCase
    public func upstreamKeyboard002CreatesRowsAndColumnsGolden(): Unit {
        let rows = ArrayList<ArrayList<KeyboardButton>>()
        let row = ArrayList<KeyboardButton>()
        row.add(Keyboard.textButton("0"))
        rows.add(row)

        let keyboard = Keyboard(rows)
            .add(Keyboard.textButton("1"), Keyboard.textButton("2"))
            .row()
            .add(Keyboard.textButton("3"), Keyboard.textButton("4"))
            .add(Keyboard.textButton("5"))

        @Expect(
            keyboard.toJSON(),
            "{\"keyboard\":[[{\"text\":\"0\"},{\"text\":\"1\"},{\"text\":\"2\"}],[{\"text\":\"3\"},{\"text\":\"4\"},{\"text\":\"5\"}]]}"
        )
    }

    @TestCase
    public func keyboardBuildsRowsStylesAndReplyOptions(): Unit {
        let keyboard = Keyboard()
            .text("A")
            .text("B")
            .row()
            .requestContact("Phone")
            .danger()
            .icon("icon-contact")
            .persistent()
            .selected(false)
            .oneTime()
            .resized()
            .placeholder("Pick")

        @Expect(
            keyboard.toJSON(),
            "{\"keyboard\":[[{\"text\":\"A\"},{\"text\":\"B\"}],[{\"text\":\"Phone\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"icon-contact\",\"request_contact\":true}]],\"is_persistent\":true,\"selective\":false,\"one_time_keyboard\":true,\"resize_keyboard\":true,\"input_field_placeholder\":\"Pick\"}"
        )
        @Expect(keyboard.schemaIsValid(), true)
    }

    @TestCase
    public func upstreamKeyboard003ReplyMarkupOptionsStartUnsetThenSetGolden(): Unit {
        let keyboard = Keyboard()
        @Expect(keyboard.toJSON(), "{\"keyboard\":[[]]}")

        keyboard
            .persistent()
            .selected(false)
            .oneTime(true)
            .resized(false)
            .placeholder("placeholder")

        @Expect(
            keyboard.toJSON(),
            "{\"keyboard\":[[]],\"is_persistent\":true,\"selective\":false,\"one_time_keyboard\":true,\"resize_keyboard\":false,\"input_field_placeholder\":\"placeholder\"}"
        )
    }

    @TestCase
    public func upstreamKeyboard004CreatedFromDataSourcesGolden(): Unit {
        let rows = ArrayList<ArrayList<String>>()
        let first = ArrayList<String>()
        first.add("a")
        first.add("b")
        let second = ArrayList<String>()
        second.add("c")
        second.add("d")
        rows.add(first)
        rows.add(second)

        @Expect(
            Keyboard.from(rows).toJSON(),
            "{\"keyboard\":[[{\"text\":\"a\"},{\"text\":\"b\"}],[{\"text\":\"c\"},{\"text\":\"d\"}]]}"
        )
    }

    @TestCase
    public func keyboardLayoutMethodsAreGoldenAndCloneDoesNotAlias(): Unit {
        let keyboard = Keyboard()
            .text("A")
            .text("B")
            .row()
            .text("C")
            .row()
            .text("D")
            .text("E")

        let clone = keyboard.clone()
        clone.text("Z")

        let rows = ArrayList<ArrayList<KeyboardButton>>()
        let row = ArrayList<KeyboardButton>()
        row.add(Keyboard.textButton("X"))
        row.add(Keyboard.requestLocationButton("Loc"))
        rows.add(row)
        let appended = Keyboard().text("Root").append(Keyboard.from(rows))

        @Expect(
            keyboard.toTransposed().toJSON(),
            "{\"keyboard\":[[{\"text\":\"A\"},{\"text\":\"C\"},{\"text\":\"D\"}],[{\"text\":\"B\"},{\"text\":\"E\"}]]}"
        )
        @Expect(
            keyboard.toFlowed(2).toJSON(),
            "{\"keyboard\":[[{\"text\":\"A\"},{\"text\":\"B\"}],[{\"text\":\"C\"},{\"text\":\"D\"}],[{\"text\":\"E\"}]]}"
        )
        @Expect(
            keyboard.toFlowed(3, true).toJSON(),
            "{\"keyboard\":[[{\"text\":\"A\"},{\"text\":\"B\"}],[{\"text\":\"C\"},{\"text\":\"D\"},{\"text\":\"E\"}]]}"
        )
        @Expect(
            keyboard.toJSON(),
            "{\"keyboard\":[[{\"text\":\"A\"},{\"text\":\"B\"}],[{\"text\":\"C\"}],[{\"text\":\"D\"},{\"text\":\"E\"}]]}"
        )
        @Expect(
            clone.toJSON(),
            "{\"keyboard\":[[{\"text\":\"A\"},{\"text\":\"B\"}],[{\"text\":\"C\"}],[{\"text\":\"D\"},{\"text\":\"E\"},{\"text\":\"Z\"}]]}"
        )
        @Expect(
            appended.toJSON(),
            "{\"keyboard\":[[{\"text\":\"Root\"}],[{\"text\":\"X\"},{\"text\":\"Loc\",\"request_location\":true}]]}"
        )
    }

    @TestCase
    public func keyboardButtonsExposeMutuallyExclusiveActionFields(): Unit {
        let contact = Keyboard.requestContactButton("contact")
        let location = Keyboard.requestLocationButton("location")
        let poll = Keyboard.requestPollButton("poll", "quiz")
        let users = Keyboard.requestUsersButton("users", 10)
        let chat = Keyboard.requestChatButton("chat", 11)
        let managed = Keyboard.requestManagedBotButton("bot", 12)
        let web = Keyboard.webAppButton("web", "https://example.test/app")

        let golden = contact.toJSON() + "\n" +
            location.toJSON() + "\n" +
            poll.toJSON() + "\n" +
            users.toJSON() + "\n" +
            chat.toJSON() + "\n" +
            managed.toJSON() + "\n" +
            web.toJSON()
        let actionCount = contact.actionFieldCount() + location.actionFieldCount() + poll.actionFieldCount() +
            users.actionFieldCount() + chat.actionFieldCount() + managed.actionFieldCount() + web.actionFieldCount()

        @Expect(actionCount, 7)
        @Expect(contact.schemaIsValid(), true)
        let invalid = TelegramObject()
        invalid.addString("text", "bad")
        invalid.addBool("request_contact", true)
        invalid.addBool("request_location", true)
        @Expect(contact.schema().isValid(invalid), false)
        @Expect(
            golden,
            "{\"text\":\"contact\",\"request_contact\":true}\n" +
                "{\"text\":\"location\",\"request_location\":true}\n" +
                "{\"text\":\"poll\",\"request_poll\":{\"type\":\"quiz\"}}\n" +
                "{\"text\":\"users\",\"request_users\":{\"request_id\":10}}\n" +
                "{\"text\":\"chat\",\"request_chat\":{\"request_id\":11,\"chat_is_channel\":false}}\n" +
                "{\"text\":\"bot\",\"request_managed_bot\":{\"request_id\":12}}\n" +
                "{\"text\":\"web\",\"web_app\":{\"url\":\"https://example.test/app\"}}"
        )
    }

    @TestCase
    public func keyboardSupportsUpstreamButtonSourcesOptionsAndStringRows(): Unit {
        let common = TelegramObject()
        common.addString("style", "primary")
        common.addString("icon_custom_emoji_id", "emoji-id")

        let userOptions = TelegramObject()
        userOptions.addBool("user_is_bot", true)

        let chatOptions = TelegramObject()
        chatOptions.addBool("chat_is_channel", true)

        let rows = ArrayList<ArrayList<String>>()
        let row = ArrayList<String>()
        row.add("a")
        row.add("b")
        rows.add(row)

        let keyboard = Keyboard.from(rows)
            .row(
                Keyboard.requestContactButton(Keyboard.textButton("contact", common)),
                Keyboard.requestUsersButton(Keyboard.textButton("users", common), 12, userOptions),
                Keyboard.requestChatButton(Keyboard.textButton("chat", common), 42, chatOptions)
            )
            .row(
                Keyboard.requestPollButton(Keyboard.textButton("poll", common), "regular"),
                Keyboard.requestManagedBotButton(Keyboard.textButton("bot", common), 96),
                Keyboard.webAppButton(Keyboard.textButton("web", common), "https://grammy.dev")
            )

        @Expect(
            keyboard.toJSON(),
            "{\"keyboard\":[[{\"text\":\"a\"},{\"text\":\"b\"}],[{\"text\":\"contact\",\"style\":\"primary\",\"icon_custom_emoji_id\":\"emoji-id\",\"request_contact\":true},{\"text\":\"users\",\"style\":\"primary\",\"icon_custom_emoji_id\":\"emoji-id\",\"request_users\":{\"request_id\":12,\"user_is_bot\":true}},{\"text\":\"chat\",\"style\":\"primary\",\"icon_custom_emoji_id\":\"emoji-id\",\"request_chat\":{\"request_id\":42,\"chat_is_channel\":true}}],[{\"text\":\"poll\",\"style\":\"primary\",\"icon_custom_emoji_id\":\"emoji-id\",\"request_poll\":{\"type\":\"regular\"}},{\"text\":\"bot\",\"style\":\"primary\",\"icon_custom_emoji_id\":\"emoji-id\",\"request_managed_bot\":{\"request_id\":96}},{\"text\":\"web\",\"style\":\"primary\",\"icon_custom_emoji_id\":\"emoji-id\",\"web_app\":{\"url\":\"https://grammy.dev\"}}]]}"
        )
    }
}

@Test
public class InlineKeyboardBuilderTest {
    @TestCase
    public func upstreamInlineKeyboard001TakesInitialButtonsGolden(): Unit {
        let rows = ArrayList<ArrayList<InlineKeyboardButton>>()
        let first = ArrayList<InlineKeyboardButton>()
        first.add(InlineKeyboard.textButton("text", "data"))
        let second = ArrayList<InlineKeyboardButton>()
        second.add(InlineKeyboard.textButton("text", "data"))
        second.add(InlineKeyboard.textButton("text", "data"))
        rows.add(first)
        rows.add(second)

        @Expect(
            InlineKeyboard(rows).toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"text\",\"callback_data\":\"data\"}],[{\"text\":\"text\",\"callback_data\":\"data\"},{\"text\":\"text\",\"callback_data\":\"data\"}]]}"
        )
    }

    @TestCase
    public func upstreamInlineKeyboard002CreatesRowsAndColumnsGolden(): Unit {
        let rows = ArrayList<ArrayList<InlineKeyboardButton>>()
        let row = ArrayList<InlineKeyboardButton>()
        row.add(InlineKeyboard.textButton("text", "data"))
        rows.add(row)

        let button = InlineKeyboard.textButton("text", "data")
        let keyboard = InlineKeyboard(rows)
            .add(button, button)
            .row()
            .add(button, button)
            .add(button)

        @Expect(
            keyboard.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"text\",\"callback_data\":\"data\"},{\"text\":\"text\",\"callback_data\":\"data\"},{\"text\":\"text\",\"callback_data\":\"data\"}],[{\"text\":\"text\",\"callback_data\":\"data\"},{\"text\":\"text\",\"callback_data\":\"data\"},{\"text\":\"text\",\"callback_data\":\"data\"}]]}"
        )
    }

    @TestCase
    public func inlineKeyboardBuildsRowsStylesAndActions(): Unit {
        let keyboard = InlineKeyboard()
            .text("A", "a")
            .url("Docs", "https://example.test")
            .row()
            .copyText("Copy", "value")
            .primary()
            .icon("icon-copy")

        @Expect(
            keyboard.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"A\",\"callback_data\":\"a\"},{\"text\":\"Docs\",\"url\":\"https://example.test\"}],[{\"text\":\"Copy\",\"style\":\"primary\",\"icon_custom_emoji_id\":\"icon-copy\",\"copy_text\":{\"text\":\"value\"}}]]}"
        )
        @Expect(keyboard.schemaIsValid(), true)
    }

    @TestCase
    public func upstreamInlineKeyboard003CreatedFromDataSourcesGolden(): Unit {
        let rows = ArrayList<ArrayList<InlineKeyboardButton>>()
        let first = ArrayList<InlineKeyboardButton>()
        first.add(InlineKeyboard.textButton("a"))
        first.add(InlineKeyboard.textButton("b"))
        let second = ArrayList<InlineKeyboardButton>()
        second.add(InlineKeyboard.textButton("c"))
        second.add(InlineKeyboard.textButton("d"))
        rows.add(first)
        rows.add(second)

        let keyboard = InlineKeyboard().text("button")
        let clone = InlineKeyboard.from(keyboard)
        clone.text("copy")

        @Expect(
            InlineKeyboard.from(rows).toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"a\",\"callback_data\":\"a\"},{\"text\":\"b\",\"callback_data\":\"b\"}],[{\"text\":\"c\",\"callback_data\":\"c\"},{\"text\":\"d\",\"callback_data\":\"d\"}]]}"
        )
        @Expect(
            keyboard.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"button\",\"callback_data\":\"button\"}]]}"
        )
        @Expect(
            clone.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"button\",\"callback_data\":\"button\"},{\"text\":\"copy\",\"callback_data\":\"copy\"}]]}"
        )
    }

    @TestCase
    public func inlineKeyboardLayoutMethodsAreGoldenAndCloneDoesNotAlias(): Unit {
        let keyboard = InlineKeyboard()
            .text("A", "a")
            .text("B", "b")
            .row()
            .url("C", "https://c.test")
            .row()
            .pay("D")
            .game("E")

        let clone = keyboard.clone()
        clone.text("Z", "z")

        let rows = ArrayList<ArrayList<InlineKeyboardButton>>()
        let row = ArrayList<InlineKeyboardButton>()
        row.add(InlineKeyboard.urlButton("X", "https://x.test"))
        row.add(InlineKeyboard.textButton("Y", "y"))
        rows.add(row)
        let appended = InlineKeyboard().text("Root", "root").append(InlineKeyboard.from(rows))

        @Expect(
            keyboard.toTransposed().toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"A\",\"callback_data\":\"a\"},{\"text\":\"C\",\"url\":\"https://c.test\"},{\"text\":\"D\",\"pay\":true}],[{\"text\":\"B\",\"callback_data\":\"b\"},{\"text\":\"E\",\"callback_game\":{}}]]}"
        )
        @Expect(
            keyboard.toFlowed(2).toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"A\",\"callback_data\":\"a\"},{\"text\":\"B\",\"callback_data\":\"b\"}],[{\"text\":\"C\",\"url\":\"https://c.test\"},{\"text\":\"D\",\"pay\":true}],[{\"text\":\"E\",\"callback_game\":{}}]]}"
        )
        @Expect(
            keyboard.toFlowed(3, true).toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"A\",\"callback_data\":\"a\"},{\"text\":\"B\",\"callback_data\":\"b\"}],[{\"text\":\"C\",\"url\":\"https://c.test\"},{\"text\":\"D\",\"pay\":true},{\"text\":\"E\",\"callback_game\":{}}]]}"
        )
        @Expect(
            keyboard.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"A\",\"callback_data\":\"a\"},{\"text\":\"B\",\"callback_data\":\"b\"}],[{\"text\":\"C\",\"url\":\"https://c.test\"}],[{\"text\":\"D\",\"pay\":true},{\"text\":\"E\",\"callback_game\":{}}]]}"
        )
        @Expect(
            clone.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"A\",\"callback_data\":\"a\"},{\"text\":\"B\",\"callback_data\":\"b\"}],[{\"text\":\"C\",\"url\":\"https://c.test\"}],[{\"text\":\"D\",\"pay\":true},{\"text\":\"E\",\"callback_game\":{}},{\"text\":\"Z\",\"callback_data\":\"z\"}]]}"
        )
        @Expect(
            appended.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"Root\",\"callback_data\":\"root\"}],[{\"text\":\"X\",\"url\":\"https://x.test\"},{\"text\":\"Y\",\"callback_data\":\"y\"}]]}"
        )
    }

    @TestCase
    public func inlineKeyboardButtonsExposeMutuallyExclusiveActionFields(): Unit {
        let chosen = TelegramObject()
        chosen.addString("query", "pick")
        chosen.addBool("allow_bot_chats", true)

        let url = InlineKeyboard.urlButton("url", "https://example.test")
        let callback = InlineKeyboard.textButton("callback", "data")
        let web = InlineKeyboard.webAppButton("web", "https://example.test/app")
        let login = InlineKeyboard.loginButton("login", "https://example.test/login")
        let switchInline = InlineKeyboard.switchInlineButton("switch", "query")
        let current = InlineKeyboard.switchInlineCurrentButton("current", "here")
        let chosenButton = InlineKeyboard.switchInlineChosenButton("chosen", chosen)
        let copy = InlineKeyboard.copyTextButton("copy", "value")
        let game = InlineKeyboard.gameButton("game")
        let pay = InlineKeyboard.payButton("pay")

        let golden = url.toJSON() + "\n" +
            callback.toJSON() + "\n" +
            web.toJSON() + "\n" +
            login.toJSON() + "\n" +
            switchInline.toJSON() + "\n" +
            current.toJSON() + "\n" +
            chosenButton.toJSON() + "\n" +
            copy.toJSON() + "\n" +
            game.toJSON() + "\n" +
            pay.toJSON()
        let actionCount = url.actionFieldCount() + callback.actionFieldCount() + web.actionFieldCount() +
            login.actionFieldCount() + switchInline.actionFieldCount() + current.actionFieldCount() +
            chosenButton.actionFieldCount() + copy.actionFieldCount() + game.actionFieldCount() + pay.actionFieldCount()

        @Expect(actionCount, 10)
        @Expect(copy.schemaIsValid(), true)
        let invalid = TelegramObject()
        invalid.addString("text", "bad")
        invalid.addString("url", "https://example.test")
        invalid.addString("callback_data", "data")
        @Expect(copy.schema().isValid(invalid), false)
        @Expect(
            golden,
            "{\"text\":\"url\",\"url\":\"https://example.test\"}\n" +
                "{\"text\":\"callback\",\"callback_data\":\"data\"}\n" +
                "{\"text\":\"web\",\"web_app\":{\"url\":\"https://example.test/app\"}}\n" +
                "{\"text\":\"login\",\"login_url\":{\"url\":\"https://example.test/login\"}}\n" +
                "{\"text\":\"switch\",\"switch_inline_query\":\"query\"}\n" +
                "{\"text\":\"current\",\"switch_inline_query_current_chat\":\"here\"}\n" +
                "{\"text\":\"chosen\",\"switch_inline_query_chosen_chat\":{\"query\":\"pick\",\"allow_bot_chats\":true}}\n" +
                "{\"text\":\"copy\",\"copy_text\":{\"text\":\"value\"}}\n" +
                "{\"text\":\"game\",\"callback_game\":{}}\n" +
                "{\"text\":\"pay\",\"pay\":true}"
        )
    }

    @TestCase
    public func inlineKeyboardSupportsUpstreamButtonSourcesAndObjectOptions(): Unit {
        let common = TelegramObject()
        common.addString("style", "danger")
        common.addString("icon_custom_emoji_id", "emoji-id")

        let login = TelegramObject()
        login.addString("url", "https://grammy.dev/login")
        login.addString("forward_text", "forward")
        login.addBool("request_write_access", true)

        let webApp = TelegramObject()
        webApp.addString("url", "https://grammy.dev/app")

        let chosen = TelegramObject()
        chosen.addBool("allow_bot_chats", true)

        let copy = TelegramObject()
        copy.addString("text", "copy-value")

        let keyboard = InlineKeyboard()
            .url(InlineKeyboardButton("url", common), "https://grammy.dev")
            .text(InlineKeyboardButton("callback", common))
            .webApp(InlineKeyboardButton("web", common), webApp)
            .login(InlineKeyboardButton("login", common), login)
            .switchInline(InlineKeyboardButton("switch", common))
            .switchInlineCurrent(InlineKeyboardButton("current", common), "query")
            .switchInlineChosen(InlineKeyboardButton("chosen", common), chosen)
            .copyText(InlineKeyboardButton("copy", common), copy)
            .game(InlineKeyboardButton("game", common))
            .pay(InlineKeyboardButton("pay", common))

        @Expect(
            keyboard.toJSON(),
            "{\"inline_keyboard\":[[{\"text\":\"url\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"url\":\"https://grammy.dev\"},{\"text\":\"callback\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"callback_data\":\"callback\"},{\"text\":\"web\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"web_app\":{\"url\":\"https://grammy.dev/app\"}},{\"text\":\"login\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"login_url\":{\"url\":\"https://grammy.dev/login\",\"forward_text\":\"forward\",\"request_write_access\":true}},{\"text\":\"switch\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"switch_inline_query\":\"\"},{\"text\":\"current\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"switch_inline_query_current_chat\":\"query\"},{\"text\":\"chosen\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"switch_inline_query_chosen_chat\":{\"allow_bot_chats\":true}},{\"text\":\"copy\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"copy_text\":{\"text\":\"copy-value\"}},{\"text\":\"game\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"callback_game\":{}},{\"text\":\"pay\",\"style\":\"danger\",\"icon_custom_emoji_id\":\"emoji-id\",\"pay\":true}]]}"
        )
    }
}
