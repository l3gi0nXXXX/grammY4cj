package grammy4cj.convenience

import std.collection.ArrayList

public let TELEGRAM_BOT_API_VERSION: String = "9.6"
public let GRAMMY_TYPES_VERSION: String = "v3.26.0"
public let GRAMMY_UPSTREAM_BASELINE_HEAD: String = "c865dd3a4d26911b01c83695e3845c7245870a5d"
public let GRAMMY_UPSTREAM_BASELINE_TAG: String = "v1.42.0-5-gc865dd3"

public class APIConstants {
    public let defaultUpdateTypeCount: Int64
    public let maxInlineKeyboardColumns: Int64
    public let DEFAULT_UPDATE_TYPES: Array<String>
    public let ALL_UPDATE_TYPES: Array<String>
    public let ALL_CHAT_PERMISSIONS: TelegramObject

    public init(defaultUpdateTypeCount: Int64, maxInlineKeyboardColumns: Int64) {
        this.defaultUpdateTypeCount = defaultUpdateTypeCount
        this.maxInlineKeyboardColumns = maxInlineKeyboardColumns
        this.DEFAULT_UPDATE_TYPES = defaultUpdateTypes()
        this.ALL_UPDATE_TYPES = allUpdateTypes()
        this.ALL_CHAT_PERMISSIONS = allChatPermissions()
    }

    public func toJSON(): String {
        let object = TelegramObject()
        object.addArray("DEFAULT_UPDATE_TYPES", stringArrayValue(this.DEFAULT_UPDATE_TYPES))
        object.addArray("ALL_UPDATE_TYPES", stringArrayValue(this.ALL_UPDATE_TYPES))
        object.addObject("ALL_CHAT_PERMISSIONS", this.ALL_CHAT_PERMISSIONS)
        object.toJSON()
    }

    public func isFrozen(): Bool {
        true
    }
}

public let API_CONSTANTS: APIConstants = APIConstants(23, 8)

public func defaultUpdateTypes(): Array<String> {
    [
        "message",
        "edited_message",
        "channel_post",
        "edited_channel_post",
        "business_connection",
        "business_message",
        "edited_business_message",
        "deleted_business_messages",
        "inline_query",
        "chosen_inline_result",
        "callback_query",
        "shipping_query",
        "pre_checkout_query",
        "purchased_paid_media",
        "poll",
        "poll_answer",
        "my_chat_member",
        "managed_bot",
        "chat_join_request",
        "chat_boost",
        "removed_chat_boost"
    ]
}

public func allUpdateTypes(): Array<String> {
    [
        "message",
        "edited_message",
        "channel_post",
        "edited_channel_post",
        "business_connection",
        "business_message",
        "edited_business_message",
        "deleted_business_messages",
        "inline_query",
        "chosen_inline_result",
        "callback_query",
        "shipping_query",
        "pre_checkout_query",
        "purchased_paid_media",
        "poll",
        "poll_answer",
        "my_chat_member",
        "managed_bot",
        "chat_join_request",
        "chat_boost",
        "removed_chat_boost",
        "chat_member",
        "message_reaction",
        "message_reaction_count"
    ]
}

public func allChatPermissionKeys(): Array<String> {
    [
        "can_send_messages",
        "can_send_audios",
        "can_send_documents",
        "can_send_photos",
        "can_send_videos",
        "can_send_video_notes",
        "can_send_voice_notes",
        "can_send_polls",
        "can_send_other_messages",
        "can_add_web_page_previews",
        "can_change_info",
        "can_invite_users",
        "can_edit_tag",
        "can_pin_messages",
        "can_manage_topics"
    ]
}

public func allChatPermissions(): TelegramObject {
    let object = TelegramObject()
    for (permission in allChatPermissionKeys()) {
        object.addBool(permission, true)
    }
    object
}

public class TelegramField {
    public let key: String
    public let value: TelegramValue

    public init(key: String, value: TelegramValue) {
        this.key = key
        this.value = value
    }
}

public class TelegramValue {
    public let kind: String
    public let literal: String
    public var fields: ArrayList<TelegramField> = ArrayList<TelegramField>()
    public var items: ArrayList<TelegramValue> = ArrayList<TelegramValue>()

