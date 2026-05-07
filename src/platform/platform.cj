package grammy4cj.platform

public let DEFAULT_WEBHOOK_ADAPTER: String = "callback"

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

public class BaseFetchConfig {
    public let apiRoot: String
    public let agentKind: String
    public let keepAlive: Bool
    public let compress: Bool
    public let isEmpty: Bool

    public init(apiRoot: String, agentKind: String, keepAlive: Bool, compress: Bool, isEmpty: Bool) {
        this.apiRoot = apiRoot
        this.agentKind = agentKind
        this.keepAlive = keepAlive
        this.compress = compress
        this.isEmpty = isEmpty
    }

    public func summary(): String {
        if (this.isEmpty) {
            return "empty"
        }
        this.agentKind + ":keepAlive=" + boolString(this.keepAlive) + ":compress=" + boolString(this.compress)
    }
}

public class ByteIterator {
    public let label: String
    public let chunkCount: Int64
    public var consumed: Bool = false

    public init(label: String, chunkCount: Int64) {
        this.label = label
        this.chunkCount = chunkCount
    }

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("ByteIterator has already been consumed.")
        }
        this.consumed = true
    }
}

public class ByteStream {
    public let sourceKind: String
    public let sourceValue: String
    public let chunkCount: Int64
    public let contract: String
    public var consumed: Bool = false

    public init(sourceKind: String) {
        this.sourceKind = sourceKind
        this.sourceValue = ""
        this.chunkCount = 0
        this.contract = "stream"
    }

    public init(sourceKind: String, sourceValue: String, chunkCount: Int64, contract: String) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.chunkCount = chunkCount
        this.contract = contract
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
    public let adapter: String

    public init(runtime: String) {
        this.runtime = runtime
        this.adapter = DEFAULT_WEBHOOK_ADAPTER
    }

    public init(runtime: String, adapter: String) {
        this.runtime = runtime
        this.adapter = adapter
    }

    public func supportsLongPolling(): Bool {
        true
    }

    public func request(req: PlatformHttpRequest): PlatformHttpResponse {
        PlatformHttpResponse(599, "No HTTP client configured for " + req.method + " " + req.url)
    }

    public func baseFetchConfig(apiRoot: String): BaseFetchConfig {
        makeBaseFetchConfig(apiRoot)
    }

    public func itrToStream(iterator: ByteIterator): ByteStream {
        makeByteStreamFromIterator(iterator)
    }

    public func logger(namespace: String): Logger {
        Logger(namespace)
    }
}

public func defaultAdapter(): String {
    DEFAULT_WEBHOOK_ADAPTER
}

public func defaultPlatform(): PlatformAdapter {
    PlatformAdapter("cjnative", defaultAdapter())
}

public func baseFetchConfig(apiRoot: String): BaseFetchConfig {
    makeBaseFetchConfig(apiRoot)
}

public func itrToStream(iterator: ByteIterator): ByteStream {
    makeByteStreamFromIterator(iterator)
}

private func makeBaseFetchConfig(apiRoot: String): BaseFetchConfig {
    if (apiRoot.startsWith("https:")) {
        return BaseFetchConfig(apiRoot, "https", true, true, false)
    }
    if (apiRoot.startsWith("http:")) {
        return BaseFetchConfig(apiRoot, "http", true, false, false)
    }
    BaseFetchConfig(apiRoot, "", false, false, true)
}

private func makeByteStreamFromIterator(iterator: ByteIterator): ByteStream {
    iterator.consume()
    ByteStream("iterator", iterator.label, iterator.chunkCount, "async-iterable-to-byte-stream")
}

private func boolString(value: Bool): String {
    if (value) { "true" } else { "false" }
}
