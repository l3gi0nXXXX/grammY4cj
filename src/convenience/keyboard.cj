package grammy4cj.convenience

public class Keyboard {
    public let buttonCount: Int64

    public init() {
        this.buttonCount = 0
    }

    public init(buttonCount: Int64) {
        this.buttonCount = buttonCount
    }
}

public class InlineKeyboard {
    public let buttonCount: Int64

    public init() {
        this.buttonCount = 0
    }

    public init(buttonCount: Int64) {
        this.buttonCount = buttonCount
    }
}