    public init(kind: String, literal: String) {
        this.kind = kind
        this.literal = literal
    }

    public func toJSON(): String {
        if (this.kind == "string") {
            return "\"" + escapeConvenienceJson(this.literal) + "\""
        }
        if (this.kind == "raw") {
            return this.literal
        }
        if (this.kind == "array") {
            var body: String = "["
            var first = true
            for (item in this.items) {
                if (!first) {
                    body += ","
                }
                body += item.toJSON()
                first = false
            }
            body += "]"
            return body
        }
        var object: String = "{"
        var firstField = true
        for (field in this.fields) {
            if (!firstField) {
                object += ","
            }
            object += "\"" + escapeConvenienceJson(field.key) + "\":" + field.value.toJSON()
            firstField = false
        }
        object += "}"
        object
    }

    public func copy(): TelegramValue {
        let copied = TelegramValue(this.kind, this.literal)
        for (field in this.fields) {
            copied.fields.add(TelegramField(field.key, field.value.copy()))
        }
        for (item in this.items) {
            copied.items.add(item.copy())
        }
        copied
    }
}

public class TelegramObject {
    public var fields: ArrayList<TelegramField> = ArrayList<TelegramField>()

    public init() {}

    public func addString(key: String, value: String): TelegramObject {
        this.putValue(key, stringValue(value))
        this
    }

    public func addRaw(key: String, value: String): TelegramObject {
        this.putValue(key, rawValue(value))
        this
    }

    public func addBool(key: String, value: Bool): TelegramObject {
        this.putValue(key, rawValue(if (value) { "true" } else { "false" }))
        this
    }

    public func addInt(key: String, value: Int64): TelegramObject {
        this.putValue(key, rawValue(value.toString()))
        this
    }

    public func addFloat(key: String, value: Float64): TelegramObject {
        this.putValue(key, rawValue(value.toString()))
        this
    }

    public func addObject(key: String, value: TelegramObject): TelegramObject {
        this.putValue(key, value.toValue())
        this
    }

    public func addArray(key: String, value: TelegramValue): TelegramObject {
        this.putValue(key, value)
        this
    }

    public func addValue(key: String, value: TelegramValue): TelegramObject {
        this.putValue(key, value)
        this
    }

    public func addNonEmptyString(key: String, value: String): TelegramObject {
        if (!value.isEmpty()) {
            this.addString(key, value)
        }
        this
    }

    public func addAll(other: TelegramObject): TelegramObject {
        for (field in other.fields) {
            this.putValue(field.key, field.value.copy())
        }
        this
    }

    public func toValue(): TelegramValue {
        let value = TelegramValue("object", "")
        for (field in this.fields) {
            value.fields.add(TelegramField(field.key, field.value.copy()))
        }
        value
    }

    public func toJSON(): String {
        this.toValue().toJSON()
    }

    public func copy(): TelegramObject {
        let object = TelegramObject()
        object.addAll(this)
        object
    }

    public func hasField(key: String): Bool {
        for (field in this.fields) {
            if (field.key == key) {
                return true
            }
        }
        false
    }

    public func fieldKind(key: String): String {
        for (field in this.fields) {
            if (field.key == key) {
                return field.value.kind
            }
        }
        ""
    }

    public func stringField(key: String): String {
        for (field in this.fields) {
            if (field.key == key && field.value.kind == "string") {
                return field.value.literal
            }
        }
        ""
    }

    public func rawField(key: String): String {
        for (field in this.fields) {
            if (field.key == key && field.value.kind == "raw") {
                return field.value.literal
            }
        }
        ""
    }

    public func matchingFieldCount(keys: Array<String>): Int64 {
        var count: Int64 = 0
        for (field in this.fields) {
            if (containsConvenienceString(keys, field.key)) {
                count += 1
            }
        }
        count
    }

    private func putValue(key: String, value: TelegramValue): Unit {
        let next = ArrayList<TelegramField>()
        var replaced = false
        for (field in this.fields) {
            if (field.key == key) {
                if (!replaced) {
                    next.add(TelegramField(key, value.copy()))
                    replaced = true
                }
            } else {
                next.add(TelegramField(field.key, field.value.copy()))
            }
        }
        if (!replaced) {
            next.add(TelegramField(key, value.copy()))
        }
        this.fields = next
    }
}

