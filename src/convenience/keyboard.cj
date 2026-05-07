package grammy4cj.convenience

import std.collection.ArrayList

public class KeyboardButton {
    public let text: String
    public var style: String
    public var iconCustomEmojiId: String
    public var actionName: String
    public var actionValue: TelegramValue

    public init(text: String) {
        this.text = text
        this.style = ""
        this.iconCustomEmojiId = ""
        this.actionName = ""
        this.actionValue = rawValue("null")
    }

    public init(text: String, style: String) {
        this.text = text
        this.style = style
        this.iconCustomEmojiId = ""
        this.actionName = ""
        this.actionValue = rawValue("null")
    }

    public func withAction(actionName: String, actionValue: TelegramValue): KeyboardButton {
        let button = this.copyBase()
        button.actionName = actionName
        button.actionValue = actionValue.copy()
        button
    }

    public func copyBase(): KeyboardButton {
        let button = KeyboardButton(this.text)
        button.style = this.style
        button.iconCustomEmojiId = this.iconCustomEmojiId
        button
    }

    public func copy(): KeyboardButton {
        let button = this.copyBase()
        button.actionName = this.actionName
        button.actionValue = this.actionValue.copy()
        button
    }

    public func actionFieldCount(): Int64 {
        if (this.actionName.isEmpty()) {
            return 0
        }
        1
    }

    public func toTelegramObject(): TelegramObject {
        let object = TelegramObject()
        object.addString("text", this.text)
        object.addNonEmptyString("style", this.style)
        object.addNonEmptyString("icon_custom_emoji_id", this.iconCustomEmojiId)
        if (!this.actionName.isEmpty()) {
            object.addValue(this.actionName, this.actionValue.copy())
        }
        object
    }

    public func toJSON(): String {
        this.toTelegramObject().toJSON()
    }
}

public class InlineKeyboardButton {
    public let text: String
    public var style: String
    public var iconCustomEmojiId: String
    public var actionName: String
    public var actionValue: TelegramValue

    public init(text: String) {
        this.text = text
        this.style = ""
        this.iconCustomEmojiId = ""
        this.actionName = ""
        this.actionValue = rawValue("null")
    }

    public init(text: String, style: String) {
        this.text = text
        this.style = style
        this.iconCustomEmojiId = ""
        this.actionName = ""
        this.actionValue = rawValue("null")
    }

    public func withAction(actionName: String, actionValue: TelegramValue): InlineKeyboardButton {
        let button = this.copyBase()
        button.actionName = actionName
        button.actionValue = actionValue.copy()
        button
    }

    public func copyBase(): InlineKeyboardButton {
        let button = InlineKeyboardButton(this.text)
        button.style = this.style
        button.iconCustomEmojiId = this.iconCustomEmojiId
        button
    }

    public func copy(): InlineKeyboardButton {
        let button = this.copyBase()
        button.actionName = this.actionName
        button.actionValue = this.actionValue.copy()
        button
    }

    public func actionFieldCount(): Int64 {
        if (this.actionName.isEmpty()) {
            return 0
        }
        1
    }

    public func toTelegramObject(): TelegramObject {
        let object = TelegramObject()
        object.addString("text", this.text)
        object.addNonEmptyString("style", this.style)
        object.addNonEmptyString("icon_custom_emoji_id", this.iconCustomEmojiId)
        if (!this.actionName.isEmpty()) {
            object.addValue(this.actionName, this.actionValue.copy())
        }
        object
    }

    public func toJSON(): String {
        this.toTelegramObject().toJSON()
    }
}

public class Keyboard {
    public var keyboard: ArrayList<ArrayList<KeyboardButton>> = ArrayList<ArrayList<KeyboardButton>>()
    public var buttonCount: Int64 = 0
    public var hasPersistent: Bool = false
    public var isPersistent: Bool = false
    public var hasSelective: Bool = false
    public var selective: Bool = false
    public var hasOneTime: Bool = false
    public var oneTimeKeyboard: Bool = false
    public var hasResize: Bool = false
    public var resizeKeyboard: Bool = false
    public var inputFieldPlaceholder: String = ""

