package grammy4cj

import std.unittest.*
import grammy4cj.architecture.rootPublicExportManifestEntryCount
import grammy4cj.architecture.rootPublicExportManifestExpertPublicCount
import grammy4cj.architecture.rootPublicExportManifestInternalCount
import grammy4cj.architecture.rootPublicExportManifestPublicCount
import grammy4cj.architecture.rootPublicExportManifestTestOnlyCount
import grammy4cj.architecture.rootSurfaceExpectedFrameworkAdapterCount
import grammy4cj.architecture.rootSurfaceExpectedHonoHandlerReturnKind
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

@Test
public class Grammy4cjRootTest {
    @TestCase
    public func exportsVersionAndBaseline(): Unit {
        @Expect(GRAMMY4CJ_VERSION, "0.1.0")
        @Expect(sourceBaselineHead(), "c865dd3a4d26911b01c83695e3845c7245870a5d")
        @Expect(GRAMMY_BASELINE_TAG, "v1.42.0-5-gc865dd3")
    }

    @TestCase
    public func rootPackageReExportsLayerOneTypes(): Unit {
        let bot = Bot("test-token")
        let update = Update(1001)
        let me = UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
        let ctx = Context(update, bot.api, me)

        @Expect(bot.token, "test-token")
        @Expect(ctx.update.updateId, 1001)
        @Expect(ctx.me.username, "grammy4cj_bot")
        @Expect(API_CONSTANTS.defaultUpdateTypeCount, 23)
        @Expect(InputFile.fromUrl("https://example.test/files/photo.jpg").toRaw().summary(), "url:deferred-fetch:photo.jpg")
    }

    @TestCase
    public func rootPackageReExportsCoreAndConvenienceSurface(): Unit {
        let media = InputMediaBuilder.photo("photo-file-id")
        let inline = InlineQueryResultBuilder.article("id-1", "title")
        let keyboard = Keyboard()
        let inlineKeyboard = InlineKeyboard()
        let storage = MemorySessionStorage<String>()

        keyboard.text("hello")
        inlineKeyboard.text("press", "payload")
        storage.write("session:1", "value")

        @Expect(Api("token").endpointFor("sendMessage"), "https://api.telegram.org/bottoken/sendMessage")
        @Expect(media.kind, "photo")
        @Expect(inline.toJSON().contains("\"type\":\"article\""), true)
        @Expect(keyboard.buttonCount, 1)
        @Expect(inlineKeyboard.buttonCount, 1)
        @Expect(storage.has("session:1"), true)
    }

    @TestCase
    public func rootPackageReExportsIntegratedGateSurface(): Unit {
        let sessionMiddleware = multiSession<String, String>(
            MultiSessionOptions2<String, String>(SessionOptions<String>(), SessionOptions<String>()),
        )

        @Expect(rootPublicExportManifestEntryCount(), 59)
        @Expect(rootPublicExportManifestPublicCount(), 46)
        @Expect(rootPublicExportManifestExpertPublicCount(), 9)
        @Expect(rootPublicExportManifestInternalCount(), 4)
        @Expect(rootPublicExportManifestTestOnlyCount(), 0)
        @Expect(rootSurfaceExpectedFrameworkAdapterCount(), 21)
        @Expect(rootSurfaceExpectedHonoHandlerReturnKind(), "promise-response")
        @Expect(sessionMiddleware is MultiSessionMiddleware2<String, String>, true)
    }
}
