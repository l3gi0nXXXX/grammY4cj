package grammy4cj.convenience

import std.collection.ArrayList
import std.unittest.*

@Test
public class KeyboardBuilderTest {
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
}

@Test
public class InlineKeyboardBuilderTest {
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
}
