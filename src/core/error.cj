package grammy4cj.core

import grammy4cj.types.ResponseParameters

public class GrammyError <: Exception {
    public let method: String
    public let payload: String
    public let errorCode: Int64
    public let description: String
    public let parameters: ResponseParameters

    public init(message: String, method: String) {
        super(message)
        this.method = method
        this.payload = ""
        this.errorCode = 0
        this.description = message
        this.parameters = ResponseParameters()
    }

    public init(method: String, payload: String, errorCode: Int64, description: String, parameters: ResponseParameters) {
        super("${method} failed with ${errorCode}: ${description}")
        this.method = method
        this.payload = payload
        this.errorCode = errorCode
        this.description = description
        this.parameters = parameters
    }
}

public class HttpError <: Exception {
    public let status: Int64
    public let method: String
    public let url: String

    public init(message: String, status: Int64) {
        super(message)
        this.status = status
        this.method = ""
        this.url = ""
    }

    public init(message: String, status: Int64, method: String, url: String) {
        super(message)
        this.status = status
        this.method = method
        this.url = url
    }
}
