package grammy4cj.platform

public class PlatformHttpRequest {
    public let method: String
    public let url: String
    public let headers: String
    public let body: String

    public init(method: String, url: String, headers: String, body: String) {
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
    }
}

public class PlatformHttpResponse {
    public let status: Int64
    public let body: String

    public init(status: Int64, body: String) {
        this.status = status
        this.body = body
    }
}

public class ByteStream {
    public let sourceKind: String
    public var consumed: Bool = false

    public init(sourceKind: String) {
        this.sourceKind = sourceKind
    }

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("ByteStream has already been consumed.")
        }
        this.consumed = true
    }
}

public class Logger {
    public let namespace: String

    public init(namespace: String) {
        this.namespace = namespace
    }

    public func sanitize(message: String, token: String): String {
        redactToken(message, token)
    }
}

public func redactToken(message: String, token: String): String {
    if (token.isEmpty()) {
        return message
    }
    message.replace(token, "<redacted>")
}

public class PlatformAdapter {
    public let runtime: String

    public init(runtime: String) {
        this.runtime = runtime
    }

    public func supportsLongPolling(): Bool {
        true
    }

    public func request(req: PlatformHttpRequest): PlatformHttpResponse {
        PlatformHttpResponse(599, "No HTTP client configured for " + req.method + " " + req.url)
    }

    public func logger(namespace: String): Logger {
        Logger(namespace)
    }
}

public func defaultPlatform(): PlatformAdapter {
    PlatformAdapter("cjnative")
}
