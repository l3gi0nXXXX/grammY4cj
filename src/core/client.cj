package grammy4cj.core

import std.collection.ArrayList

import grammy4cj.types.ApiResponse
import grammy4cj.types.ResponseParameters

public class CoreHttpRequest {
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

public class WebhookReplyEnvelope {
    public var sent: Bool = false
    public var payload: String = ""

    public init() {}

    public func send(payload: String): Unit {
        this.sent = true
        this.payload = payload
    }
}

public class ApiClient {
    public let config: ApiClientOptions
    public var installedTransformers: ArrayList<String> = ArrayList<String>()
    public var hasUsedWebhookReply: Bool = false
    public let webhookReplyEnvelope: WebhookReplyEnvelope

    public init(config: ApiClientOptions) {
        this.config = config
        this.webhookReplyEnvelope = WebhookReplyEnvelope()
    }

    public init(config: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope) {
        this.config = config
        this.webhookReplyEnvelope = webhookReplyEnvelope
    }

    public func endpoint(token: String, method: String): String {
        this.config.buildUrl(token, method)
    }

    public func use(transformerName: String): ApiClient {
        this.installedTransformers.add(transformerName)
        this
    }

    public func jsonRequest(token: String, method: String, payload: Payload): CoreHttpRequest {
        let req = createJsonPayload(payload)
        CoreHttpRequest(req.method, this.endpoint(token, method), req.headers, req.body)
    }

    public func formRequest(token: String, method: String, payload: Payload, boundary: String, attachIdPrefix: String): CoreHttpRequest {
        let req = createFormDataPayload(payload, boundary, attachIdPrefix)
        CoreHttpRequest(req.method, this.endpoint(token, method), req.headers, req.body)
    }

    public func maybeUseWebhookReply(method: String, payload: Payload): Bool {
        if (this.hasUsedWebhookReply || !this.config.canUseWebhookReply || requiresFormDataUpload(payload)) {
            return false
        }
        this.webhookReplyEnvelope.send(createJsonPayload(payload).body)
        this.hasUsedWebhookReply = true
        true
    }

    public func dispatchRaw(method: String): Payload {
        Payload("{}").addValue("__method", method)
    }

    public func dispatchRaw(method: String, payload: Payload): Payload {
        payload.addValue("__method", method)
    }

    public func resultOrThrow(method: String, payload: Payload, response: ApiResponse): String {
        if (response.ok) {
            return response.result
        }
        throw GrammyError(method, createJsonPayload(payload).body, response.error.errorCode, response.error.description, response.error.parameters)
    }

    public func httpErrorFor(method: String, url: String, message: String): HttpError {
        HttpError(message, 599, method, url)
    }

    public func timeoutConfig(): TimeoutConfig {
        TimeoutConfig(this.config.timeoutSeconds * 1000)
    }
}