    public init() {
        this.keyboard.add(ArrayList<KeyboardButton>())
    }

    public init(buttonCount: Int64) {
        this.keyboard.add(ArrayList<KeyboardButton>())
        this.buttonCount = buttonCount
    }

    public init(keyboard: ArrayList<ArrayList<KeyboardButton>>) {
        this.keyboard = copyKeyboardGrid(keyboard)
        this.buttonCount = countKeyboardButtons(this.keyboard)
    }

    public func add(button: KeyboardButton): Keyboard {
        this.currentRow().add(button.copy())
        this.buttonCount += 1
        this
    }

    public func add(first: KeyboardButton, second: KeyboardButton): Keyboard {
        this.add(first)
        this.add(second)
    }

    public func add(first: KeyboardButton, second: KeyboardButton, third: KeyboardButton): Keyboard {
        this.add(first)
        this.add(second)
        this.add(third)
    }

    public func row(): Keyboard {
        this.keyboard.add(ArrayList<KeyboardButton>())
        this
    }

    public func row(button: KeyboardButton): Keyboard {
        this.row()
        this.add(button)
    }

    public func row(first: KeyboardButton, second: KeyboardButton): Keyboard {
        this.row()
        this.add(first)
        this.add(second)
    }

    public func text(text: String): Keyboard {
        this.add(Keyboard.textButton(text))
    }

    public func text(text: String, style: String): Keyboard {
        this.add(Keyboard.textButton(text, style))
    }

    public static func textButton(text: String): KeyboardButton {
        KeyboardButton(text)
    }

    public static func textButton(text: String, style: String): KeyboardButton {
        KeyboardButton(text, style)
    }

    public func requestContact(text: String): Keyboard {
        this.add(Keyboard.requestContactButton(text))
    }

    public static func requestContactButton(text: String): KeyboardButton {
        Keyboard.textButton(text).withAction("request_contact", rawValue("true"))
    }

    public static func requestContactButton(button: KeyboardButton): KeyboardButton {
        button.withAction("request_contact", rawValue("true"))
    }

    public func requestLocation(text: String): Keyboard {
        this.add(Keyboard.requestLocationButton(text))
    }

    public static func requestLocationButton(text: String): KeyboardButton {
        Keyboard.textButton(text).withAction("request_location", rawValue("true"))
    }

    public static func requestLocationButton(button: KeyboardButton): KeyboardButton {
        button.withAction("request_location", rawValue("true"))
    }

    public func requestPoll(text: String): Keyboard {
        this.add(Keyboard.requestPollButton(text))
    }

    public func requestPoll(text: String, pollType: String): Keyboard {
        this.add(Keyboard.requestPollButton(text, pollType))
    }

    public static func requestPollButton(text: String): KeyboardButton {
        Keyboard.textButton(text).withAction("request_poll", objectValue(TelegramObject()))
    }

    public static func requestPollButton(text: String, pollType: String): KeyboardButton {
        let poll = TelegramObject()
        poll.addString("type", pollType)
        Keyboard.textButton(text).withAction("request_poll", objectValue(poll))
    }

    public func requestUsers(text: String, requestId: Int64): Keyboard {
        this.add(Keyboard.requestUsersButton(text, requestId))
    }

    public func requestUsers(text: String, requestId: Int64, options: TelegramObject): Keyboard {
        this.add(Keyboard.requestUsersButton(text, requestId, options))
    }

    public static func requestUsersButton(text: String, requestId: Int64): KeyboardButton {
        Keyboard.requestUsersButton(text, requestId, TelegramObject())
    }

    public static func requestUsersButton(text: String, requestId: Int64, options: TelegramObject): KeyboardButton {
        let requestUsers = TelegramObject()
        requestUsers.addInt("request_id", requestId)
        requestUsers.addAll(options)
        Keyboard.textButton(text).withAction("request_users", objectValue(requestUsers))
    }

    public func requestChat(text: String, requestId: Int64): Keyboard {
        this.add(Keyboard.requestChatButton(text, requestId))
    }

