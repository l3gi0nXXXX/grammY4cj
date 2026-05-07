package grammy4cj.types

public class ResponseParameters {
    public let migrateToChatId: Int64
    public let retryAfter: Int64

    public init() {
        this.migrateToChatId = 0
        this.retryAfter = 0
    }

    public init(migrateToChatId: Int64, retryAfter: Int64) {
        this.migrateToChatId = migrateToChatId
        this.retryAfter = retryAfter
    }
}

public class ApiError {
    public let errorCode: Int64
    public let description: String
    public let parameters: ResponseParameters

    public init(errorCode: Int64, description: String, parameters: ResponseParameters) {
        this.errorCode = errorCode
        this.description = description
        this.parameters = parameters
    }
}

public class ApiResponse {
    public let ok: Bool
    public let result: String
    public let error: ApiError

    public init(ok: Bool, result: String, error: ApiError) {
        this.ok = ok
        this.result = result
        this.error = error
    }

    public static func success(result: String): ApiResponse {
        ApiResponse(true, result, ApiError(0, "", ResponseParameters()))
    }

    public static func failure(errorCode: Int64, description: String, parameters: ResponseParameters): ApiResponse {
        ApiResponse(false, "", ApiError(errorCode, description, parameters))
    }
}

public class User {
    public let id: Int64
    public let isBot: Bool
    public let firstName: String
    public let username: String

    public init(id: Int64, isBot: Bool, firstName: String, username: String) {
        this.id = id
        this.isBot = isBot
        this.firstName = firstName
        this.username = username
    }
}

public class UserFromGetMe {
    public let id: Int64
    public let isBot: Bool
    public let firstName: String
    public let username: String

    public init(id: Int64, isBot: Bool, firstName: String, username: String) {
        this.id = id
        this.isBot = isBot
        this.firstName = firstName
        this.username = username
    }
}

public class Chat {
    public let id: Int64
    public let kind: String

    public init(id: Int64, kind: String) {
        this.id = id
        this.kind = kind
    }
}

public class Message {
    public let messageId: Int64
    public let chat: Chat
    public let text: String

    public init(messageId: Int64, chat: Chat, text: String) {
        this.messageId = messageId
        this.chat = chat
        this.text = text
    }
}

public class Update {
    public let updateId: Int64
    public let kind: String

    public init(updateId: Int64) {
        this.updateId = updateId
        this.kind = ""
    }

    public init(updateId: Int64, kind: String) {
        this.updateId = updateId
        this.kind = kind
    }
}
