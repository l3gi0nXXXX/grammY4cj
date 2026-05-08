package grammy4cj.core

import std.collection.ArrayList
import std.io.StringReader
import std.sync.{Condition, Mutex}
import std.time.DateTime
import stdx.encoding.url.URL
import stdx.net.http.*
import stdx.net.tls.TlsClientConfig

import grammy4cj.types.ApiResponse
import grammy4cj.types.ResponseParameters

public type ApiCallFn = (String, Payload, CancelSignal) -> ApiResponse
public type Transformer = (ApiCallFn, String, Payload, CancelSignal) -> ApiResponse
public type CoreFetchFn = (CoreHttpRequest, CancelSignal) -> CoreFetchResponse

private func emptyBaseFetchConfig(): BaseFetchConfig {
    BaseFetchConfig("", "", false, false, true)
}

private func ignoreClientMultipartStreamError(_err: Exception): Unit {}

public class CoreHttpRequest {
    public let method: String
    public let url: String
    public let headers: String
    public let body: String
    public let payload: RequestPayload
    public let baseFetchConfig: BaseFetchConfig
    public let baseFetchConfigSummary: String

    public init(method: String, url: String, headers: String, body: String) {
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
        this.payload = RequestPayload(method, headers, body)
        this.baseFetchConfig = emptyBaseFetchConfig()
        this.baseFetchConfigSummary = this.baseFetchConfig.summary()
    }

    public init(method: String, url: String, headers: String, body: String, baseFetchConfig: BaseFetchConfig) {
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
        this.payload = RequestPayload(method, headers, body)
        this.baseFetchConfig = baseFetchConfig
        this.baseFetchConfigSummary = baseFetchConfig.summary()
    }

    public init(url: String, payload: RequestPayload) {
        this.method = payload.method
        this.url = url
        this.headers = payload.headers
        this.body = payload.body
        this.payload = payload
        this.baseFetchConfig = emptyBaseFetchConfig()
        this.baseFetchConfigSummary = this.baseFetchConfig.summary()
    }

    public init(url: String, payload: RequestPayload, baseFetchConfig: BaseFetchConfig) {
        this.method = payload.method
        this.url = url
        this.headers = payload.headers
        this.body = payload.body
        this.payload = payload
        this.baseFetchConfig = baseFetchConfig
        this.baseFetchConfigSummary = baseFetchConfig.summary()
    }
}

public class CoreFetchResponse {
    public let status: Int64
    public let statusText: String
    public let body: String
    public let apiResponse: ApiResponse
    public let hasApiResponse: Bool
    public let hasTransportError: Bool
    public let transportErrorMessage: String
    public var delayMillis: Int64 = 0

    public init(status: Int64, statusText: String, body: String) {
        this.status = status
        this.statusText = statusText
        this.body = body
        this.apiResponse = ApiResponse.success(body)
        this.hasApiResponse = false
        this.hasTransportError = false
        this.transportErrorMessage = ""
    }

    public init(response: ApiResponse) {
        this.status = 200
        this.statusText = "OK"
        this.body = response.result
        this.apiResponse = response
        this.hasApiResponse = true
        this.hasTransportError = false
        this.transportErrorMessage = ""
    }

    public init(message: String, status: Int64, statusText: String) {
        this.status = status
        this.statusText = statusText
        this.body = ""
        this.apiResponse = ApiResponse.success("")
        this.hasApiResponse = false
        this.hasTransportError = true
        this.transportErrorMessage = message
    }

    public static func success(result: String): CoreFetchResponse {
        CoreFetchResponse(ApiResponse.success(result))
    }

    public static func api(response: ApiResponse): CoreFetchResponse {
        CoreFetchResponse(response)
    }

    public static func networkError(message: String): CoreFetchResponse {
        CoreFetchResponse(message, 0, "")
    }

    public static func telegramError(status: Int64, statusText: String, message: String): CoreFetchResponse {
        CoreFetchResponse(message, status, statusText)
    }

    public func withDelay(delayMillis: Int64): CoreFetchResponse {
        this.delayMillis = delayMillis
        this
    }
}

private class TransportRaceState {
    public var completed: Bool = false
    public var fetchStarted: Bool = false
    public var branch: String = ""
    public var response: CoreFetchResponse = CoreFetchResponse.success("")
    public var failure: Option<Exception> = None<Exception>

    public init() {}
}

public interface CoreFetch {
    func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse
}

public class FunctionCoreFetch <: CoreFetch {
    private let fetchFn: CoreFetchFn

    public init(fetchFn: CoreFetchFn) {
        this.fetchFn = fetchFn
    }

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        this.fetchFn(request, signal)
    }
}

public class NoopCoreFetch <: CoreFetch {
    public init() {}

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        signal.throwIfCancelled()
        CoreFetchResponse.networkError("No HTTP client configured for " + request.method + " " + request.url)
    }
}

public class NativeHttpCoreFetch <: CoreFetch {
    public init() {}

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        signal.throwIfCancelled()
        try {
            let client = nativeHttpClient(request.url)
            try {
                let response = client.send(nativeHttpRequest(request))
                signal.throwIfCancelled()
                CoreFetchResponse(Int64(response.status), "", nativeHttpBody(response))
            } finally {
                client.close()
            }
        } catch (err: Exception) {
            CoreFetchResponse.networkError(err.message)
        }
    }
}

