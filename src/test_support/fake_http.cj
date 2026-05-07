package grammy4cj.test_support

public class FakeHttpRequest {
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

public class FakeHttp {
    public var called: Bool = false
    public var method: String = ""
    public var url: String = ""
    public var headers: String = ""
    public var body: String = ""

    public init() {}

    public func request(method: String, url: String, headers: String, body: String): FakeHttpRequest {
        this.called = true
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
        FakeHttpRequest(method, url, headers, body)
    }
}