public class TelegramStringLiteralRule {
    public let key: String
    public let literal: String

    public init(key: String, literal: String) {
        this.key = key
        this.literal = literal
    }
}

public class TelegramObjectSchemaResult {
    public let valid: Bool
    public let message: String

    public init(valid: Bool, message: String) {
        this.valid = valid
        this.message = message
    }
}

public class TelegramObjectSchema {
    public let name: String
    private let requiredFields: ArrayList<String> = ArrayList<String>()
    private let allowedFields: ArrayList<String> = ArrayList<String>()
    private let stringLiteralRules: ArrayList<TelegramStringLiteralRule> = ArrayList<TelegramStringLiteralRule>()
    private let exclusiveGroups: ArrayList<Array<String>> = ArrayList<Array<String>>()

    public init(name: String) {
        this.name = name
    }

    public func requireField(key: String): TelegramObjectSchema {
        this.addUnique(this.requiredFields, key)
        this.allowField(key)
    }

    public func requireString(key: String, literal: String): TelegramObjectSchema {
        this.requireField(key)
        this.stringLiteralRules.add(TelegramStringLiteralRule(key, literal))
        this
    }

    public func allowField(key: String): TelegramObjectSchema {
        this.addUnique(this.allowedFields, key)
        this
    }

    public func allowFields(keys: Array<String>): TelegramObjectSchema {
        for (key in keys) {
            this.allowField(key)
        }
        this
    }

    public func exclusiveGroup(keys: Array<String>): TelegramObjectSchema {
        this.exclusiveGroups.add(keys)
        for (key in keys) {
            this.allowField(key)
        }
        this
    }

    public func validate(object: TelegramObject): TelegramObjectSchemaResult {
        for (key in this.requiredFields) {
            if (!object.hasField(key)) {
                return TelegramObjectSchemaResult(false, this.name + " missing required field `" + key + "`")
            }
        }
        for (field in object.fields) {
            if (this.allowedFields.size > 0 && !this.containsAllowed(field.key)) {
                return TelegramObjectSchemaResult(false, this.name + " contains unsupported field `" + field.key + "`")
            }
        }
        for (rule in this.stringLiteralRules) {
            if (object.fieldKind(rule.key) != "string" || object.stringField(rule.key) != rule.literal) {
                return TelegramObjectSchemaResult(false, this.name + " requires `" + rule.key + "` to be `" + rule.literal + "`")
            }
        }
        for (group in this.exclusiveGroups) {
            if (object.matchingFieldCount(group) > 1) {
                return TelegramObjectSchemaResult(false, this.name + " contains mutually exclusive fields")
            }
        }
        TelegramObjectSchemaResult(true, "")
    }

    public func isValid(object: TelegramObject): Bool {
        this.validate(object).valid
    }

    private func addUnique(target: ArrayList<String>, key: String): Unit {
        for (value in target) {
            if (value == key) {
                return
            }
        }
        target.add(key)
    }

    private func containsAllowed(key: String): Bool {
        for (value in this.allowedFields) {
            if (value == key) {
                return true
            }
        }
        false
    }
}

public func stringValue(value: String): TelegramValue {
    TelegramValue("string", value)
}

public func rawValue(value: String): TelegramValue {
    TelegramValue("raw", value)
}

public func objectValue(object: TelegramObject): TelegramValue {
    object.toValue()
}

public func arrayValue(): TelegramValue {
    TelegramValue("array", "")
}

public func stringArrayValue(values: Array<String>): TelegramValue {
    let array = arrayValue()
    for (value in values) {
        array.items.add(stringValue(value))
    }
    array
}

public func objectArrayValue(values: ArrayList<TelegramObject>): TelegramValue {
    let array = arrayValue()
    for (value in values) {
        array.items.add(value.toValue())
    }
    array
}

public func escapeConvenienceJson(value: String): String {
    value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r")
}

private func containsConvenienceString(values: Array<String>, target: String): Bool {
    for (value in values) {
        if (value == target) {
            return true
        }
    }
    false
}