private func nativeHttpClient(url: String): Client {
    let builder = ClientBuilder()
    if (url.startsWith("https://")) {
        var tlsConfig = TlsClientConfig()
        tlsConfig.domain = URL.parse(url).hostName
        builder.tlsConfig(tlsConfig)
    }
    builder.build()
}

private func nativeHttpRequest(request: CoreHttpRequest): HttpRequest {
    let builder = HttpRequestBuilder().url(request.url)
    if (request.method == "GET") {
        builder.get()
    } else {
        builder.post()
    }
    builder.body(request.payload.drainBody())
    nativeAppendHeaderArgs(builder, request.headers)
    builder.build()
}

private func nativeAppendHeaderArgs(builder: HttpRequestBuilder, headers: String): Unit {
    let contentType = nativeHeaderContentType(headers)
    if (!contentType.isEmpty()) {
        builder.header("content-type", contentType)
    }
    if (headers.contains("connection=keep-alive")) {
        builder.header("connection", "keep-alive")
    }
}

private func nativeHeaderContentType(headers: String): String {
    let prefix = "content-type="
    if (!headers.startsWith(prefix)) {
        return ""
    }
    var value = headers[prefix.size..]
    let connectionIndex = nativeIndexOfFrom(value, ";connection=", 0)
    if (connectionIndex >= 0) {
        value = value[0..connectionIndex]
    }
    value
}

private func nativeHttpBody(response: HttpResponse): String {
    let reader = StringReader(response.body)
    reader.readToEnd()
}

private func nativeIndexOfFrom(value: String, needle: String, startIndex: Int64): Int64 {
    if (needle.isEmpty()) {
        return startIndex
    }
    var i = startIndex
    while (i + needle.size <= value.size) {
        if (value[i..i + needle.size] == needle) {
            return i
        }
        i += 1
    }
    -1
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
    public var installedTransformerFunctions: ArrayList<Transformer> = ArrayList<Transformer>()
    public var hasUsedWebhookReply: Bool = false
    public let webhookReplyEnvelope: WebhookReplyEnvelope
    private let fetcher: CoreFetch

    public init(config: ApiClientOptions) {
        this.config = config
        this.webhookReplyEnvelope = WebhookReplyEnvelope()
        this.fetcher = NativeHttpCoreFetch()
    }

    public init(config: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope) {
        this.config = config
        this.webhookReplyEnvelope = webhookReplyEnvelope
        this.fetcher = NativeHttpCoreFetch()
    }

    public init(config: ApiClientOptions, fetcher: CoreFetch) {
        this.config = config
        this.webhookReplyEnvelope = WebhookReplyEnvelope()
        this.fetcher = fetcher
    }

    public init(config: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope, fetcher: CoreFetch) {
        this.config = config
        this.webhookReplyEnvelope = webhookReplyEnvelope
        this.fetcher = fetcher
    }

    public func endpoint(token: String, method: String): String {
        this.config.buildUrl(token, method)
    }

    public func use(transformerName: String): ApiClient {
        this.installedTransformers.add(transformerName)
        this
    }

    public func use(transformer: Transformer): ApiClient {
        this.installedTransformers.add("function")
        this.installedTransformerFunctions.add(transformer)
        this
    }

    public func use(transformerName: String, transformer: Transformer): ApiClient {
        this.installedTransformers.add(transformerName)
        this.installedTransformerFunctions.add(transformer)
        this
    }

    public func jsonRequest(token: String, method: String, payload: Payload): CoreHttpRequest {
        let req = createJsonPayload(payload)
        CoreHttpRequest(req.method, this.endpoint(token, method), req.headers, req.body, this.config.baseFetchConfig)
    }

    public func formRequest(token: String, method: String, payload: Payload, boundary: String, attachIdPrefix: String): CoreHttpRequest {
        let req = createFormDataPayload(payload, boundary, attachIdPrefix)
        CoreHttpRequest(this.endpoint(token, method), req, this.config.baseFetchConfig)
    }

    public func maybeUseWebhookReply(method: String, payload: Payload): Bool {
        if (this.hasUsedWebhookReply || requiresFormDataUpload(payload) || !this.config.canUseWebhookReplyFor(method)) {
            return false
        }
        this.webhookReplyEnvelope.send(createJsonPayloadWithMethod(payload, method).body)
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
        throw toGrammyError(response.error, method, payload)
    }

    public func httpErrorFor(method: String, url: String, message: String): HttpError {
        HttpError(message, 599, method, url)
    }

    public func timeoutConfig(): TimeoutConfig {
        TimeoutConfig(this.config.timeoutSeconds * 1000)
    }

    public func copyInstalledTransformersTo(target: ApiClient): ApiClient {
        for (name in this.installedTransformers) {
            target.installedTransformers.add(name)
        }
        for (transformer in this.installedTransformerFunctions) {
            target.installedTransformerFunctions.add(transformer)
        }
        target
    }

    public func callApi(token: String, method: String, payload: Payload): String {
        this.callApi(token, method, payload, CancelSignal())
    }

    public func callApi(token: String, method: String, payload: Payload, signal: CancelSignal): String {
        var response = ApiResponse.success("")
        try {
            response = this.callWithTransformers(token, method, payload, signal)
        } catch (err: GrammyError) {
            throw err
        } catch (err: HttpError) {
            throw err
        } catch (err: Exception) {
            throw toHttpError(method, this.config.sensitiveLogs, err)
        }
        this.resultOrThrow(method, payload, response)
    }

    private func callWithTransformers(token: String, method: String, payload: Payload, signal: CancelSignal): ApiResponse {
        var call: ApiCallFn = { m: String, p: Payload, s: CancelSignal => this.performCall(token, m, p, s) }
        for (transformer in this.installedTransformerFunctions) {
            let previous = call
            call = { m: String, p: Payload, s: CancelSignal => transformer(previous, m, p, s) }
        }
        call(method, payload, signal)
    }

    private func performCall(token: String, method: String, payload: Payload, signal: CancelSignal): ApiResponse {
        try {
            signal.throwIfCancelled()
        } catch (err: Exception) {
            throw toHttpError(method, this.config.sensitiveLogs, err)
        }
        if (this.maybeUseWebhookReply(method, payload)) {
            return ApiResponse.success("true")
        }

        let requestPayload = if (requiresFormDataUpload(payload)) {
            createFormDataPayload(payload, ignoreClientMultipartStreamError)
        } else {
            createJsonPayload(payload)
        }
        let request = CoreHttpRequest(this.endpoint(token, method), requestPayload, this.config.baseFetchConfig)

        let response = this.runTransportRace(method, token, request, requestPayload, signal)
        this.resolveTransportResponse(method, token, request.url, response)
    }

    private func runTransportRace(method: String, token: String, request: CoreHttpRequest, requestPayload: RequestPayload, parentSignal: CancelSignal): CoreFetchResponse {
        let transportSignal = CancelSignal(parentSignal)
        let race = TransportRaceState()
        let mutex = Mutex()
        let condition: Condition = synchronized(mutex) { mutex.condition() }
        let startedAt = clientNowMillis()
        let timeoutMillis = this.timeoutConfig().timeoutMillis
        let timeoutMessage = "Request to '" + method + "' timed out after " + this.config.timeoutSeconds.toString() + " seconds"

        spawn { =>
            markTransportRaceFetchStarted(race, mutex, condition)
            try {
                let response = this.fetcher.fetch(request, transportSignal)
                completeTransportRaceResponse(race, mutex, condition, "success", response)
            } catch (err: Exception) {
                completeTransportRaceFailure(race, mutex, condition, "success", err)
            }
        }

        synchronized(mutex) {
            condition.waitUntil({ => race.fetchStarted })
        }

        spawn { =>
            if (requestPayload.stream.hasError) {
                if (waitUntilRaceDeadline(startedAt + requestPayload.stream.errorAfterMillis, race, mutex)) {
                    try {
                        requestPayload.stream.raiseError()
                    } catch (err: Exception) {
                        transportSignal.cancel(err.message)
                        completeTransportRaceFailure(race, mutex, condition, "stream", err)
                    }
                }
            }
        }

        spawn { =>
            if (waitUntilRaceDeadline(startedAt + timeoutMillis, race, mutex)) {
                transportSignal.cancel(timeoutMessage)
                completeTransportRaceFailure(race, mutex, condition, "timeout", Exception(timeoutMessage))
            }
        }

        synchronized(mutex) {
            condition.waitUntil({ => race.completed })
        }
        match (race.failure) {
            case Some(err) => throw toHttpError(method, this.config.sensitiveLogs, request.url, token, err)
            case None => race.response
        }
    }

    private func resolveTransportResponse(method: String, token: String, url: String, response: CoreFetchResponse): ApiResponse {
        if (response.hasTransportError) {
            throw toHttpError(method, this.config.sensitiveLogs, url, token, response.status, response.statusText, response.transportErrorMessage)
        }

        if (response.hasApiResponse) {
            return response.apiResponse
        }

        if (response.status >= 400) {
            throw toHttpError(method, this.config.sensitiveLogs, url, token, response.status, response.statusText, response.body)
        }
        try {
            return parseTelegramApiResponse(response.body)
        } catch (err: Exception) {
            throw toHttpError(method, this.config.sensitiveLogs, url, token, err)
        }
    }
}

