package grammy4cj.platform_contract

public func platformInputFileRuntimeNames(): Array<String> {
    ["deno", "node", "web"]
}

public func platformInputFileSourceKindNames(): Array<String> {
    ["path", "url", "url_like", "file_url", "bytes", "blob", "response", "stream", "iterable", "async_iterable", "supplier"]
}

public func platformNormalizeInputFileRuntime(runtime: String): String {
    if (runtime == "deno" || runtime == "node" || runtime == "web") {
        return runtime
    }
    if (runtime.isEmpty() || runtime == "cjnative") {
        return "node"
    }
    runtime
}

public func platformSupportsInputFileSourceKind(sourceKind: String, runtime: String): Bool {
    let normalizedRuntime = platformNormalizeInputFileRuntime(runtime)
    if (sourceKind == "path") {
        return normalizedRuntime == "deno" || normalizedRuntime == "node"
    }
    if (sourceKind == "file_url") {
        return normalizedRuntime == "node"
    }
    if (sourceKind == "blob") {
        return normalizedRuntime == "deno" || normalizedRuntime == "web"
    }
    if (sourceKind == "response") {
        return normalizedRuntime == "deno"
    }
    if (sourceKind == "supplier") {
        return normalizedRuntime == "deno" || normalizedRuntime == "node"
    }
    platformInputFileSourceKindExists(sourceKind)
}

public func platformInputFileRawContractFor(sourceKind: String, runtime: String, fallbackContract: String): String {
    let normalizedRuntime = platformNormalizeInputFileRuntime(runtime)
    if (sourceKind == "path") {
        if (normalizedRuntime == "deno") {
            return "deno-open-file-async-iterator"
        }
        if (normalizedRuntime == "node") {
            return "node-create-read-stream"
        }
    }
    if (sourceKind == "file_url") {
        if (normalizedRuntime == "node") {
            return "node-file-url-create-read-stream"
        }
        return "file-url-unsupported"
    }
    if (sourceKind == "url" || sourceKind == "url_like") {
        return "fetch-body-async-iterable"
    }
    if (sourceKind == "bytes") {
        return "uint8-array-as-is"
    }
    if (sourceKind == "blob") {
        return "blob-stream"
    }
    if (sourceKind == "response") {
        return "response-body"
    }
    if (sourceKind == "stream") {
        if (normalizedRuntime == "node") {
            return "node-read-stream-as-is"
        }
        return "readable-stream-as-is"
    }
    if (sourceKind == "iterable") {
        return "iterator-as-is"
    }
    if (sourceKind == "async_iterable") {
        return "async-iterator-as-is"
    }
    if (sourceKind == "supplier") {
        return "supplier-deferred"
    }
    fallbackContract
}

private func platformInputFileSourceKindExists(sourceKind: String): Bool {
    for (kind in platformInputFileSourceKindNames()) {
        if (kind == sourceKind) {
            return true
        }
    }
    false
}