    public func requestChat(text: String, requestId: Int64, options: TelegramObject): Keyboard {
        this.add(Keyboard.requestChatButton(text, requestId, options))
    }

    public static func requestChatButton(text: String, requestId: Int64): KeyboardButton {
        let options = TelegramObject()
        options.addBool("chat_is_channel", false)
        Keyboard.requestChatButton(text, requestId, options)
    }

    public static func requestChatButton(text: String, requestId: Int64, options: TelegramObject): KeyboardButton {
        let requestChat = TelegramObject()
        requestChat.addInt("request_id", requestId)
        requestChat.addAll(options)
        Keyboard.textButton(text).withAction("request_chat", objectValue(requestChat))
    }

    public func requestManagedBot(text: String, requestId: Int64): Keyboard {
        this.add(Keyboard.requestManagedBotButton(text, requestId))
    }

    public func requestManagedBot(text: String, requestId: Int64, options: TelegramObject): Keyboard {
        this.add(Keyboard.requestManagedBotButton(text, requestId, options))
    }

    public static func requestManagedBotButton(text: String, requestId: Int64): KeyboardButton {
        Keyboard.requestManagedBotButton(text, requestId, TelegramObject())
    }

    public static func requestManagedBotButton(text: String, requestId: Int64, options: TelegramObject): KeyboardButton {
        let requestManagedBot = TelegramObject()
        requestManagedBot.addInt("request_id", requestId)
        requestManagedBot.addAll(options)
        Keyboard.textButton(text).withAction("request_managed_bot", objectValue(requestManagedBot))
    }

    public func webApp(text: String, url: String): Keyboard {
        this.add(Keyboard.webAppButton(text, url))
    }

    public static func webAppButton(text: String, url: String): KeyboardButton {
        let webApp = TelegramObject()
        webApp.addString("url", url)
        Keyboard.textButton(text).withAction("web_app", objectValue(webApp))
    }

    public func style(style: String): Keyboard {
        let button = this.lastButton("Need to add a button before applying a style!")
        button.style = style
        this
    }

    public func danger(): Keyboard {
        this.style("danger")
    }

    public func success(): Keyboard {
        this.style("success")
    }

    public func primary(): Keyboard {
        this.style("primary")
    }

    public func icon(icon: String): Keyboard {
        let button = this.lastButton("Need to add a button before adding an icon!")
        button.iconCustomEmojiId = icon
        this
    }

    public func persistent(): Keyboard {
        this.persistent(true)
    }

    public func persistent(isEnabled: Bool): Keyboard {
        this.hasPersistent = true
        this.isPersistent = isEnabled
        this
    }

    public func selected(): Keyboard {
        this.selected(true)
    }

    public func selected(isEnabled: Bool): Keyboard {
        this.hasSelective = true
        this.selective = isEnabled
        this
    }

    public func oneTime(): Keyboard {
        this.oneTime(true)
    }

    public func oneTime(isEnabled: Bool): Keyboard {
        this.hasOneTime = true
        this.oneTimeKeyboard = isEnabled
        this
    }

    public func resized(): Keyboard {
        this.resized(true)
    }

    public func resized(isEnabled: Bool): Keyboard {
        this.hasResize = true
        this.resizeKeyboard = isEnabled
        this
    }

    public func placeholder(value: String): Keyboard {
        this.inputFieldPlaceholder = value
        this
    }

    public func toTransposed(): Keyboard {
        this.cloneWithGrid(transposeKeyboardGrid(this.keyboard))
    }

    public func toFlowed(columns: Int64): Keyboard {
        this.toFlowed(columns, false)
    }

    public func toFlowed(columns: Int64, fillLastRow: Bool): Keyboard {
        this.cloneWithGrid(reflowKeyboardGrid(this.keyboard, columns, fillLastRow))
    }

    public func clone(): Keyboard {
        this.cloneWithGrid(this.keyboard)
    }