private func markTransportRaceFetchStarted(state: TransportRaceState, mutex: Mutex, condition: Condition): Unit {
    synchronized(mutex) {
        state.fetchStarted = true
        condition.notifyAll()
    }
}

private func clientNowMillis(): Int64 {
    DateTime.now().toUnixTimeStamp().toMilliseconds()
}

private func isTransportRaceCompleted(state: TransportRaceState, mutex: Mutex): Bool {
    synchronized(mutex) {
        state.completed
    }
}

private func waitUntilRaceDeadline(deadlineMillis: Int64, state: TransportRaceState, mutex: Mutex): Bool {
    while (clientNowMillis() < deadlineMillis) {
        if (isTransportRaceCompleted(state, mutex)) {
            return false
        }
    }
    !isTransportRaceCompleted(state, mutex)
}

private func completeTransportRaceResponse(state: TransportRaceState, mutex: Mutex, condition: Condition, branch: String, response: CoreFetchResponse): Unit {
    synchronized(mutex) {
        if (!state.completed) {
            state.completed = true
            state.branch = branch
            state.response = response
            condition.notifyAll()
        }
    }
}

private func completeTransportRaceFailure(state: TransportRaceState, mutex: Mutex, condition: Condition, branch: String, err: Exception): Unit {
    synchronized(mutex) {
        if (!state.completed) {
            state.completed = true
            state.branch = branch
            state.failure = Some(err)
            condition.notifyAll()
        }
    }
}

public class RawApiFacade {
    private let token: String
    private let client: ApiClient

    public init(token: String, client: ApiClient) {
        this.token = token
        this.client = client
    }

    public func call(method: String): String {
        this.call(method, Payload("{}"))
    }

    public func call(method: String, payload: Payload): String {
        this.client.callApi(this.token, method, payload)
    }

