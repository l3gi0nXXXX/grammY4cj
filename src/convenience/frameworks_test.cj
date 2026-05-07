package grammy4cj.convenience

import std.unittest.*

import grammy4cj.types.Update

@Test
public class FrameworkAdaptersTest {
    @TestCase
    public func reqResHandlerReadsSecretHeaderCaseInsensitively(): Unit {
        let headers = WebhookHeaders().set(SECRET_HEADER_LOWERCASE, "secret-lower")
        let request = WebhookRequest(Update(101), headers, "http")
        let handler = nodeHttpAdapter(request)

        @Expect(handler.update.updateId, 101)
        @Expect(handler.header, "secret-lower")
        @Expect(handler.headerPresent, true)
    }

    @TestCase
    public func respondJsonSetsStatusBodyAndContentTypeForEveryAdapter(): Unit {
        for (name in registeredFrameworkAdapterNames()) {
            let handler = createReqResHandler(name, WebhookRequest(Update(102), WebhookHeaders(), name))
            handler.respond("{\"method\":\"sendMessage\"}")

            @Expect(handler.response.statusCode, 200)
            @Expect(handler.response.contentType, "application/json")
            @Expect(handler.response.body, "{\"method\":\"sendMessage\"}")
            @Expect(handler.response.responded, true)
            @Expect(handler.response.lastAction, "respond")
            if (adapterHasHandlerReturn(name)) {
                @Expect(handler.response.handlerReturnResolved, true)
            }
        }
    }

    @TestCase
    public func unauthorizedUsesUpstreamAdapterProtocol(): Unit {
        for (name in registeredFrameworkAdapterNames()) {
            let handler = createReqResHandler(name, WebhookRequest(Update(103), WebhookHeaders(), name))
            handler.unauthorized()

            @Expect(handler.response.statusCode, 401)
            @Expect(handler.response.body, adapterUnauthorizedBody(name))
            @Expect(handler.response.statusText, adapterUnauthorizedStatusText(name))
            @Expect(handler.response.unauthorizedCalled, true)
            @Expect(handler.response.lastAction, "unauthorized")
            if (adapterHasHandlerReturn(name)) {
                @Expect(handler.response.handlerReturnResolved, true)
            }
        }
    }

    @TestCase
    public func endUsesUpstreamAdapterProtocol(): Unit {
        for (name in registeredFrameworkAdapterNames()) {
            let handler = createReqResHandler(name, WebhookRequest(Update(104), WebhookHeaders(), name))
            handler.end()

            @Expect(handler.response.statusCode, adapterEndStatusCode(name))
            @Expect(handler.response.body, adapterEndBody(name))
            @Expect(handler.response.ended, true)
            @Expect(handler.response.lastAction, "end")
            if (adapterHasHandlerReturn(name)) {
                @Expect(handler.response.handlerReturnResolved, true)
            }
        }
    }

    @TestCase
    public func adapterMapReportsAllUpstreamAdaptersAsSupported(): Unit {
        @Expect(upstreamFrameworkAdapterCount(), 21)
        @Expect(registeredFrameworkAdapterCount(), 22)
        @Expect(adapterStatus("callback").supported, true)
        @Expect(adapterStatus("fastify").supported, true)
        @Expect(adapterStatus("fastify").state, "supported")
        @Expect(adapterStatus("unknown").supported, false)
        @Expect(adapterStatus("unknown").state, "unknown")
    }

    @TestCase
    public func everyUpstreamAdapterHasCangjieStatusEntry(): Unit {
        for (name in upstreamFrameworkAdapterNames()) {
            @Expect(hasAdapterStatus(name), true)
            @Expect(adapterStatus(name).supported, true)
            @Expect(adapterStatus(name).name, name)
            @Expect(adapterStatus(name).reason.isEmpty(), false)
        }
    }

    @TestCase
    public func everyRegisteredAdapterExposesUpdateHeaderAndHandlerReturnContract(): Unit {
        var updateId: Int64 = 200
        for (name in registeredFrameworkAdapterNames()) {
            let headers = WebhookHeaders().set(SECRET_HEADER, "secret")
            let handler = createReqResHandler(name, WebhookRequest(Update(updateId), headers, name))

            @Expect(handler.adapterName, name)
            @Expect(handler.update.updateId, updateId)
            @Expect(handler.header, "secret")
            @Expect(handler.headerPresent, true)
            @Expect(handler.handlerReturn.handlerReturnAvailable, adapterHasHandlerReturn(name))
            @Expect(handler.handlerReturn.handlerReturnKind, adapterHandlerReturnKind(name))
            @Expect(handler.handlerReturn.handlerReturnResolved, false)

            updateId += 1
        }
    }

    @TestCase
    public func nodeHttpAdaptersRejectMalformedJsonBodies(): Unit {
        var httpThrown = false
        try {
            let _ = createReqResHandler(
                "http",
                WebhookRequest(Update(301), "{", WebhookHeaders(), "http")
            )
        } catch (e: MalformedWebhookBodyError) {
            httpThrown = true
            @Expect(e.adapterName, "http")
        }

        var httpsThrown = false
        try {
            let _ = createReqResHandler(
                "https",
                WebhookRequest(Update(302), "{", WebhookHeaders(), "https")
            )
        } catch (e: MalformedWebhookBodyError) {
            httpsThrown = true
            @Expect(e.adapterName, "https")
        }

        @Expect(httpThrown, true)
        @Expect(httpsThrown, true)
    }

    @TestCase
    public func unknownAdapterThrowsUnsupportedAdapterError(): Unit {
        var thrown = false
        try {
            let _ = createReqResHandler("unknown", WebhookRequest(Update(401), WebhookHeaders(), "unknown"))
        } catch (e: UnsupportedAdapterError) {
            thrown = true
            @Expect(e.adapterName, "unknown")
        }

        @Expect(thrown, true)
    }
}