    public func cloneWithGrid(keyboard: ArrayList<ArrayList<KeyboardButton>>): Keyboard {
        let cloned = Keyboard(keyboard)
        cloned.hasPersistent = this.hasPersistent
        cloned.isPersistent = this.isPersistent
        cloned.hasSelective = this.hasSelective
        cloned.selective = this.selective
        cloned.hasOneTime = this.hasOneTime
        cloned.oneTimeKeyboard = this.oneTimeKeyboard
        cloned.hasResize = this.hasResize
        cloned.resizeKeyboard = this.resizeKeyboard
        cloned.inputFieldPlaceholder = this.inputFieldPlaceholder
        cloned
    }

    public func append(source: Keyboard): Keyboard {
        for (row in source.keyboard) {
            let next = ArrayList<KeyboardButton>()
            for (button in row) {
                next.add(button.copy())
            }
            this.keyboard.add(next)
            this.buttonCount += next.size
        }
        this
    }

    public static func from(source: Keyboard): Keyboard {
        source.clone()
    }

    public static func from(source: ArrayList<ArrayList<KeyboardButton>>): Keyboard {
        Keyboard(source)
    }

    public func build(): ArrayList<ArrayList<KeyboardButton>> {
        copyKeyboardGrid(this.keyboard)
    }

    public func toTelegramObject(): TelegramObject {
        let object = TelegramObject()
        object.addArray("keyboard", keyboardGridValue(this.keyboard))
        if (this.hasPersistent) {
            object.addBool("is_persistent", this.isPersistent)
        }
        if (this.hasSelective) {
            object.addBool("selective", this.selective)
        }
        if (this.hasOneTime) {
            object.addBool("one_time_keyboard", this.oneTimeKeyboard)
        }
        if (this.hasResize) {
            object.addBool("resize_keyboard", this.resizeKeyboard)
        }
        object.addNonEmptyString("input_field_placeholder", this.inputFieldPlaceholder)
        object
    }

    public func toJSON(): String {
        this.toTelegramObject().toJSON()
    }

    private func currentRow(): ArrayList<KeyboardButton> {
        if (this.keyboard.size == 0) {
            this.keyboard.add(ArrayList<KeyboardButton>())
        }
        this.keyboard[this.keyboard.size - 1]
    }

    private func lastButton(message: String): KeyboardButton {
        if (this.keyboard.size == 0) {
            throw Exception(message)
        }
        let row = this.keyboard[this.keyboard.size - 1]
        if (row.size == 0) {
            throw Exception(message)
        }
        row[row.size - 1]
    }
}

public class InlineKeyboard {
    public var inlineKeyboard: ArrayList<ArrayList<InlineKeyboardButton>> = ArrayList<ArrayList<InlineKeyboardButton>>()
    public var buttonCount: Int64 = 0

    public init() {
        this.inlineKeyboard.add(ArrayList<InlineKeyboardButton>())
    }

    public init(buttonCount: Int64) {
        this.inlineKeyboard.add(ArrayList<InlineKeyboardButton>())
        this.buttonCount = buttonCount
    }

    public init(inlineKeyboard: ArrayList<ArrayList<InlineKeyboardButton>>) {
        this.inlineKeyboard = copyInlineKeyboardGrid(inlineKeyboard)
        this.buttonCount = countInlineKeyboardButtons(this.inlineKeyboard)
    }

    public func add(button: InlineKeyboardButton): InlineKeyboard {
        this.currentRow().add(button.copy())
        this.buttonCount += 1
        this
    }

    public func add(first: InlineKeyboardButton, second: InlineKeyboardButton): InlineKeyboard {
        this.add(first)
        this.add(second)
    }

    public func add(first: InlineKeyboardButton, second: InlineKeyboardButton, third: InlineKeyboardButton): InlineKeyboard {
        this.add(first)
        this.add(second)
        this.add(third)
    }

    public func row(): InlineKeyboard {
        this.inlineKeyboard.add(ArrayList<InlineKeyboardButton>())
        this
    }

    public func row(button: InlineKeyboardButton): InlineKeyboard {
        this.row()
        this.add(button)
    }

    public func row(first: InlineKeyboardButton, second: InlineKeyboardButton): InlineKeyboard {
        this.row()
        this.add(first)
        this.add(second)
    }