    public func call(method: String, payload: Payload, signal: CancelSignal): String {
        this.client.callApi(this.token, method, payload, signal)
    }

    public func getMe(): String {
        this.call("getMe", Payload("{}"))
    }

    public func getWebhookInfo(): String {
        this.call("getWebhookInfo", Payload("{}"))
    }

    public func getForumTopicIconStickers(): String {
        this.call("getForumTopicIconStickers", Payload("{}"))
    }

    public func getAvailableGifts(): String {
        this.call("getAvailableGifts", Payload("{}"))
    }

    public func logOut(): String {
        this.call("logOut", Payload("{}"))
    }

    public func close(): String {
        this.call("close", Payload("{}"))
    }

    public func getMyStarBalance(): String {
        this.call("getMyStarBalance", Payload("{}"))
    }

    public func removeMyProfilePhoto(): String {
        this.call("removeMyProfilePhoto", Payload("{}"))
    }

    public func callPublic(publicMethodName: String, payload: Payload): String {
        this.call(apiWrapperSchemaTraceFor(publicMethodName).rawMethodName, payload)
    }

    public func getUpdates(payload: Payload): String { this.call("getUpdates", payload) }
    public func setWebhook(payload: Payload): String { this.call("setWebhook", payload) }
    public func deleteWebhook(payload: Payload): String { this.call("deleteWebhook", payload) }
    public func getWebhookInfo(payload: Payload): String { this.call("getWebhookInfo", payload) }
    public func getMe(payload: Payload): String { this.call("getMe", payload) }
    public func logOut(payload: Payload): String { this.call("logOut", payload) }
    public func close(payload: Payload): String { this.call("close", payload) }
    public func sendMessage(payload: Payload): String {
        this.call("sendMessage", payload)
    }
    public func sendMessageDraft(payload: Payload): String { this.call("sendMessageDraft", payload) }
    public func forwardMessage(payload: Payload): String { this.call("forwardMessage", payload) }
    public func forwardMessages(payload: Payload): String { this.call("forwardMessages", payload) }
    public func copyMessage(payload: Payload): String { this.call("copyMessage", payload) }
    public func copyMessages(payload: Payload): String { this.call("copyMessages", payload) }
    public func sendPhoto(payload: Payload): String { this.call("sendPhoto", payload) }
    public func sendAudio(payload: Payload): String { this.call("sendAudio", payload) }
    public func sendDocument(payload: Payload): String { this.call("sendDocument", payload) }
    public func sendVideo(payload: Payload): String { this.call("sendVideo", payload) }
    public func sendAnimation(payload: Payload): String { this.call("sendAnimation", payload) }
    public func sendVoice(payload: Payload): String { this.call("sendVoice", payload) }
    public func sendVideoNote(payload: Payload): String { this.call("sendVideoNote", payload) }
    public func sendMediaGroup(payload: Payload): String { this.call("sendMediaGroup", payload) }
    public func sendLocation(payload: Payload): String { this.call("sendLocation", payload) }
    public func editMessageLiveLocation(payload: Payload): String { this.call("editMessageLiveLocation", payload) }
    public func editMessageLiveLocationInline(payload: Payload): String { this.call("editMessageLiveLocation", payload) }
    public func stopMessageLiveLocation(payload: Payload): String { this.call("stopMessageLiveLocation", payload) }
    public func stopMessageLiveLocationInline(payload: Payload): String { this.call("stopMessageLiveLocation", payload) }
    public func sendPaidMedia(payload: Payload): String { this.call("sendPaidMedia", payload) }
    public func sendVenue(payload: Payload): String { this.call("sendVenue", payload) }
    public func sendContact(payload: Payload): String { this.call("sendContact", payload) }
    public func sendPoll(payload: Payload): String { this.call("sendPoll", payload) }
    public func sendChecklist(payload: Payload): String { this.call("sendChecklist", payload) }
    public func editMessageChecklist(payload: Payload): String { this.call("editMessageChecklist", payload) }
    public func sendDice(payload: Payload): String { this.call("sendDice", payload) }
    public func setMessageReaction(payload: Payload): String { this.call("setMessageReaction", payload) }
    public func sendChatAction(payload: Payload): String { this.call("sendChatAction", payload) }
    public func getUserProfilePhotos(payload: Payload): String { this.call("getUserProfilePhotos", payload) }
    public func getUserProfileAudios(payload: Payload): String { this.call("getUserProfileAudios", payload) }
    public func setUserEmojiStatus(payload: Payload): String { this.call("setUserEmojiStatus", payload) }
    public func getUserChatBoosts(payload: Payload): String { this.call("getUserChatBoosts", payload) }
    public func getUserGifts(payload: Payload): String { this.call("getUserGifts", payload) }
    public func getChatGifts(payload: Payload): String { this.call("getChatGifts", payload) }
    public func getBusinessConnection(payload: Payload): String { this.call("getBusinessConnection", payload) }
    public func getFile(payload: Payload): String { this.call("getFile", payload) }
    public func kickChatMember(payload: Payload): String { this.call("banChatMember", payload) }
    public func banChatMember(payload: Payload): String { this.call("banChatMember", payload) }
    public func unbanChatMember(payload: Payload): String { this.call("unbanChatMember", payload) }
    public func restrictChatMember(payload: Payload): String { this.call("restrictChatMember", payload) }
    public func promoteChatMember(payload: Payload): String { this.call("promoteChatMember", payload) }
    public func setChatAdministratorCustomTitle(payload: Payload): String { this.call("setChatAdministratorCustomTitle", payload) }
    public func setChatMemberTag(payload: Payload): String { this.call("setChatMemberTag", payload) }
    public func banChatSenderChat(payload: Payload): String { this.call("banChatSenderChat", payload) }
    public func unbanChatSenderChat(payload: Payload): String { this.call("unbanChatSenderChat", payload) }
    public func setChatPermissions(payload: Payload): String { this.call("setChatPermissions", payload) }
    public func exportChatInviteLink(payload: Payload): String { this.call("exportChatInviteLink", payload) }
    public func createChatInviteLink(payload: Payload): String { this.call("createChatInviteLink", payload) }
    public func editChatInviteLink(payload: Payload): String { this.call("editChatInviteLink", payload) }
    public func createChatSubscriptionInviteLink(payload: Payload): String { this.call("createChatSubscriptionInviteLink", payload) }
    public func editChatSubscriptionInviteLink(payload: Payload): String { this.call("editChatSubscriptionInviteLink", payload) }
    public func revokeChatInviteLink(payload: Payload): String { this.call("revokeChatInviteLink", payload) }
    public func getManagedBotToken(payload: Payload): String { this.call("getManagedBotToken", payload) }
    public func replaceManagedBotToken(payload: Payload): String { this.call("replaceManagedBotToken", payload) }
    public func approveChatJoinRequest(payload: Payload): String { this.call("approveChatJoinRequest", payload) }
    public func declineChatJoinRequest(payload: Payload): String { this.call("declineChatJoinRequest", payload) }
    public func approveSuggestedPost(payload: Payload): String { this.call("approveSuggestedPost", payload) }
    public func declineSuggestedPost(payload: Payload): String { this.call("declineSuggestedPost", payload) }
    public func setChatPhoto(payload: Payload): String { this.call("setChatPhoto", payload) }
    public func deleteChatPhoto(payload: Payload): String { this.call("deleteChatPhoto", payload) }
    public func setChatTitle(payload: Payload): String { this.call("setChatTitle", payload) }
    public func setChatDescription(payload: Payload): String { this.call("setChatDescription", payload) }
    public func pinChatMessage(payload: Payload): String { this.call("pinChatMessage", payload) }
    public func unpinChatMessage(payload: Payload): String { this.call("unpinChatMessage", payload) }
    public func unpinAllChatMessages(payload: Payload): String { this.call("unpinAllChatMessages", payload) }
    public func leaveChat(payload: Payload): String { this.call("leaveChat", payload) }
    public func getChat(payload: Payload): String { this.call("getChat", payload) }
    public func getChatAdministrators(payload: Payload): String { this.call("getChatAdministrators", payload) }
    public func getChatMembersCount(payload: Payload): String { this.call("getChatMemberCount", payload) }
    public func getChatMemberCount(payload: Payload): String { this.call("getChatMemberCount", payload) }
    public func getChatMember(payload: Payload): String { this.call("getChatMember", payload) }
    public func setChatStickerSet(payload: Payload): String { this.call("setChatStickerSet", payload) }
    public func deleteChatStickerSet(payload: Payload): String { this.call("deleteChatStickerSet", payload) }
    public func getForumTopicIconStickers(payload: Payload): String { this.call("getForumTopicIconStickers", payload) }
    public func createForumTopic(payload: Payload): String { this.call("createForumTopic", payload) }
    public func editForumTopic(payload: Payload): String { this.call("editForumTopic", payload) }
    public func closeForumTopic(payload: Payload): String { this.call("closeForumTopic", payload) }
    public func reopenForumTopic(payload: Payload): String { this.call("reopenForumTopic", payload) }
    public func deleteForumTopic(payload: Payload): String { this.call("deleteForumTopic", payload) }
    public func unpinAllForumTopicMessages(payload: Payload): String { this.call("unpinAllForumTopicMessages", payload) }
    public func editGeneralForumTopic(payload: Payload): String { this.call("editGeneralForumTopic", payload) }
    public func closeGeneralForumTopic(payload: Payload): String { this.call("closeGeneralForumTopic", payload) }
    public func reopenGeneralForumTopic(payload: Payload): String { this.call("reopenGeneralForumTopic", payload) }
    public func hideGeneralForumTopic(payload: Payload): String { this.call("hideGeneralForumTopic", payload) }
    public func unhideGeneralForumTopic(payload: Payload): String { this.call("unhideGeneralForumTopic", payload) }
    public func unpinAllGeneralForumTopicMessages(payload: Payload): String { this.call("unpinAllGeneralForumTopicMessages", payload) }
    public func answerCallbackQuery(payload: Payload): String { this.call("answerCallbackQuery", payload) }
    public func setMyName(payload: Payload): String { this.call("setMyName", payload) }
    public func getMyName(payload: Payload): String { this.call("getMyName", payload) }
    public func setMyCommands(payload: Payload): String { this.call("setMyCommands", payload) }
    public func deleteMyCommands(payload: Payload): String { this.call("deleteMyCommands", payload) }
    public func getMyCommands(payload: Payload): String { this.call("getMyCommands", payload) }
    public func setMyDescription(payload: Payload): String { this.call("setMyDescription", payload) }
    public func getMyDescription(payload: Payload): String { this.call("getMyDescription", payload) }
    public func setMyShortDescription(payload: Payload): String { this.call("setMyShortDescription", payload) }
    public func getMyShortDescription(payload: Payload): String { this.call("getMyShortDescription", payload) }
    public func setMyProfilePhoto(payload: Payload): String { this.call("setMyProfilePhoto", payload) }
    public func removeMyProfilePhoto(payload: Payload): String { this.call("removeMyProfilePhoto", payload) }
    public func setChatMenuButton(payload: Payload): String { this.call("setChatMenuButton", payload) }
    public func getChatMenuButton(payload: Payload): String { this.call("getChatMenuButton", payload) }
    public func setMyDefaultAdministratorRights(payload: Payload): String { this.call("setMyDefaultAdministratorRights", payload) }
    public func getMyDefaultAdministratorRights(payload: Payload): String { this.call("getMyDefaultAdministratorRights", payload) }
    public func getMyStarBalance(payload: Payload): String { this.call("getMyStarBalance", payload) }
    public func editMessageText(payload: Payload): String { this.call("editMessageText", payload) }
    public func editMessageTextInline(payload: Payload): String { this.call("editMessageText", payload) }
    public func editMessageCaption(payload: Payload): String { this.call("editMessageCaption", payload) }
    public func editMessageCaptionInline(payload: Payload): String { this.call("editMessageCaption", payload) }
    public func editMessageMedia(payload: Payload): String { this.call("editMessageMedia", payload) }
    public func editMessageMediaInline(payload: Payload): String { this.call("editMessageMedia", payload) }
    public func editMessageReplyMarkup(payload: Payload): String { this.call("editMessageReplyMarkup", payload) }
    public func editMessageReplyMarkupInline(payload: Payload): String { this.call("editMessageReplyMarkup", payload) }
    public func stopPoll(payload: Payload): String { this.call("stopPoll", payload) }
    public func deleteMessage(payload: Payload): String { this.call("deleteMessage", payload) }
    public func deleteMessages(payload: Payload): String { this.call("deleteMessages", payload) }
    public func deleteBusinessMessages(payload: Payload): String { this.call("deleteBusinessMessages", payload) }
    public func setBusinessAccountName(payload: Payload): String { this.call("setBusinessAccountName", payload) }
    public func setBusinessAccountUsername(payload: Payload): String { this.call("setBusinessAccountUsername", payload) }
    public func setBusinessAccountBio(payload: Payload): String { this.call("setBusinessAccountBio", payload) }
    public func setBusinessAccountProfilePhoto(payload: Payload): String { this.call("setBusinessAccountProfilePhoto", payload) }
    public func removeBusinessAccountProfilePhoto(payload: Payload): String { this.call("removeBusinessAccountProfilePhoto", payload) }
    public func setBusinessAccountGiftSettings(payload: Payload): String { this.call("setBusinessAccountGiftSettings", payload) }
    public func getBusinessAccountStarBalance(payload: Payload): String { this.call("getBusinessAccountStarBalance", payload) }
    public func transferBusinessAccountStars(payload: Payload): String { this.call("transferBusinessAccountStars", payload) }
    public func getBusinessAccountGifts(payload: Payload): String { this.call("getBusinessAccountGifts", payload) }
    public func convertGiftToStars(payload: Payload): String { this.call("convertGiftToStars", payload) }
    public func upgradeGift(payload: Payload): String { this.call("upgradeGift", payload) }
    public func transferGift(payload: Payload): String { this.call("transferGift", payload) }
    public func postStory(payload: Payload): String { this.call("postStory", payload) }
    public func repostStory(payload: Payload): String { this.call("repostStory", payload) }
    public func editStory(payload: Payload): String { this.call("editStory", payload) }
    public func deleteStory(payload: Payload): String { this.call("deleteStory", payload) }
    public func sendSticker(payload: Payload): String { this.call("sendSticker", payload) }
    public func getStickerSet(payload: Payload): String { this.call("getStickerSet", payload) }
    public func getCustomEmojiStickers(payload: Payload): String { this.call("getCustomEmojiStickers", payload) }
    public func uploadStickerFile(payload: Payload): String { this.call("uploadStickerFile", payload) }
    public func createNewStickerSet(payload: Payload): String { this.call("createNewStickerSet", payload) }
    public func addStickerToSet(payload: Payload): String { this.call("addStickerToSet", payload) }
    public func setStickerPositionInSet(payload: Payload): String { this.call("setStickerPositionInSet", payload) }
    public func deleteStickerFromSet(payload: Payload): String { this.call("deleteStickerFromSet", payload) }
    public func replaceStickerInSet(payload: Payload): String { this.call("replaceStickerInSet", payload) }
    public func setStickerEmojiList(payload: Payload): String { this.call("setStickerEmojiList", payload) }
    public func setStickerKeywords(payload: Payload): String { this.call("setStickerKeywords", payload) }
    public func setStickerMaskPosition(payload: Payload): String { this.call("setStickerMaskPosition", payload) }
    public func setStickerSetTitle(payload: Payload): String { this.call("setStickerSetTitle", payload) }
    public func deleteStickerSet(payload: Payload): String { this.call("deleteStickerSet", payload) }
    public func setStickerSetThumbnail(payload: Payload): String { this.call("setStickerSetThumbnail", payload) }
    public func setCustomEmojiStickerSetThumbnail(payload: Payload): String { this.call("setCustomEmojiStickerSetThumbnail", payload) }
    public func getAvailableGifts(payload: Payload): String { this.call("getAvailableGifts", payload) }
    public func sendGift(payload: Payload): String { this.call("sendGift", payload) }
    public func giftPremiumSubscription(payload: Payload): String { this.call("giftPremiumSubscription", payload) }
    public func sendGiftToChannel(payload: Payload): String { this.call("sendGift", payload) }
    public func answerInlineQuery(payload: Payload): String { this.call("answerInlineQuery", payload) }
    public func answerWebAppQuery(payload: Payload): String { this.call("answerWebAppQuery", payload) }
    public func savePreparedInlineMessage(payload: Payload): String { this.call("savePreparedInlineMessage", payload) }
    public func savePreparedKeyboardButton(payload: Payload): String { this.call("savePreparedKeyboardButton", payload) }
    public func sendInvoice(payload: Payload): String { this.call("sendInvoice", payload) }
    public func createInvoiceLink(payload: Payload): String { this.call("createInvoiceLink", payload) }
    public func answerShippingQuery(payload: Payload): String { this.call("answerShippingQuery", payload) }
    public func answerPreCheckoutQuery(payload: Payload): String { this.call("answerPreCheckoutQuery", payload) }
    public func getStarTransactions(payload: Payload): String { this.call("getStarTransactions", payload) }
    public func refundStarPayment(payload: Payload): String { this.call("refundStarPayment", payload) }
    public func editUserStarSubscription(payload: Payload): String { this.call("editUserStarSubscription", payload) }
    public func verifyUser(payload: Payload): String { this.call("verifyUser", payload) }
    public func verifyChat(payload: Payload): String { this.call("verifyChat", payload) }
    public func removeUserVerification(payload: Payload): String { this.call("removeUserVerification", payload) }
    public func removeChatVerification(payload: Payload): String { this.call("removeChatVerification", payload) }
    public func readBusinessMessage(payload: Payload): String { this.call("readBusinessMessage", payload) }
    public func setPassportDataErrors(payload: Payload): String { this.call("setPassportDataErrors", payload) }
    public func sendGame(payload: Payload): String { this.call("sendGame", payload) }
    public func setGameScore(payload: Payload): String { this.call("setGameScore", payload) }
    public func setGameScoreInline(payload: Payload): String { this.call("setGameScore", payload) }
    public func getGameHighScores(payload: Payload): String { this.call("getGameHighScores", payload) }
    public func getGameHighScoresInline(payload: Payload): String { this.call("getGameHighScores", payload) }
}

