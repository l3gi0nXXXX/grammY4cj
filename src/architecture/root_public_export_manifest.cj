package grammy4cj.architecture

public let ROOT_PUBLIC_EXPORT_MANIFEST_PATH: String = "src/architecture/root_public_export_manifest.tsv"
public let ROOT_PUBLIC_EXPORT_MANIFEST_UPSTREAM_ANCHOR: String = "grammY/src/mod.ts:1-60"

public func rootPublicExportManifestEntryCount(): Int64 {
    59
}

public func rootPublicExportManifestPublicCount(): Int64 {
    46
}

public func rootPublicExportManifestExpertPublicCount(): Int64 {
    9
}

public func rootPublicExportManifestInternalCount(): Int64 {
    4
}

public func rootPublicExportManifestTestOnlyCount(): Int64 {
    0
}

public func rootPublicExportManifestCategories(): Array<String> {
    ["public", "expert-public", "internal", "test-only"]
}

public func rootPublicExportManifestGateScript(): String {
    "scripts/check_root_public_surface.sh"
}

public func rootSurfaceExpectedFrameworkAdapterCount(): Int64 {
    21
}

public func rootSurfaceExpectedHonoHandlerReturnKind(): String {
    "promise-response"
}
