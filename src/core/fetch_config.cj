package grammy4cj.core

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

private func boolString(value: Bool): String {
    if (value) { "true" } else { "false" }
}
