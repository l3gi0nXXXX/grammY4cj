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

public func defaultCoreBaseFetchConfig(apiRoot: String): BaseFetchConfig {
    if (apiRoot.startsWith("https:")) {
        return BaseFetchConfig(apiRoot, "https", true, true, false)
    }
    if (apiRoot.startsWith("http:")) {
        return BaseFetchConfig(apiRoot, "http", true, false, false)
    }
    BaseFetchConfig(apiRoot, "", false, false, true)
}

public func mergeBaseFetchConfig(apiRoot: String, overrideConfig: BaseFetchConfig): BaseFetchConfig {
    let base = defaultCoreBaseFetchConfig(apiRoot)
    if (overrideConfig.isEmpty) {
        return base
    }
    let mergedRoot = if (overrideConfig.apiRoot.isEmpty()) {
        base.apiRoot
    } else {
        overrideConfig.apiRoot
    }
    let mergedAgent = if (overrideConfig.agentKind.isEmpty()) {
        base.agentKind
    } else {
        overrideConfig.agentKind
    }
    BaseFetchConfig(mergedRoot, mergedAgent, overrideConfig.keepAlive, overrideConfig.compress, false)
}

private func boolString(value: Bool): String {
    if (value) { "true" } else { "false" }
}
