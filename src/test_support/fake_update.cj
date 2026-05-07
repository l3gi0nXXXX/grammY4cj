package grammy4cj.test_support

import grammy4cj.types.Chat
import grammy4cj.types.Message
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

public func fakeChat(id: Int64): Chat {
    Chat(id, "private")
}

public func fakeMessage(messageId: Int64, text: String): Message {
    Message(messageId, fakeChat(123456), text)
}

public func fakeMessageUpdate(updateId: Int64): Update {
    Update(updateId)
}

public func fakeBotInfo(): UserFromGetMe {
    UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
}
