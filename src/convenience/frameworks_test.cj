package grammy4cj.convenience

import std.unittest.*

import grammy4cj.types.Update

private func testHeaders(value: String): WebhookHeaders {
    WebhookHeaders()
        .set(SECRET_HEADER_LOWERCASE, value)
        .set(SECRET_HEADER, value)
}

private func adapterRequest(adapterName: String, updateId: Int64, headers: WebhookHeaders): WebhookRequest {
    WebhookRequest(Update(updateId), "{\"update_id\":${updateId}}", headers, adapterName)
}

private func expectedHeaderFromDualSource(adapterName: String): String {
    if (adapterName == "aws-lambda" || adapterName == "aws-lambda-async") {
        return "secret-canonical"
    }
    "secret-lower"
}

private func updateSourceUsesJson(adapterName: String): Bool {
    adapterUpdateSource(adapterName) != "body-object"
}

private func assertBodySourceWasRead(adapterName: String, request: WebhookRequest): Unit {
    let source = adapterUpdateSource(adapterName)
    if (source == "body-object") {
        @Expect(request.bodyObjectReads, 1)
        @Expect(request.jsonReads, 0)
        @Expect(request.rawStreamReads, 0)
    } else if (source == "node-raw-json-stream") {
        @Expect(request.bodyObjectReads, 0)
        @Expect(request.jsonReads, 0)
        @Expect(request.rawStreamReads, 1)
    } else {
        @Expect(request.bodyObjectReads, 0)
        @Expect(request.jsonReads, 1)
        @Expect(request.rawStreamReads, 0)
    }
}

@Test
public class FrameworkAdaptersTest {
    @TestCase
    public func registryContainsExactlyUpstreamTwentyOneAdapters(): Unit {
        @Expect(upstreamFrameworkAdapterCount(), 21)
        @Expect(registeredFrameworkAdapterCount(), 21)
        @Expect(frameworkAdapterPublicShapeCount(), 21)
        @Expect(adapterStatus("callback").supported, false)
        @Expect(adapterStatus("unknown").supported, false)

        for (contract in frameworkAdapterContracts()) {
            @Expect(hasAdapterStatus(contract.name), true)
            @Expect(adapterStatus(contract.name).supported, true)
            @Expect(adapterStatus(contract.name).name, contract.name)
            @Expect(adapterStatus(contract.name).reason.isEmpty(), false)
            @Expect(contract.cangjiePublicSignature, frameworkAdapterPublicShape(contract.name).cangjieSignature)
            @Expect(contract.fakeProtocolEntry, frameworkAdapterPublicShape(contract.name).fakeProtocolEntry)
        }
    }

    @TestCase
    public func adapterPublicShapesMirrorUpstreamSignaturesWithoutUsingFakeRequestAsPublicShape(): Unit {
        for (shape in frameworkAdapterPublicShapes()) {
            @Expect(hasAdapterStatus(shape.name), true)
            @Expect(shape.upstreamSignature.isEmpty(), false)
            @Expect(shape.cangjieSignature.isEmpty(), false)
            @Expect(shape.requestShape.isEmpty(), false)
            @Expect(shape.responseShape.isEmpty(), false)
            @Expect(shape.fakeProtocolEntry.isEmpty(), false)
            @Expect(shape.usesWebhookRequestAsPublicShape(), false)
        }

        @Expect(frameworkAdapterPublicShape("aws-lambda").upstreamSignature, "(event, context, callback) -> ReqResHandler")
        @Expect(frameworkAdapterPublicShape("azure").requestShape, "request.body plus request.headers")
        @Expect(frameworkAdapterPublicShape("bun").responseShape, "handlerReturn Response")
        @Expect(frameworkAdapterPublicShape("http").requestShape, "Node raw JSON stream plus lowercase headers")
        @Expect(frameworkAdapterPublicShape("std/http").cangjieSignature, "StdHttpAdapter(req)")
        @Expect(frameworkAdapterPublicShape("unknown").cangjieSignature, "unsupported")
    }

    @TestCase
    public func eachAdapterReadsUpstreamBodyAndSecretHeaderSource(): Unit {
        var updateId: Int64 = 100
        for (contract in frameworkAdapterContracts()) {
            let headers = WebhookHeaders()
                .set(SECRET_HEADER_LOWERCASE, "secret-lower")
                .set(SECRET_HEADER, "secret-canonical")
            let request = adapterRequest(contract.name, updateId, headers)
            let handler = frameworkAdapter(contract.name)(request)

            @Expect(handler.adapterName, contract.name)
            @Expect(handler.update.updateId, updateId)
            @Expect(handler.header, expectedHeaderFromDualSource(contract.name))
            @Expect(handler.headerPresent, true)
            @Expect(request.headerReads, 1)
            @Expect(handler.response.updateSource, contract.updateSource)
            @Expect(handler.response.headerSource, contract.headerSource)
            assertBodySourceWasRead(contract.name, request)

            updateId += 1
        }
    }

