import Foundation

/// Telegram 认证状态
public enum TelegramAuthState: Sendable {
    case waitingForTdlibParameters
    case waitingForPhoneNumber
    case waitingForCode
    case waitingForPassword
    case ready
    case closed
    case unknown
}

/// 简化的聊天信息
public struct TelegramChatInfo: Sendable {
    public let id: Int64
    public let title: String
    public let type: String
    public let memberCount: Int?
    public let lastMessageDate: Date?

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title,
            "type": type
        ]
        if let count = memberCount {
            dict["member_count"] = count
        }
        if let date = lastMessageDate {
            dict["last_message_date"] = ISO8601DateFormatter().string(from: date)
        }
        return dict
    }
}

/// 简化的消息信息
public struct TelegramMessageInfo: Sendable {
    public let id: Int64
    public let chatId: Int64
    public let senderUserId: Int64?
    public let date: Int32
    public let content: String
    public let contentType: String

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "chat_id": chatId,
            "date": date,
            "content": content,
            "content_type": contentType
        ]
        if let senderId = senderUserId {
            dict["sender_user_id"] = senderId
        }
        return dict
    }
}

/// 简化的用户信息
public struct TelegramUserInfo: Sendable {
    public let id: Int64
    public let firstName: String
    public let lastName: String
    public let username: String?
    public let phoneNumber: String?
    public let isBot: Bool

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "first_name": firstName,
            "last_name": lastName,
            "is_bot": isBot
        ]
        if let username = username {
            dict["username"] = username
        }
        if let phone = phoneNumber {
            dict["phone_number"] = phone
        }
        return dict
    }
}
