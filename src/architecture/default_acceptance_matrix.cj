package grammy4cj.architecture

public let DEFAULT_ACCEPTANCE_MATRIX_PATH: String = "src/architecture/default_acceptance_matrix.tsv"

public func defaultAcceptanceMatrixRowCount(): Int64 {
    10
}

public func defaultAcceptanceMatrixCategoryCount(): Int64 {
    3
}

public func defaultAcceptanceMatrixDefaultNetworkRows(): Int64 {
    0
}

public func defaultAcceptanceMatrixOptInRows(): Int64 {
    1
}

public func defaultAcceptanceMatrixPackageRows(): Int64 {
    3
}

public func defaultAcceptanceMatrixGateScript(): String {
    "scripts/check_default_acceptance_matrix.sh"
}
