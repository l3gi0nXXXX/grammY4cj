<div align="center"><a href="https://grammy.dev"><img src="https://raw.githubusercontent.com/grammyjs/website/main/logos/grammY.png" alt="grammY"></a></h1></div>

<div align="right">

# The Telegram Bot Framework

</div>

<div align="center">

<!-- deno-fmt-ignore-start -->

[![Bot API](https://img.shields.io/badge/Bot%20API-9.6-blue?logo=telegram&style=flat&labelColor=000&color=3b82f6)](https://core.telegram.org/bots/api)
[![All Contributors](https://img.shields.io/github/all-contributors/grammyjs/grammy?style=flat&labelColor=000&color=3b82f6)](#contributors-)

<!-- deno-fmt-ignore-end -->

## _[docs.](https://grammy.dev) [reference.](https://grammy.dev/ref) [chat.](https://telegram.me/grammyjs) [news.](https://telegram.me/grammyjs_news)_

</div>

**grammY4cj is the Cangjie implementation of [grammY](https://github.com/grammyjs/grammY), the Telegram Bot Framework.** It aims to preserve grammY's public API, runtime behavior, and development model as closely as Cangjie permits.

You want grammY4cj because it brings grammY's easy-to-use and scalable design to Cangjie. It follows grammY's source layout, middleware model, context shortcuts, Telegram Bot API wrappers, and framework integrations so that upstream changes can be tracked with minimal porting overhead.

Are you ready?

Bots are written in [Cangjie](https://cangjie-lang.cn/) and run on Cangjie Native.

## Quickstart

> If you are new to Telegram bots, read the official [Introduction for Developers](https://core.telegram.org/bots) written by the Telegram team.

Visit [@BotFather](https://t.me/BotFather) and create a new bot. You will obtain a **bot token**.

Add grammY4cj to your Cangjie package and build it with

```bash
cjpm build
```

Then create a file `bot.cj` with this content:

```cangjie
import grammy4cj.*

main() {
    let bot = Bot("") // <-- place your bot token in this string

    // Register listeners to handle messages
    bot.on("message:text", { ctx: Context, _next: NextFunction =>
        ctx.reply("Echo: " + ctx.message.text)
    })

    // Start the bot using long polling
    bot.start()
}
```

Now you can run the bot with your Cangjie toolchain, and it will echo all received text messages.

Congrats! You just wrote a Telegram bot :)

## Going Further

grammY has an excellent [documentation](https://grammy.dev), and an [API Reference](https://grammy.dev/ref). grammY4cj follows these concepts and maps them to Cangjie APIs.

If you are still stuck, just join the [Telegram chat](https://t.me/grammyjs) and ask for help. People are nice there and we appreciate your question, no matter what it is :)

Here are some more resources to support you:

## Resources

### [grammY website](https://grammy.dev)

—main project website and documentation.
Gets you started and explains all concepts.

### [grammY API reference](https://grammy.dev/ref)

—reference of everything that grammY exports.
Useful to look up descriptions about any element of grammY.

### [grammY examples](https://github.com/grammyjs/examples)

—repository full of example bots.
Includes a setup to easily run any of them.

### [Awesome grammY](https://github.com/grammyjs/awesome-grammY)

—list of awesome projects built with grammY.
Helpful if you want to see some real-world usage.

### [grammY chat](https://t.me/grammyjs)

—The chat where you can ask any question about grammY or bots in general.
We are also open for feedback, ideas, and contributions!

The Russian community chat can be found [here](https://t.me/grammyjs_ru).

### [grammY news](https://t.me/grammyjs_news)

—The channel where updates to grammY and the ecosystem are posted.

### [Telegram Bot API Reference](https://core.telegram.org/bots/api)

—documentation of the API that Telegram offers, and that grammY connects to under the hood.

## Deno Support

All grammY packages published by [@grammyjs](https://github.com/grammyjs) run natively on [Deno](https://deno.land). grammY4cj is a Cangjie port and runs on Cangjie Native instead.

However, given that grammY's public behavior is the source contract for this project, Deno-specific upstream code is still useful when tracking platform abstractions, web bundles, and runtime boundaries.

You may also be interested in [why grammY supports Deno](https://grammy.dev/resources/faq.html#why-do-you-support-deno).

## JavaScript Bundles

The grammY core package is available as a JavaScript bundle via <https://bundle.deno.dev/>.
This helps compare published upstream behavior against the Cangjie port when investigating browser and worker compatibility.

Being compatible with browsers is especially useful for running bots on Cloudflare Workers.
grammY4cj keeps the same architecture target, while the executable runtime is Cangjie Native.

## [Contribution Guide »](./CONTRIBUTING.md)

## Contributors ✨

Thanks goes to grammY's maintainers and contributors for the original framework, and to all grammY4cj contributors who help port it to Cangjie.

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification.
Contributions of any kind welcome!
