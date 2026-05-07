package grammy4cj.filter

public type FilterQuery = String

public func matchFilter(query: FilterQuery, updateKind: String): Bool {
    !query.isEmpty() && query == updateKind
}