private func parseTelegramApiResponse(body: String): ApiResponse {
    let okValue = jsonFieldValue(body, "ok")
    if (okValue == "true") {
        let result = jsonFieldValue(body, "result")
        if (result.isEmpty()) {
            throw Exception("Could not parse Telegram response JSON: missing result")
        }
        return ApiResponse.success(result)
    }
    if (okValue == "false") {
        let errorCode = parseJsonInt(jsonFieldValue(body, "error_code"))
        let description = parseJsonString(jsonFieldValue(body, "description"))
        let parametersValue = jsonFieldValue(body, "parameters")
        return ApiResponse.failure(errorCode, description, parseResponseParameters(parametersValue))
    }
    throw Exception("Could not parse Telegram response JSON: missing ok")
}

private func parseResponseParameters(value: String): ResponseParameters {
    if (value.isEmpty()) {
        return ResponseParameters()
    }
    let migrateToChatId = parseJsonIntOrDefault(jsonFieldValue(value, "migrate_to_chat_id"), 0)
    let retryAfter = parseJsonIntOrDefault(jsonFieldValue(value, "retry_after"), 0)
    ResponseParameters(migrateToChatId, retryAfter)
}

private func jsonFieldValue(json: String, key: String): String {
    let pattern = "\"" + key + "\""
    let keyIndex = indexOfFrom(json, pattern, 0)
    if (keyIndex < 0) {
        return ""
    }
    var i = keyIndex + pattern.size
    while (i < json.size && isJsonWhitespace(json[i..i + 1])) {
        i += 1
    }
    if (i >= json.size || json[i..i + 1] != ":") {
        return ""
    }
    readJsonValue(json, i + 1)
}

