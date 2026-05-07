package grammy4cj.convenience

import std.unittest.*

import grammy4cj.types.Update

@Test
public class FrameworkAdaptersTest {
    @TestCase
    public func frameworkAdaptersMirrorUpstreamRequestResponseContracts(): Unit {
        @Expect(upstreamFrameworkAdapterCount(), 21)
        @Expect(registeredFrameworkAdapterCount(), 22)
        @Expect(adapterStatus("callback").supported, true)
        @Expect(adapterStatus("unknown").supported, false)

        var updateId: Int64 = 100
        for (contract in frameworkAdapterContracts()) {
            @Expect(hasAdapterStatus(contract.name), true)
            @Expect(adapterStatus(contract.name).supported, true)
            @Expect(adapterStatus(contract.name).name, contract.name)
            @Expect(adapterStatus(contract.name).reason.isEmpty(), false)

            let headers = WebhookHeaders()
                .set(SECRET_HEADER_LOWERCASE, "secret-lower")
                .set(SECRET_HEADER, "secret-canonical")
            let request = WebhookRequest(Update(updateId), "{\"update_id\":${updateId}}", headers, contract.name)
            let handler = createReqResHandler(contract.name, request)

            @Expect(handler.adapterName, contract.name)
            @Expect(handler.update.updateId, updateId)
            @Expect(handler.header, "secret-lower")
            @Expect(handler.headerPresent, true)
            @Expect(handler.handlerReturn.handlerReturnAvailable, contract.handlerReturnAvailable)
            @Expect(handler.handlerReturn.handlerReturnKind, contract.handlerReturnKind)
            @Expect(handler.response.updateSource, contract.updateSource)
            @Expect(handler.response.headerSource, contract.headerSource)
            @Expect(handler.response.responseDelivery, contract.responseDelivery)

            let endHandler = createReqResHandler(contract.name, request)
            endHandler.end()
            @Expect(endHandler.response.statusCode, contract.endStatusCode)
            @Expect(endHandler.response.body, contract.endBody)
            @Expect(endHandler.response.ended, true)
            @Expect(endHandler.response.lastAction, "end")
            @Expect(endHandler.response.endProtocol, contract.endProtocol)
            if (contract.handlerReturnAvailable) {
                @Expect(endHandler.response.handlerReturnResolved, true)
            } else {
                @Expect(contract.responseDelivery.isEmpty(), false)
            }

            let respondHandler = createReqResHandler(contract.name, request)
            respondHandler.respond("{\"method\":\"sendMessage\"}")
            @Expect(respondHandler.response.statusCode, 200)
            @Expect(respondHandler.response.contentType, "application/json")
            @Expect(respondHandler.response.body, "{\"method\":\"sendMessage\"}")
            @Expect(respondHandler.response.responded, true)
            @Expect(respondHandler.response.lastAction, "respond")
            @Expect(respondHandler.response.respondProtocol, contract.respondProtocol)
            if (contract.handlerReturnAvailable) {
                @Expect(respondHandler.response.handlerReturnResolved, true)
            }

            let unauthorizedHandler = createReqResHandler(contract.name, request)
            unauthorizedHandler.unauthorized()
            @Expect(unauthorizedHandler.response.statusCode, 401)
            @Expect(unauthorizedHandler.response.body, contract.unauthorizedBody)
            @Expect(unauthorizedHandler.response.statusText, contract.unauthorizedStatusText)
            @Expect(unauthorizedHandler.response.unauthorizedCalled, true)
            @Expect(unauthorizedHandler.response.lastAction, "unauthorized")
            @Expect(unauthorizedHandler.response.unauthorizedProtocol, contract.unauthorizedProtocol)
            if (contract.handlerReturnAvailable) {
                @Expect(unauthorizedHandler.response.handlerReturnResolved, true)
            }

            updateId += 1
        }

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

        var unknownThrown = false
        try {
            let _ = frameworkAdapterContract("unknown")
        } catch (e: UnsupportedAdapterError) {
            unknownThrown = true
            @Expect(e.adapterName, "unknown")
        }

        @Expect(httpThrown, true)
        @Expect(httpsThrown, true)
        @Expect(unknownThrown, true)
    }
}
