package grammy4cj.architecture

public class DependencyBoundaryRule {
    public let sourceGroup: String
    public let forbiddenImport: String

    public init(sourceGroup: String, forbiddenImport: String) {
        this.sourceGroup = sourceGroup
        this.forbiddenImport = forbiddenImport
    }
}

public func dependencyBoundaryRuleCount(): Int64 {
    12
}

public func coreForbiddenImports(): Array<String> {
    ["grammy4cj.bot", "grammy4cj.context", "grammy4cj.composer", "grammy4cj.convenience", "grammy4cj.platform"]
}

public func contextForbiddenImports(): Array<String> {
    ["grammy4cj.platform"]
}

public func platformForbiddenImports(): Array<String> {
    ["grammy4cj.bot", "grammy4cj.context"]
}

public func convenienceForbiddenImports(): Array<String> {
    ["grammy4cj.core.ApiClient", "grammy4cj.bot"]
}
