package grammy4cj.context

import grammy4cj.core.Api
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

public class Context {
    public let update: Update
    public let api: Api
    public let me: UserFromGetMe

    public init(update: Update, api: Api, me: UserFromGetMe) {
        this.update = update
        this.api = api
        this.me = me
    }

    public func updateId(): Int64 {
        this.update.updateId
    }

    public func botInfoUsername(): String {
        this.me.username
    }
}
