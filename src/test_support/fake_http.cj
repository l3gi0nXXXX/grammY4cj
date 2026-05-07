package grammy4cj.test_support

import std.collection.ArrayList

import grammy4cj.core.CancelSignal
import grammy4cj.core.CoreFetch
import grammy4cj.core.CoreFetchResponse
import grammy4cj.core.CoreHttpRequest
import grammy4cj.types.ApiResponse

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

public class FakeHttp <: CoreFetch {
    public var called: Bool = false
    public var method: String = ""
    public var url: String = ""
    public var headers: String = ""
    public var body: String = ""
    public var baseFetchConfigSummary: String = ""
    public let requests: ArrayList<CoreHttpRequest> = ArrayList<CoreHttpRequest>()
    private let responses: ArrayList<CoreFetchResponse> = ArrayList<CoreFetchResponse>()

    public init() {}

    public func request(method: String, url: String, headers: String, body: String): FakeHttpRequest {
        this.called = true
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
        FakeHttpRequest(method, url, headers, body)
    }

    public func enqueue(response: CoreFetchResponse): FakeHttp {
        this.responses.add(response)
        this
    }

    public func enqueueApi(response: ApiResponse): FakeHttp {
        this.enqueue(CoreFetchResponse.api(response))
    }

    public func enqueueResult(result: String): FakeHttp {
        this.enqueue(CoreFetchResponse.success(result))
    }

    public func enqueueNetworkError(message: String): FakeHttp {
        this.enqueue(CoreFetchResponse.networkError(message))
    }

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        signal.throwIfCancelled()
        this.called = true
        this.method = request.method
        this.url = request.url
        this.headers = request.headers
        this.body = request.body
        this.baseFetchConfigSummary = request.baseFetchConfigSummary
        this.requests.add(request)
        if (this.responses.size == 0) {
            return CoreFetchResponse.success("{}")
        }
        let response = this.responses[0]
        this.responses.remove(at: 0)
        response
    }
}