    @TestCase
    public func eachAdapterEndsRespondsAndRejectsWithUpstreamSemantics(): Unit {
        var updateId: Int64 = 200
        for (contract in frameworkAdapterContracts()) {
            let request = adapterRequest(contract.name, updateId, testHeaders("secret"))

            let endHandler = frameworkAdapter(contract.name)(request)
            endHandler.end()
            @Expect(endHandler.response.statusCode, contract.endStatusCode)
            @Expect(endHandler.response.body, contract.endBody)
            @Expect(endHandler.response.ended, true)
            @Expect(endHandler.response.lastAction, "end")
            @Expect(endHandler.response.endProtocol, contract.endProtocol)
            @Expect(endHandler.response.responseDelivery, contract.responseDelivery)
            @Expect(endHandler.response.handlerReturnAvailable, contract.handlerReturnAvailable)
            @Expect(endHandler.response.handlerReturnKind, contract.handlerReturnKind)
            if (contract.handlerReturnAvailable) {
                @Expect(endHandler.response.handlerReturnResolved, true)
            }

            let respondHandler = frameworkAdapter(contract.name)(request)
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

            let unauthorizedHandler = frameworkAdapter(contract.name)(request)
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
    }

    @TestCase
    public func webhookCallbacksDriveEveryRegisteredAdapterThroughRealAdapter(): Unit {
        var updateId: Int64 = 400
        for (contract in frameworkAdapterContracts()) {
            let normalHandler = FakeWebhookUpdateHandler()
            let normalCallback = webhookCallback(normalHandler, contract.name, WebhookOptions("shared-secret"))
            let normal = normalCallback.handle(adapterRequest(contract.name, updateId, testHeaders("shared-secret")))

            @Expect(normal.unauthorized, false)
            @Expect(normal.response.ended, true)
            @Expect(normal.response.responseDelivery, contract.responseDelivery)
            @Expect(normal.response.handlerReturnKind, contract.handlerReturnKind)
            @Expect(normalHandler.handleUpdateCount, 1)
            @Expect(normalHandler.lastUpdateId, updateId)

            let unauthorizedHandler = FakeWebhookUpdateHandler()
            let unauthorizedCallback = webhookCallback(unauthorizedHandler, contract.name, WebhookOptions("shared-secret"))
            let unauthorized = unauthorizedCallback.handle(adapterRequest(contract.name, updateId + 1, testHeaders("wrong-secret")))

            @Expect(unauthorized.unauthorized, true)
            @Expect(unauthorized.response.statusCode, 401)
            @Expect(unauthorized.response.unauthorizedCalled, true)
            @Expect(unauthorized.response.body, contract.unauthorizedBody)
            @Expect(unauthorizedHandler.handleUpdateCount, 0)

            let replyHandler = FakeWebhookUpdateHandler()
            replyHandler.webhookReplyJson = "{\"method\":\"sendMessage\",\"adapter\":\"${contract.name}\"}"
            let replyCallback = webhookCallback(replyHandler, contract.name, WebhookOptions("shared-secret"))
            let reply = replyCallback.handle(adapterRequest(contract.name, updateId + 2, testHeaders("shared-secret")))

            @Expect(reply.usedWebhookReply, true)
            @Expect(reply.response.responded, true)
            @Expect(reply.response.ended, false)
            @Expect(reply.response.contentType, "application/json")
            @Expect(reply.response.body, "{\"method\":\"sendMessage\",\"adapter\":\"${contract.name}\"}")
            if (contract.handlerReturnAvailable) {
                @Expect(reply.response.handlerReturnResolved, true)
            }

            updateId += 3
        }
    }

    @TestCase
    public func rawJsonAdaptersRejectMalformedBodiesWhenUpdateIsRead(): Unit {
        for (contract in frameworkAdapterContracts()) {
            if (updateSourceUsesJson(contract.name)) {
                var thrown = false
                try {
                    let handler = frameworkAdapter(contract.name)(
                        WebhookRequest.raw("{", WebhookHeaders(), contract.name)
                    )
                    let _ = handler.update
                } catch (e: MalformedWebhookBodyError) {
                    thrown = true
                    @Expect(e.adapterName, contract.name)
                }
                @Expect(thrown, true)
            }
        }
    }

    @TestCase
    public func missingBodiesFollowAdapterBodySourceContract(): Unit {
        for (contract in frameworkAdapterContracts()) {
            let handler = frameworkAdapter(contract.name)(
                WebhookRequest.missingBody(WebhookHeaders(), contract.name)
            )
            if (contract.name == "aws-lambda" || contract.name == "aws-lambda-async") {
                @Expect(handler.update.updateId, 0)
            } else {
                var thrown = false
                try {
                    let _ = handler.update
                } catch (e: MissingWebhookBodyError) {
                    thrown = true
                    @Expect(e.adapterName, contract.name)
                }
                @Expect(thrown, true)
            }
        }
    }

    @TestCase
    public func secretHeaderSourcesRespectCanonicalLowercaseAndMultiValueRules(): Unit {
        let awsHeaders = WebhookHeaders()
            .set(SECRET_HEADER_LOWERCASE, "lower")
            .set(SECRET_HEADER, "canonical")
        let aws = awsLambdaAdapter(adapterRequest("aws-lambda", 500, awsHeaders))
        @Expect(aws.header, "canonical")
        @Expect(aws.headerPresent, true)

        let fastifyHeaders = WebhookHeaders()
            .set(SECRET_HEADER, "canonical")
            .set(SECRET_HEADER_LOWERCASE, "lower")
        let fastify = fastifyAdapter(adapterRequest("fastify", 501, fastifyHeaders))
        @Expect(fastify.header, "lower")

        let httpHeaders = WebhookHeaders()
            .setValues(SECRET_HEADER_LOWERCASE, ["first", "second"])
        let http = nodeHttpAdapter(adapterRequest("http", 502, httpHeaders))
        @Expect(http.header, "first")

        let fetchHeaders = WebhookHeaders()
            .set(SECRET_HEADER_LOWERCASE, "fetch-lower")
        let bun = bunAdapter(adapterRequest("bun", 503, fetchHeaders))
        @Expect(bun.header, "fetch-lower")
    }

    @TestCase
    public func malformedBodyIsNotParsedBeforeUnauthorizedResponse(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "http", WebhookOptions("expected"))

        let result = callback.handle(WebhookRequest.raw(
            "{",
            WebhookHeaders().setValues(SECRET_HEADER_LOWERCASE, ["wrong", "ignored"]),
            "http"
        ))

        @Expect(result.unauthorized, true)
        @Expect(result.response.statusCode, 401)
        @Expect(handler.handleUpdateCount, 0)
    }

