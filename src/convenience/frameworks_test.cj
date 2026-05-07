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
    }

    @TestCase
    public func respondJsonSetsStatusBodyAndContentType(): Unit {
        let handler = callbackAdapter(Update(102), "secret")
        handler.respond("{\"method\":\"sendMessage\"}")

        @Expect(handler.response.statusCode, 200)
        @Expect(handler.response.contentType, "application/json")
        @Expect(handler.response.body, "{\"method\":\"sendMessage\"}")
        @Expect(handler.response.responded, true)
    }

    @TestCase
    public func unauthorizedAndEndUseSharedProtocol(): Unit {
        let unauthorizedHandler = expressAdapter(WebhookRequest(Update(103), WebhookHeaders(), "express"))
        unauthorizedHandler.unauthorized()

        @Expect(unauthorizedHandler.response.statusCode, 401)
        @Expect(unauthorizedHandler.response.body, WRONG_TOKEN_ERROR)
        @Expect(unauthorizedHandler.response.unauthorizedCalled, true)

        let endHandler = callbackAdapter(Update(104), "")
        endHandler.end()

        @Expect(endHandler.response.statusCode, 200)
        @Expect(endHandler.response.body, "")
        @Expect(endHandler.response.ended, true)
    }

    @TestCase
    public func adapterMapReportsSupportedAndNotApplicableStates(): Unit {
        @Expect(adapterStatus("callback").supported, true)
        @Expect(adapterStatus("http").supported, true)
        @Expect(adapterStatus("https").supported, true)
        @Expect(adapterStatus("express").supported, true)
        @Expect(adapterStatus("fastify").supported, false)
        @Expect(adapterStatus("fastify").state, "not-applicable")
    }

    @TestCase
    public func everyUpstreamAdapterHasCangjieStatusEntry(): Unit {
        @Expect(upstreamFrameworkAdapterCount(), 21)
        @Expect(registeredFrameworkAdapterCount(), 22)
        for (name in upstreamFrameworkAdapterNames()) {
            @Expect(hasAdapterStatus(name), true)
            @Expect(adapterStatus(name).name, name)
            @Expect(adapterStatus(name).reason.isEmpty(), false)
        }
    }
}