    public func url(text: String, url: String): InlineKeyboard {
        this.add(InlineKeyboard.urlButton(text, url))
    }

    public static func urlButton(text: String, url: String): InlineKeyboardButton {
        InlineKeyboardButton(text).withAction("url", stringValue(url))
    }

    public static func urlButton(button: InlineKeyboardButton, url: String): InlineKeyboardButton {
        button.withAction("url", stringValue(url))
    }

    public func text(text: String): InlineKeyboard {
        this.add(InlineKeyboard.textButton(text))
    }

    public func text(text: String, data: String): InlineKeyboard {
        this.add(InlineKeyboard.textButton(text, data))
    }

    public static func textButton(text: String): InlineKeyboardButton {
        InlineKeyboard.textButton(text, text)
    }

    public static func textButton(text: String, data: String): InlineKeyboardButton {
        InlineKeyboardButton(text).withAction("callback_data", stringValue(data))
    }

    public static func textButton(button: InlineKeyboardButton, data: String): InlineKeyboardButton {
        button.withAction("callback_data", stringValue(data))
    }

    public func webApp(text: String, url: String): InlineKeyboard {
        this.add(InlineKeyboard.webAppButton(text, url))
    }

    public static func webAppButton(text: String, url: String): InlineKeyboardButton {
        let webApp = TelegramObject()
        webApp.addString("url", url)
        InlineKeyboardButton(text).withAction("web_app", objectValue(webApp))
    }

    public func login(text: String, url: String): InlineKeyboard {
        this.add(InlineKeyboard.loginButton(text, url))
    }

    public static func loginButton(text: String, url: String): InlineKeyboardButton {
        let loginUrl = TelegramObject()
        loginUrl.addString("url", url)
        InlineKeyboardButton(text).withAction("login_url", objectValue(loginUrl))
    }

    public func switchInline(text: String): InlineKeyboard {
        this.add(InlineKeyboard.switchInlineButton(text))
    }

    public func switchInline(text: String, query: String): InlineKeyboard {
        this.add(InlineKeyboard.switchInlineButton(text, query))
    }

    public static func switchInlineButton(text: String): InlineKeyboardButton {
        InlineKeyboard.switchInlineButton(text, "")
    }

    public static func switchInlineButton(text: String, query: String): InlineKeyboardButton {
        InlineKeyboardButton(text).withAction("switch_inline_query", stringValue(query))
    }

    public func switchInlineCurrent(text: String): InlineKeyboard {
        this.add(InlineKeyboard.switchInlineCurrentButton(text))
    }

    public func switchInlineCurrent(text: String, query: String): InlineKeyboard {
        this.add(InlineKeyboard.switchInlineCurrentButton(text, query))
    }

    public static func switchInlineCurrentButton(text: String): InlineKeyboardButton {
        InlineKeyboard.switchInlineCurrentButton(text, "")
    }

    public static func switchInlineCurrentButton(text: String, query: String): InlineKeyboardButton {
        InlineKeyboardButton(text).withAction("switch_inline_query_current_chat", stringValue(query))
    }

    public func switchInlineChosen(text: String): InlineKeyboard {
        this.add(InlineKeyboard.switchInlineChosenButton(text))
    }

    public func switchInlineChosen(text: String, query: TelegramObject): InlineKeyboard {
        this.add(InlineKeyboard.switchInlineChosenButton(text, query))
    }

    public static func switchInlineChosenButton(text: String): InlineKeyboardButton {
        InlineKeyboard.switchInlineChosenButton(text, TelegramObject())
    }

    public static func switchInlineChosenButton(text: String, query: TelegramObject): InlineKeyboardButton {
        InlineKeyboardButton(text).withAction("switch_inline_query_chosen_chat", objectValue(query))
    }

    public func copyText(text: String, copyText: String): InlineKeyboard {
        this.add(InlineKeyboard.copyTextButton(text, copyText))
    }

