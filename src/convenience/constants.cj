package grammy4cj.convenience

public class APIConstants {
    public let defaultUpdateTypeCount: Int64
    public let maxInlineKeyboardColumns: Int64

    public init(defaultUpdateTypeCount: Int64, maxInlineKeyboardColumns: Int64) {
        this.defaultUpdateTypeCount = defaultUpdateTypeCount
        this.maxInlineKeyboardColumns = maxInlineKeyboardColumns
    }
}

public let API_CONSTANTS: APIConstants = APIConstants(23, 8)
