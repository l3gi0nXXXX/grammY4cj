package grammy4cj.core

public class ApiClientOptions {
    public let apiRoot: String
    public let environment: String
    public let timeoutSeconds: Int64
    public let sensitiveLogs: Bool
    public let canUseWebhookReply: Bool

    public init() {
        this.apiRoot = "https://api.telegram.org"
        this.environment = "prod"
        this.timeoutSeconds = 500
        this.sensitiveLogs = false
        this.canUseWebhookReply = false
    }

    public init(apiRoot: String, environment: String) {
        if (apiRoot.endsWith("/")) {
            throw Exception("apiRoot must not end with a slash.")
        }
        this.apiRoot = apiRoot
        this.environment = environment
        this.timeoutSeconds = 500
        this.sensitiveLogs = false
        this.canUseWebhookReply = false
    }

    public init(apiRoot: String, environment: String, timeoutSeconds: Int64, sensitiveLogs: Bool, canUseWebhookReply: Bool) {
        if (apiRoot.endsWith("/")) {
            throw Exception("apiRoot must not end with a slash.")
        }
        this.apiRoot = apiRoot
        this.environment = environment
        this.timeoutSeconds = timeoutSeconds
        this.sensitiveLogs = sensitiveLogs
        this.canUseWebhookReply = canUseWebhookReply
    }

    public func buildUrl(token: String, method: String): String {
        let prefix = if (this.environment == "test") {
            "test/"
        } else {
            ""
        }
        this.apiRoot + "/bot" + token + "/" + prefix + method
    }
}

public class Api {
    public let token: String
    public let config: ApiClientOptions

    public init(token: String) {
        this.token = token
        this.config = ApiClientOptions()
    }

    public init(token: String, config: ApiClientOptions) {
        this.token = token
        this.config = config
    }

    public func endpointFor(method: String): String {
        this.config.buildUrl(this.token, method)
    }

    public func call(method: String, payload: Payload): Payload {
        Payload("").addValue("__method", method).addValue("__payload", createJsonPayload(payload).body)
    }

    public func getUpdates(payload: Payload): Payload {
        this.call("getUpdates", payload)
    }

    public func setWebhook(payload: Payload): Payload {
        this.call("setWebhook", payload)
    }

    public func deleteWebhook(payload: Payload): Payload {
        this.call("deleteWebhook", payload)
    }

    public func getWebhookInfo(payload: Payload): Payload {
        this.call("getWebhookInfo", payload)
    }

    public func getMe(payload: Payload): Payload {
        this.call("getMe", payload)
    }

    public func logOut(payload: Payload): Payload {
        this.call("logOut", payload)
    }

    public func close(payload: Payload): Payload {
        this.call("close", payload)
    }

    public func sendMessage(payload: Payload): Payload {
        this.call("sendMessage", payload)
    }

    public func sendMessageDraft(payload: Payload): Payload {
        this.call("sendMessageDraft", payload)
    }

    public func forwardMessage(payload: Payload): Payload {
        this.call("forwardMessage", payload)
    }

    public func forwardMessages(payload: Payload): Payload {
        this.call("forwardMessages", payload)
    }

    public func copyMessage(payload: Payload): Payload {
        this.call("copyMessage", payload)
    }

    public func copyMessages(payload: Payload): Payload {
        this.call("copyMessages", payload)
    }

    public func sendPhoto(payload: Payload): Payload {
        this.call("sendPhoto", payload)
    }

    public func sendAudio(payload: Payload): Payload {
        this.call("sendAudio", payload)
    }

    public func sendDocument(payload: Payload): Payload {
        this.call("sendDocument", payload)
    }

    public func sendVideo(payload: Payload): Payload {
        this.call("sendVideo", payload)
    }

    public func sendAnimation(payload: Payload): Payload {
        this.call("sendAnimation", payload)
    }

    public func sendVoice(payload: Payload): Payload {
        this.call("sendVoice", payload)
    }

    public func sendVideoNote(payload: Payload): Payload {
        this.call("sendVideoNote", payload)
    }

    public func sendMediaGroup(payload: Payload): Payload {
        this.call("sendMediaGroup", payload)
    }

    public func sendLocation(payload: Payload): Payload {
        this.call("sendLocation", payload)
    }
}

public func apiWrapperGenerationSkeletonCount(): Int64 {
    22
}