private func readJsonValue(json: String, startIndex: Int64): String {
    var i = startIndex
    while (i < json.size && isJsonWhitespace(json[i..i + 1])) {
        i += 1
    }
    if (i >= json.size) {
        return ""
    }
    let first = json[i..i + 1]
    if (first == "\"") {
        return readJsonStringValue(json, i)
    }
    if (first == "{" || first == "[") {
        return readJsonCompositeValue(json, i)
    }
    let end = readJsonPrimitiveEnd(json, i)
    trimJson(json[i..end])
}

private func readJsonStringValue(json: String, startIndex: Int64): String {
    var i = startIndex + 1
    var escaped = false
    while (i < json.size) {
        let ch = json[i..i + 1]
        if (escaped) {
            escaped = false
        } else if (ch == "\\") {
            escaped = true
        } else if (ch == "\"") {
            return json[startIndex..i + 1]
        }
        i += 1
    }
    throw Exception("Could not parse Telegram response JSON: unterminated string")
}

private func readJsonCompositeValue(json: String, startIndex: Int64): String {
    var i = startIndex
    var depth: Int64 = 0
    var inString = false
    var escaped = false
    while (i < json.size) {
        let ch = json[i..i + 1]
        if (inString) {
            if (escaped) {
                escaped = false
            } else if (ch == "\\") {
                escaped = true
            } else if (ch == "\"") {
                inString = false
            }
        } else if (ch == "\"") {
            inString = true
        } else if (ch == "{" || ch == "[") {
            depth += 1
        } else if (ch == "}" || ch == "]") {
            depth -= 1
            if (depth == 0) {
                return json[startIndex..i + 1]
            }
        }
        i += 1
    }
    throw Exception("Could not parse Telegram response JSON: unterminated composite value")
}

