package grammy4cj

import std.unittest.*

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
        @Expect(defaultPlatform().runtime, "cjnative")
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

        @Expect(apiWrapperCount(), 180)
        @Expect(media.kind, "photo")
        @Expect(inline.toJSON().contains("\"type\":\"article\""), true)
        @Expect(keyboard.buttonCount, 1)
        @Expect(inlineKeyboard.buttonCount, 1)
        @Expect(registeredFrameworkAdapterCount(), 22)
        @Expect(storage.has("session:1"), true)
    }
}
