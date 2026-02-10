import Foundation
@preconcurrency import TDLibKit

/// JSON 可序列化的字典类型（解决 Sendable 问题）
typealias JSONDict = [String: any Sendable]

/// Telegram 客户端封装
/// 封装 TDLibKit，提供简洁的 async/await API
public final class TelegramClient: @unchecked Sendable {

    // MARK: - Properties

    private let config: TelegramConfig
    private var manager: TDLibClientManager?
    private var client: TDLibApi?
    private var isAuthorized = false

    /// 认证状态变化回调
    public var onAuthStateChanged: (@Sendable (TelegramAuthState) -> Void)?

    /// 当前认证状态
    public private(set) var authState: TelegramAuthState = .unknown

    // MARK: - Initialization

    public init(config: TelegramConfig) {
        self.config = config
    }

    // MARK: - Lifecycle

    /// 初始化 TDLib 客户端
    public func initialize() {
        let manager = TDLibClientManager()
        self.manager = manager

        let client = manager.createClient { [weak self] data, client in
            guard let self = self else { return }
            do {
                let update = try client.decoder.decode(Update.self, from: data)
                self.handleUpdate(update, client: client)
            } catch {
                // Ignore decode errors for unhandled update types
            }
        }
        self.client = client
    }

    /// 关闭客户端
    public func close() {
        if let client = client {
            try? client.close { _ in }
        }
        manager?.closeClients()
        manager = nil
        client = nil
        isAuthorized = false
        authState = .closed
    }

    /// 是否已认证
    public var authorized: Bool { isAuthorized }

    // MARK: - Authentication

    /// 设置手机号
    public func setPhoneNumber(_ phoneNumber: String) async throws {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.setAuthenticationPhoneNumber(
            phoneNumber: phoneNumber,
            settings: nil
        )
    }

    /// 设置验证码
    public func setAuthenticationCode(_ code: String) async throws {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.checkAuthenticationCode(code: code)
    }

    /// 设置密码（两步验证）
    public func setPassword(_ password: String) async throws {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.checkAuthenticationPassword(password: password)
    }

    // MARK: - Chat Operations