private func readJsonPrimitiveEnd(json: String, startIndex: Int64): Int64 {
    var i = startIndex
    while (i < json.size) {
        let ch = json[i..i + 1]
        if (ch == "," || ch == "}" || ch == "]") {
            return i
        }
        i += 1
    }
    i
}

private func parseJsonString(value: String): String {
    let trimmed = trimJson(value)
    if (trimmed.size < 2 || trimmed[0..1] != "\"" || trimmed[trimmed.size - 1..trimmed.size] != "\"") {
        return trimmed
    }
    var out = ""
    var i: Int64 = 1
    while (i < trimmed.size - 1) {
        let ch = trimmed[i..i + 1]
        if (ch == "\\" && i + 1 < trimmed.size - 1) {
            let next = trimmed[i + 1..i + 2]
            if (next == "n") {
                out += "\n"
            } else if (next == "r") {
                out += "\r"
            } else if (next == "t") {
                out += "\t"
            } else {
                out += next
            }
            i += 2
        } else {
            out += ch
            i += 1
        }
    }
    out
}

private func parseJsonIntOrDefault(value: String, fallback: Int64): Int64 {
    if (value.isEmpty()) {
        return fallback
    }
    parseJsonInt(value)
}

private func parseJsonInt(value: String): Int64 {
    let trimmed = trimJson(value)
    if (trimmed.isEmpty()) {
        throw Exception("Could not parse Telegram response JSON: missing integer")
    }
    var sign: Int64 = 1
    var i: Int64 = 0
    if (trimmed[0..1] == "-") {
        sign = -1
        i = 1
    }
    var out: Int64 = 0
    var hasDigit = false
    while (i < trimmed.size) {
        let digit = digitValue(trimmed[i..i + 1])
        if (digit < 0) {
            break
        }
        hasDigit = true
        out = out * 10 + digit
        i += 1
    }
    if (!hasDigit) {
        throw Exception("Could not parse Telegram response JSON: invalid integer")
    }
    out * sign
}