    public static func copyTextButton(text: String, copyText: String): InlineKeyboardButton {
        let copy = TelegramObject()
        copy.addString("text", copyText)
        InlineKeyboardButton(text).withAction("copy_text", objectValue(copy))
    }

    public func game(text: String): InlineKeyboard {
        this.add(InlineKeyboard.gameButton(text))
    }

    public static func gameButton(text: String): InlineKeyboardButton {
        InlineKeyboardButton(text).withAction("callback_game", objectValue(TelegramObject()))
    }

    public func pay(text: String): InlineKeyboard {
        this.add(InlineKeyboard.payButton(text))
    }

    public static func payButton(text: String): InlineKeyboardButton {
        InlineKeyboardButton(text).withAction("pay", rawValue("true"))
    }

    public func style(style: String): InlineKeyboard {
        let button = this.lastButton("Need to add a button before applying a style!")
        button.style = style
        this
    }

    public func danger(): InlineKeyboard {
        this.style("danger")
    }

    public func success(): InlineKeyboard {
        this.style("success")
    }

    public func primary(): InlineKeyboard {
        this.style("primary")
    }

    public func icon(icon: String): InlineKeyboard {
        let button = this.lastButton("Need to add a button before adding an icon!")
        button.iconCustomEmojiId = icon
        this
    }

    public func toTransposed(): InlineKeyboard {
        InlineKeyboard(transposeInlineKeyboardGrid(this.inlineKeyboard))
    }

    public func toFlowed(columns: Int64): InlineKeyboard {
        this.toFlowed(columns, false)
    }

    public func toFlowed(columns: Int64, fillLastRow: Bool): InlineKeyboard {
        InlineKeyboard(reflowInlineKeyboardGrid(this.inlineKeyboard, columns, fillLastRow))
    }

    public func clone(): InlineKeyboard {
        InlineKeyboard(this.inlineKeyboard)
    }

    public func append(source: InlineKeyboard): InlineKeyboard {
        for (row in source.inlineKeyboard) {
            let next = ArrayList<InlineKeyboardButton>()
            for (button in row) {
                next.add(button.copy())
            }
            this.inlineKeyboard.add(next)
            this.buttonCount += next.size
        }
        this
    }

    public static func from(source: InlineKeyboard): InlineKeyboard {
        source.clone()
    }

    public static func from(source: ArrayList<ArrayList<InlineKeyboardButton>>): InlineKeyboard {
        InlineKeyboard(source)
    }

    public func build(): ArrayList<ArrayList<InlineKeyboardButton>> {
        copyInlineKeyboardGrid(this.inlineKeyboard)
    }

    public func toTelegramObject(): TelegramObject {
        let object = TelegramObject()
        object.addArray("inline_keyboard", inlineKeyboardGridValue(this.inlineKeyboard))
        object
    }

    public func toJSON(): String {
        this.toTelegramObject().toJSON()
    }

    private func currentRow(): ArrayList<InlineKeyboardButton> {
        if (this.inlineKeyboard.size == 0) {
            this.inlineKeyboard.add(ArrayList<InlineKeyboardButton>())
        }
        this.inlineKeyboard[this.inlineKeyboard.size - 1]
    }

    private func lastButton(message: String): InlineKeyboardButton {
        if (this.inlineKeyboard.size == 0) {
            throw Exception(message)
        }
        let row = this.inlineKeyboard[this.inlineKeyboard.size - 1]
        if (row.size == 0) {
            throw Exception(message)
        }
        row[row.size - 1]
    }
}

private func copyKeyboardGrid(source: ArrayList<ArrayList<KeyboardButton>>): ArrayList<ArrayList<KeyboardButton>> {
    let copied = ArrayList<ArrayList<KeyboardButton>>()
    for (row in source) {
        let next = ArrayList<KeyboardButton>()
        for (button in row) {
            next.add(button.copy())
        }
        copied.add(next)
    }
    copied
}

private func copyInlineKeyboardGrid(source: ArrayList<ArrayList<InlineKeyboardButton>>): ArrayList<ArrayList<InlineKeyboardButton>> {
    let copied = ArrayList<ArrayList<InlineKeyboardButton>>()
    for (row in source) {
        let next = ArrayList<InlineKeyboardButton>()
        for (button in row) {
            next.add(button.copy())
        }
        copied.add(next)
    }
    copied
}

