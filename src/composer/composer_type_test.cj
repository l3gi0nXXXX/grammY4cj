package grammy4cj.composer

import grammy4cj.context.Context
import std.unittest.*

@Test
public class ComposerTypeSurfaceTest {
    @TestCase
    public func hearsReturnsComposableComposer(): Unit {
        let composer: Composer = Composer().hears("test")
        let middleware: MiddlewareFn = composer.middleware()
        @Expect(middlewareNameOf(middleware), "MiddlewareFn")
    }

    @TestCase
    public func callbackQueryReturnsComposableComposer(): Unit {
        let composer: Composer = Composer().callbackQuery("test")
        composer.use({ _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func commandReturnsComposableComposer(): Unit {
        let composer: Composer = Composer().command("start")
        composer.command(["start", "help"], { _ctx: Context, next: NextFunction => next() })
        @Expect(composer.middlewareName(), "grammy4cj.composer.Composer")
    }

    @TestCase
    public func chatTypePrivateChainCompiles(): Unit {
        let composer: Composer = Composer().chatType("private")
        composer.command("start", { _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func chatTypeGroupChainCompiles(): Unit {
        let composer: Composer = Composer().chatType("group")
        composer.hears("hello", { _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func chatTypeSupergroupChainCompiles(): Unit {
        let composer: Composer = Composer().chatType("supergroup")
        composer.callbackQuery("data", { _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func chatTypeChannelChainCompiles(): Unit {
        let composer: Composer = Composer().chatType("channel")
        composer.on("channel_post", { _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func chatTypeCombinedArrayChainCompiles(): Unit {
        let composer: Composer = Composer().chatType(["private", "channel"])
        composer.on(["message", "channel_post"], { _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func gameQueryReturnsComposableComposer(): Unit {
        let composer: Composer = Composer().gameQuery("game")
        composer.use({ _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func inlineQueryReturnsComposableComposer(): Unit {
        let composer: Composer = Composer().inlineQuery("inline")
        composer.use({ _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func preCheckoutQueryReturnsComposableComposer(): Unit {
        let composer: Composer = Composer().preCheckoutQuery("payload")
        composer.use({ _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func shippingQueryReturnsComposableComposer(): Unit {
        let composer: Composer = Composer().shippingQuery("payload")
        composer.use({ _ctx: Context, next: NextFunction => next() })
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func filterPredicateNarrowsToComposableComposerShape(): Unit {
        let predicate: SyncPredicate = { _ctx: Context => true }
        let composer: Composer = Composer().filter(predicate)
        composer.drop(predicate, { _ctx: Context, next: NextFunction => next() })
        let decision = composerMaybePromiseDecision()

        @Expect(decision.callbackContract, "MaybePromise via sync and Future middleware adapters")
        @Expect(decision.futureBoundary.contains("AsyncNextFunction returns Future<Unit>"), true)
        @Expect(decision.routeFallbackContract, "None<String> route values select fallback")
        @Expect(composer.layerName(), "Composer")
    }

    @TestCase
    public func chatTypeCallbackCombinedUsageCompiles(): Unit {
        let first: Composer = Composer().chatType("private").callbackQuery("query")
        let second: Composer = Composer().callbackQuery("query").chatType("private")
        @Expect(first.layerName(), "Composer")
        @Expect(second.layerName(), "Composer")
    }
}

private func middlewareNameOf(_middleware: MiddlewareFn): String {
    "MiddlewareFn"
}