    @TestCase
    public func malformedBodyIsPropagatedAfterSecretPasses(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "http", WebhookOptions("expected"))
        var thrown = false

        try {
            let _ = callback.handle(WebhookRequest.raw(
                "{",
                WebhookHeaders().set(SECRET_HEADER_LOWERCASE, "expected"),
                "http"
            ))
        } catch (e: MalformedWebhookBodyError) {
            thrown = true
            @Expect(e.adapterName, "http")
        }

        @Expect(thrown, true)
        @Expect(handler.handleUpdateCount, 0)
    }

    @TestCase
    public func nonEmptyRawJsonWithoutUpdateIdIsMalformed(): Unit {
        let handler = bunAdapter(
            WebhookRequest.raw("{,}", WebhookHeaders(), "bun")
        )
        var thrown = false

        try {
            let _ = handler.update
        } catch (e: MalformedWebhookBodyError) {
            thrown = true
            @Expect(e.adapterName, "bun")
        }

        @Expect(thrown, true)
    }

    @TestCase
    public func callbackAdapterExistsOnlyAsWebhookTestAdapter(): Unit {
        @Expect(adapterIsSupported("callback"), false)
        let callback = callbackAdapter(Update(900), "secret")
        @Expect(callback.adapterName, "callback")
        @Expect(callback.header, "secret")
        callback.respond("{\"ok\":true}")
        @Expect(callback.response.responded, true)
        @Expect(callback.response.body, "{\"ok\":true}")
    }

    @TestCase
    public func unsupportedAdapterContractStillThrows(): Unit {
        var unknownThrown = false
        try {
            let _ = frameworkAdapterContract("unknown")
        } catch (e: UnsupportedAdapterError) {
            unknownThrown = true
            @Expect(e.adapterName, "unknown")
        }

        @Expect(unknownThrown, true)
    }
}