private func countKeyboardButtons(source: ArrayList<ArrayList<KeyboardButton>>): Int64 {
    var count: Int64 = 0
    for (row in source) {
        count += row.size
    }
    count
}

private func countInlineKeyboardButtons(source: ArrayList<ArrayList<InlineKeyboardButton>>): Int64 {
    var count: Int64 = 0
    for (row in source) {
        count += row.size
    }
    count
}

private func transposeKeyboardGrid(source: ArrayList<ArrayList<KeyboardButton>>): ArrayList<ArrayList<KeyboardButton>> {
    let transposed = ArrayList<ArrayList<KeyboardButton>>()
    for (row in source) {
        var column: Int64 = 0
        for (button in row) {
            while (transposed.size <= column) {
                transposed.add(ArrayList<KeyboardButton>())
            }
            transposed[column].add(button.copy())
            column += 1
        }
    }
    transposed
}

private func transposeInlineKeyboardGrid(source: ArrayList<ArrayList<InlineKeyboardButton>>): ArrayList<ArrayList<InlineKeyboardButton>> {
    let transposed = ArrayList<ArrayList<InlineKeyboardButton>>()
    for (row in source) {
        var column: Int64 = 0
        for (button in row) {
            while (transposed.size <= column) {
                transposed.add(ArrayList<InlineKeyboardButton>())
            }
            transposed[column].add(button.copy())
            column += 1
        }
    }
    transposed
}

private func reflowKeyboardGrid(
    source: ArrayList<ArrayList<KeyboardButton>>,
    columns: Int64,
    fillLastRow: Bool
): ArrayList<ArrayList<KeyboardButton>> {
    let reflowed = ArrayList<ArrayList<KeyboardButton>>()
    var first = columns
    if (fillLastRow) {
        first = countKeyboardButtons(source) % columns
    }
    for (row in source) {
        for (button in row) {
            if (reflowed.size == 0) {
                reflowed.add(ArrayList<KeyboardButton>())
            }
            let index = reflowed.size - 1
            let max = if (index == 0) { first } else { columns }
            if (reflowed[index].size == max) {
                reflowed.add(ArrayList<KeyboardButton>())
            }
            reflowed[reflowed.size - 1].add(button.copy())
        }
    }
    reflowed
}

private func reflowInlineKeyboardGrid(
    source: ArrayList<ArrayList<InlineKeyboardButton>>,
    columns: Int64,
    fillLastRow: Bool
): ArrayList<ArrayList<InlineKeyboardButton>> {
    let reflowed = ArrayList<ArrayList<InlineKeyboardButton>>()
    var first = columns
    if (fillLastRow) {
        first = countInlineKeyboardButtons(source) % columns
    }
    for (row in source) {
        for (button in row) {
            if (reflowed.size == 0) {
                reflowed.add(ArrayList<InlineKeyboardButton>())
            }
            let index = reflowed.size - 1
            let max = if (index == 0) { first } else { columns }
            if (reflowed[index].size == max) {
                reflowed.add(ArrayList<InlineKeyboardButton>())
            }
            reflowed[reflowed.size - 1].add(button.copy())
        }
    }
    reflowed
}

private func keyboardGridValue(source: ArrayList<ArrayList<KeyboardButton>>): TelegramValue {
    let grid = arrayValue()
    for (row in source) {
        let rowValue = arrayValue()
        for (button in row) {
            rowValue.items.add(button.toTelegramObject().toValue())
        }
        grid.items.add(rowValue)
    }
    grid
}

private func inlineKeyboardGridValue(source: ArrayList<ArrayList<InlineKeyboardButton>>): TelegramValue {
    let grid = arrayValue()
    for (row in source) {
        let rowValue = arrayValue()
        for (button in row) {
            rowValue.items.add(button.toTelegramObject().toValue())
        }
        grid.items.add(rowValue)
    }
    grid
}