    /// 获取聊天列表
    public func getChats(limit: Int = 50) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.getChats(chatList: .chatListMain, limit: limit)
        var chatInfos: [[String: any Sendable]] = []
        for chatId in result.chatIds {
            let chat = try await client.getChat(chatId: chatId)
            let info: [String: any Sendable] = [
                "id": chat.id,
                "title": chat.title,
                "type": chatTypeString(chat.type),
                "unread_count": chat.unreadCount
            ]
            chatInfos.append(info)
        }
        return toJSON(["chats": chatInfos, "total_count": chatInfos.count])
    }

    /// 获取单个聊天信息
    public func getChat(chatId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let chat = try await client.getChat(chatId: chatId)
        let dict: [String: any Sendable] = [
            "id": chat.id,
            "title": chat.title,
            "type": chatTypeString(chat.type),
            "unread_count": chat.unreadCount,
            "last_read_inbox_message_id": chat.lastReadInboxMessageId,
            "last_read_outbox_message_id": chat.lastReadOutboxMessageId
        ]
        return toJSON(dict)
    }

    /// 创建群组
    public func createGroup(title: String, userIds: [Int64]) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.createNewBasicGroupChat(
            messageAutoDeleteTime: 0,
            title: title,
            userIds: userIds
        )
        return toJSON(["chat_id": result.chatId, "success": true] as [String: any Sendable])
    }

    /// 创建频道/超级群
    public func createChannel(title: String, description: String, isChannel: Bool) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.createNewSupergroupChat(
            description: description,
            forImport: false,
            isChannel: isChannel,
            isForum: false,
            location: nil,
            messageAutoDeleteTime: 0,
            title: title
        )
        return toJSON(["chat_id": result.id, "title": result.title] as [String: any Sendable])
    }

    /// 离开聊天
    public func leaveChat(chatId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.leaveChat(chatId: chatId)
        return toJSON(["success": true, "chat_id": chatId] as [String: any Sendable])
    }

    /// 修改聊天标题
    public func editChatTitle(chatId: Int64, title: String) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.setChatTitle(chatId: chatId, title: title)
        return toJSON(["success": true, "chat_id": chatId, "title": title] as [String: any Sendable])
    }

    // MARK: - Message Operations

    /// 获取聊天历史
    public func getChatHistory(chatId: Int64, fromMessageId: Int64 = 0, limit: Int = 50) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.getChatHistory(
            chatId: chatId,
            fromMessageId: fromMessageId,
            limit: limit,
            offset: 0,
            onlyLocal: false
        )
        let messages = (result.messages ?? []).map { messageToDict($0) }
        return toJSON(["messages": messages, "total_count": result.totalCount] as [String: any Sendable])
    }

    /// 发送消息
    public func sendMessage(chatId: Int64, text: String) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let content = InputMessageContent.inputMessageText(InputMessageText(
            clearDraft: true,
            linkPreviewOptions: nil,
            text: FormattedText(entities: [], text: text)
        ))
        let result = try await client.sendMessage(
            chatId: chatId,
            inputMessageContent: content,
            options: nil,
            replyMarkup: nil,
            replyTo: nil,
            topicId: nil
        )
        return toJSON(messageToDict(result))
    }

    /// 回复消息
    public func replyToMessage(chatId: Int64, messageId: Int64, text: String) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let content = InputMessageContent.inputMessageText(InputMessageText(
            clearDraft: true,
            linkPreviewOptions: nil,
            text: FormattedText(entities: [], text: text)
        ))
        let result = try await client.sendMessage(
            chatId: chatId,
            inputMessageContent: content,
            options: nil,
            replyMarkup: nil,
            replyTo: .inputMessageReplyToMessage(InputMessageReplyToMessage(
                checklistTaskId: 0,
                messageId: messageId,
                quote: nil
            )),
            topicId: nil
        )
        return toJSON(messageToDict(result))
    }

    /// 编辑消息
    public func editMessage(chatId: Int64, messageId: Int64, text: String) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let content = InputMessageContent.inputMessageText(InputMessageText(
            clearDraft: true,
            linkPreviewOptions: nil,
            text: FormattedText(entities: [], text: text)
        ))
        let result = try await client.editMessageText(
            chatId: chatId,
            inputMessageContent: content,
            messageId: messageId,
            replyMarkup: nil
        )
        return toJSON(messageToDict(result))
    }

    /// 转发消息
    public func forwardMessages(chatId: Int64, fromChatId: Int64, messageIds: [Int64]) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.forwardMessages(
            chatId: chatId,
            fromChatId: fromChatId,
            messageIds: messageIds,
            options: nil,
            removeCaption: false,
            sendCopy: false,
            topicId: nil
        )
        let messages = (result.messages ?? []).map { messageToDict($0) }
        return toJSON(["messages": messages, "count": messages.count] as [String: any Sendable])
    }

    /// 删除消息
    public func deleteMessages(chatId: Int64, messageIds: [Int64]) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.deleteMessages(chatId: chatId, messageIds: messageIds, revoke: true)
        return toJSON(["success": true, "deleted_count": messageIds.count] as [String: any Sendable])
    }

    /// 获取单条消息
    public func getMessage(chatId: Int64, messageId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.getMessage(chatId: chatId, messageId: messageId)
        return toJSON(messageToDict(result))
    }

    // MARK: - Contact Operations

    /// 获取联系人列表
    public func getContacts() async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.getContacts()
        var users: [[String: any Sendable]] = []
        for userId in result.userIds {
            let user = try await client.getUser(userId: userId)
            users.append(userToDict(user))
        }
        return toJSON(["contacts": users, "total_count": users.count] as [String: any Sendable])
    }

    /// 搜索联系人
    public func searchContacts(query: String, limit: Int = 20) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.searchContacts(limit: limit, query: query)
        var users: [[String: any Sendable]] = []
        for userId in result.userIds {
            let user = try await client.getUser(userId: userId)
            users.append(userToDict(user))
        }
        return toJSON(["contacts": users, "total_count": users.count] as [String: any Sendable])
    }

    /// 添加联系人
    public func addContact(phoneNumber: String, firstName: String, lastName: String) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let contact = ImportedContact(
            firstName: firstName,
            lastName: lastName,
            note: nil,
            phoneNumber: phoneNumber
        )
        _ = try await client.addContact(contact: contact, sharePhoneNumber: false, userId: 0)
        return toJSON(["success": true, "phone": phoneNumber, "name": "\(firstName) \(lastName)"] as [String: any Sendable])
    }

    /// 删除联系人
    public func deleteContact(userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.removeContacts(userIds: [userId])
        return toJSON(["success": true, "user_id": userId] as [String: any Sendable])
    }

    // MARK: - User Operations

    /// 获取自己的信息
    public func getMe() async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.getMe()
        return toJSON(userToDict(result))
    }

    /// 获取用户信息
    public func getUser(userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.getUser(userId: userId)
        return toJSON(userToDict(result))
    }

    /// 屏蔽用户
    public func blockUser(userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.setMessageSenderBlockList(
            blockList: .blockListMain,
            senderId: .messageSenderUser(MessageSenderUser(userId: userId))
        )
        return toJSON(["success": true, "user_id": userId, "blocked": true] as [String: any Sendable])
    }

    /// 取消屏蔽用户
    public func unblockUser(userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.setMessageSenderBlockList(
            blockList: nil,
            senderId: .messageSenderUser(MessageSenderUser(userId: userId))
        )
        return toJSON(["success": true, "user_id": userId, "blocked": false] as [String: any Sendable])
    }

    // MARK: - Group Admin Operations

    /// 获取群成员列表
    public func getChatMembers(chatId: Int64, limit: Int = 200) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let chat = try await client.getChat(chatId: chatId)

        switch chat.type {
        case .chatTypeBasicGroup(let info):
            let group = try await client.getBasicGroupFullInfo(basicGroupId: info.basicGroupId)
            let members = group.members.map { memberToDict($0) }
            return toJSON(["members": members, "total_count": members.count] as [String: any Sendable])

        case .chatTypeSupergroup(let info):
            let result = try await client.getSupergroupMembers(
                filter: nil,
                limit: limit,
                offset: 0,
                supergroupId: info.supergroupId
            )
            let members = result.members.map { memberToDict($0) }
            return toJSON(["members": members, "total_count": result.totalCount] as [String: any Sendable])

        default:
            return toJSON(["members": [] as [String], "total_count": 0] as [String: any Sendable])
        }
    }

    /// 邀请用户加入群组
    public func addChatMembers(chatId: Int64, userIds: [Int64]) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        _ = try await client.addChatMembers(chatId: chatId, userIds: userIds)
        return toJSON(["success": true, "chat_id": chatId, "added_count": userIds.count] as [String: any Sendable])
    }

    /// 提升为管理员
    public func promoteAdmin(chatId: Int64, userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let status = ChatMemberStatus.chatMemberStatusAdministrator(ChatMemberStatusAdministrator(
            canBeEdited: true,
            customTitle: "",
            rights: ChatAdministratorRights(
                canChangeInfo: true,
                canDeleteMessages: true,
                canDeleteStories: false,
                canEditMessages: false,
                canEditStories: false,
                canInviteUsers: true,
                canManageChat: true,
                canManageDirectMessages: false,
                canManageTopics: false,
                canManageVideoChats: true,
                canPinMessages: true,
                canPostMessages: false,
                canPostStories: false,
                canPromoteMembers: false,
                canRestrictMembers: true,
                isAnonymous: false
            )
        ))
        _ = try await client.setChatMemberStatus(chatId: chatId, memberId: .messageSenderUser(MessageSenderUser(userId: userId)), status: status)
        return toJSON(["success": true, "chat_id": chatId, "user_id": userId, "role": "administrator"] as [String: any Sendable])
    }

    /// 取消管理员
    public func demoteAdmin(chatId: Int64, userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let status = ChatMemberStatus.chatMemberStatusMember(ChatMemberStatusMember(memberUntilDate: 0))
        _ = try await client.setChatMemberStatus(chatId: chatId, memberId: .messageSenderUser(MessageSenderUser(userId: userId)), status: status)
        return toJSON(["success": true, "chat_id": chatId, "user_id": userId, "role": "member"] as [String: any Sendable])
    }

    /// 封禁用户
    public func banUser(chatId: Int64, userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let status = ChatMemberStatus.chatMemberStatusBanned(ChatMemberStatusBanned(bannedUntilDate: 0))
        _ = try await client.setChatMemberStatus(chatId: chatId, memberId: .messageSenderUser(MessageSenderUser(userId: userId)), status: status)
        return toJSON(["success": true, "chat_id": chatId, "user_id": userId, "banned": true] as [String: any Sendable])
    }

    /// 解封用户
    public func unbanUser(chatId: Int64, userId: Int64) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let status = ChatMemberStatus.chatMemberStatusLeft
        _ = try await client.setChatMemberStatus(chatId: chatId, memberId: .messageSenderUser(MessageSenderUser(userId: userId)), status: status)
        return toJSON(["success": true, "chat_id": chatId, "user_id": userId, "banned": false] as [String: any Sendable])
    }

    // MARK: - Search Operations

    /// 搜索聊天中的消息
    public func searchMessages(chatId: Int64, query: String, limit: Int = 20) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.searchChatMessages(
            chatId: chatId,
            filter: nil,
            fromMessageId: 0,
            limit: limit,
            offset: 0,
            query: query,
            senderId: nil,
            topicId: nil
        )
        let messages = result.messages.map { messageToDict($0) }
        return toJSON(["messages": messages, "total_count": result.totalCount] as [String: any Sendable])
    }

    /// 搜索公共聊天
    public func searchPublicChats(query: String) async throws -> String {
        guard let client = client else { throw TelegramError.clientNotInitialized }
        let result = try await client.searchPublicChats(query: query)
        var chats: [[String: any Sendable]] = []
        for chatId in result.chatIds {
            let chat = try await client.getChat(chatId: chatId)
            let info: [String: any Sendable] = [
                "id": chat.id,
                "title": chat.title,
                "type": chatTypeString(chat.type)
            ]
            chats.append(info)
        }
        return toJSON(["chats": chats, "total_count": chats.count] as [String: any Sendable])
    }

    // MARK: - Private Helpers

    private func handleUpdate(_ update: Update, client: TDLibApi) {
        switch update {
        case .updateAuthorizationState(let state):
            handleAuthorizationState(state.authorizationState, client: client)
        default:
            break
        }
    }

    private func handleAuthorizationState(_ state: AuthorizationState, client: TDLibApi) {
        switch state {
        case .authorizationStateWaitTdlibParameters:
            authState = .waitingForTdlibParameters
            Task {
                try? await client.setTdlibParameters(
                    apiHash: config.apiHash,
                    apiId: config.apiId,
                    applicationVersion: config.applicationVersion,
                    databaseDirectory: config.databaseDirectory,
                    databaseEncryptionKey: Data(),
                    deviceModel: config.deviceModel,
                    filesDirectory: config.filesDirectory,
                    systemLanguageCode: config.systemLanguageCode,
                    systemVersion: "",
                    useChatInfoDatabase: config.useChatInfoDatabase,
                    useFileDatabase: config.useFileDatabase,
                    useMessageDatabase: config.useMessageDatabase,
                    useSecretChats: false,
                    useTestDc: false
                )
            }

        case .authorizationStateWaitPhoneNumber:
            authState = .waitingForPhoneNumber
            onAuthStateChanged?(.waitingForPhoneNumber)

        case .authorizationStateWaitCode:
            authState = .waitingForCode
            onAuthStateChanged?(.waitingForCode)

        case .authorizationStateWaitPassword:
            authState = .waitingForPassword
            onAuthStateChanged?(.waitingForPassword)

        case .authorizationStateReady:
            authState = .ready
            isAuthorized = true
            onAuthStateChanged?(.ready)

        case .authorizationStateClosed:
            authState = .closed
            isAuthorized = false
            onAuthStateChanged?(.closed)

        default:
            break
        }
    }

    private func chatTypeString(_ type: ChatType) -> String {
        switch type {
        case .chatTypePrivate: return "private"
        case .chatTypeBasicGroup: return "basic_group"
        case .chatTypeSupergroup(let info): return info.isChannel ? "channel" : "supergroup"
        case .chatTypeSecret: return "secret"
        }
    }

    private func messageToDict(_ message: Message) -> [String: any Sendable] {
        var dict: [String: any Sendable] = [
            "id": message.id,
            "chat_id": message.chatId,
            "date": message.date,
            "is_outgoing": message.isOutgoing
        ]

        switch message.senderId {
        case .messageSenderUser(let user):
            dict["sender_user_id"] = user.userId
        case .messageSenderChat(let chat):
            dict["sender_chat_id"] = chat.chatId
        }

        switch message.content {
        case .messageText(let text):
            dict["content_type"] = "text"
            dict["text"] = text.text.text
        case .messagePhoto(let photo):
            dict["content_type"] = "photo"
            dict["caption"] = photo.caption.text
        case .messageVideo(let video):
            dict["content_type"] = "video"
            dict["caption"] = video.caption.text
        case .messageDocument(let doc):
            dict["content_type"] = "document"
            dict["caption"] = doc.caption.text
            dict["file_name"] = doc.document.fileName
        case .messageSticker(let sticker):
            dict["content_type"] = "sticker"
            dict["emoji"] = sticker.sticker.emoji
        case .messageVoiceNote:
            dict["content_type"] = "voice_note"
        case .messageVideoNote:
            dict["content_type"] = "video_note"
        case .messageAnimation(let anim):
            dict["content_type"] = "animation"
            dict["caption"] = anim.caption.text
        default:
            dict["content_type"] = "other"
        }

        return dict
    }

    private func userToDict(_ user: User) -> [String: any Sendable] {
        var dict: [String: any Sendable] = [
            "id": user.id,
            "first_name": user.firstName,
            "last_name": user.lastName,
            "is_premium": user.isPremium
        ]
        if let username = user.usernames?.activeUsernames.first {
            dict["username"] = username
        }
        if !user.phoneNumber.isEmpty {
            dict["phone_number"] = user.phoneNumber
        }
        switch user.type {
        case .userTypeBot:
            dict["is_bot"] = true
        default:
            dict["is_bot"] = false
        }
        return dict
    }

    private func memberToDict(_ member: ChatMember) -> [String: any Sendable] {
        var dict: [String: any Sendable] = [:]

        switch member.memberId {
        case .messageSenderUser(let user):
            dict["user_id"] = user.userId
        case .messageSenderChat(let chat):
            dict["chat_id"] = chat.chatId
        }

        switch member.status {
        case .chatMemberStatusCreator:
            dict["role"] = "creator"
        case .chatMemberStatusAdministrator:
            dict["role"] = "administrator"
        case .chatMemberStatusMember:
            dict["role"] = "member"
        case .chatMemberStatusRestricted:
            dict["role"] = "restricted"
        case .chatMemberStatusBanned:
            dict["role"] = "banned"
        case .chatMemberStatusLeft:
            dict["role"] = "left"
        }

        dict["joined_date"] = member.joinedChatDate
        return dict
    }

    /// 将字典转为 JSON 字符串
    private func toJSON(_ dict: [String: any Sendable]) -> String {
        // 将 [String: any Sendable] 转为 JSONSerialization 兼容的类型
        let jsonCompatible = dict.mapValues { value -> Any in
            if let arr = value as? [[String: any Sendable]] {
                return arr.map { $0.mapValues { $0 as Any } }
            }
            return value as Any
        }
        guard let data = try? JSONSerialization.data(withJSONObject: jsonCompatible, options: [.sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}