private func digitValue(ch: String): Int64 {
    if (ch == "0") { return 0 }
    if (ch == "1") { return 1 }
    if (ch == "2") { return 2 }
    if (ch == "3") { return 3 }
    if (ch == "4") { return 4 }
    if (ch == "5") { return 5 }
    if (ch == "6") { return 6 }
    if (ch == "7") { return 7 }
    if (ch == "8") { return 8 }
    if (ch == "9") { return 9 }
    -1
}

private func trimJson(value: String): String {
    var start: Int64 = 0
    var end = value.size
    while (start < end && isJsonWhitespace(value[start..start + 1])) {
        start += 1
    }
    while (end > start && isJsonWhitespace(value[end - 1..end])) {
        end -= 1
    }
    value[start..end]
}

private func isJsonWhitespace(ch: String): Bool {
    ch == " " || ch == "\n" || ch == "\r" || ch == "\t"
}

private func indexOfFrom(value: String, needle: String, startIndex: Int64): Int64 {
    if (needle.isEmpty()) {
        return startIndex
    }
    var i = startIndex
    while (i + needle.size <= value.size) {
        if (value[i..i + needle.size] == needle) {
            return i
        }
        i += 1
    }
    -1
}

public class TransformableApi {
    public let raw: RawApiFacade
    public let installedTransformers: ArrayList<String>
    private let client: ApiClient

    public init(token: String) {
        this.client = ApiClient(ApiClientOptions())
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public init(token: String, options: ApiClientOptions) {
        this.client = ApiClient(options)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public init(token: String, options: ApiClientOptions, fetcher: CoreFetch) {
        this.client = ApiClient(options, fetcher)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public init(token: String, options: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope) {
        this.client = ApiClient(options, webhookReplyEnvelope)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public init(token: String, options: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope, fetcher: CoreFetch) {
        this.client = ApiClient(options, webhookReplyEnvelope, fetcher)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public func use(transformerName: String): TransformableApi {
        this.client.use(transformerName)
        this
    }

    public func use(transformer: Transformer): TransformableApi {
        this.client.use(transformer)
        this
    }

    public func use(transformerName: String, transformer: Transformer): TransformableApi {
        this.client.use(transformerName, transformer)
        this
    }
}

public func createRawApi(token: String): TransformableApi {
    TransformableApi(token)
}

public func createRawApi(token: String, options: ApiClientOptions): TransformableApi {
    TransformableApi(token, options)
}

public func createRawApi(token: String, options: ApiClientOptions, fetcher: CoreFetch): TransformableApi {
    TransformableApi(token, options, fetcher)
}

public func createRawApi(token: String, options: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope): TransformableApi {
    TransformableApi(token, options, webhookReplyEnvelope)
}

public func createRawApi(token: String, options: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope, fetcher: CoreFetch): TransformableApi {
    TransformableApi(token, options, webhookReplyEnvelope, fetcher)
}

public func zeroArgRawMethodNames(): Array<String> {
    [
        "getMe",
        "getWebhookInfo",
        "getForumTopicIconStickers",
        "getAvailableGifts",
        "logOut",
        "close",
        "getMyStarBalance",
        "removeMyProfilePhoto"
    ]
}

public func isZeroArgRawMethod(method: String): Bool {
    for (name in zeroArgRawMethodNames()) {
        if (name == method) {
            return true
        }
    }
    false
}
