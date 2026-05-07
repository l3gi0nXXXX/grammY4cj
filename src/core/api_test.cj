package grammy4cj.core

import std.unittest.*

private func methodName(payload: Payload): String {
    for (field in payload.fields) {
        if (field.key == "__method") {
            return field.value
        }
    }
    ""
}

@Test
public class ApiWrapperSkeletonTest {
    @TestCase
    public func lifecycleWrappersRecordRawMethodNames(): Unit {
        let api = Api("token")
        let empty = Payload("")

        @Expect(methodName(api.getUpdates(empty)), "getUpdates")
        @Expect(methodName(api.setWebhook(empty)), "setWebhook")
        @Expect(methodName(api.deleteWebhook(empty)), "deleteWebhook")
        @Expect(methodName(api.getWebhookInfo(empty)), "getWebhookInfo")
        @Expect(methodName(api.getMe(empty)), "getMe")
        @Expect(methodName(api.logOut(empty)), "logOut")
        @Expect(methodName(api.close(empty)), "close")
    }

    @TestCase
    public func sendMessageFamilyWrappersRecordRawMethodNames(): Unit {
        let api = Api("token")
        let payload = Payload("").addValue("chat_id", "42")

        @Expect(methodName(api.sendMessage(payload)), "sendMessage")
        @Expect(methodName(api.sendMessageDraft(payload)), "sendMessageDraft")
        @Expect(methodName(api.forwardMessage(payload)), "forwardMessage")
        @Expect(methodName(api.forwardMessages(payload)), "forwardMessages")
        @Expect(methodName(api.copyMessage(payload)), "copyMessage")
        @Expect(methodName(api.copyMessages(payload)), "copyMessages")
        @Expect(methodName(api.sendPhoto(payload)), "sendPhoto")
        @Expect(methodName(api.sendAudio(payload)), "sendAudio")
        @Expect(methodName(api.sendDocument(payload)), "sendDocument")
        @Expect(methodName(api.sendVideo(payload)), "sendVideo")
        @Expect(methodName(api.sendAnimation(payload)), "sendAnimation")
        @Expect(methodName(api.sendVoice(payload)), "sendVoice")
        @Expect(methodName(api.sendVideoNote(payload)), "sendVideoNote")
        @Expect(methodName(api.sendMediaGroup(payload)), "sendMediaGroup")
        @Expect(methodName(api.sendLocation(payload)), "sendLocation")
    }

    @TestCase
    public func apiWrapperSkeletonCountIsExplicit(): Unit {
        @Expect(apiWrapperGenerationSkeletonCount(), 22)
    }
}
