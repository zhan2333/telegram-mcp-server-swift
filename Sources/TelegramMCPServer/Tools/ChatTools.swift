import Foundation
import MCP

/// 聊天相关工具 (6个)
public enum ChatTools {

    /// 获取所有聊天工具
    public static func all(client: TelegramClient) -> [SimpleTool] {
        [
            getChatsTool(client: client),
            getChatTool(client: client),
            createGroupTool(client: client),
            createChannelTool(client: client),
            leaveChatTool(client: client),
            editChatTitleTool(client: client)
        ]
    }

    // MARK: - telegram_get_chats

    public static func getChatsTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_chats",
                description: "Get the list of chats. Returns chat ID, title, type, and unread count.",
                inputSchema: objectSchema(
                    properties: [
                        "limit": integerProperty(description: "Maximum number of chats to return (default 50, max 100)")
                    ],
                    required: []
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let limit = extractor.optionalInt("limit") ?? 50
                return try await client.getChats(limit: min(limit, 100))
            }
        )
    }

    // MARK: - telegram_get_chat

    public static func getChatTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_chat",
                description: "Get detailed information about a specific chat by its ID.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat")
                    ],
                    required: ["chat_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                return try await client.getChat(chatId: chatId)
            }
        )
    }

    // MARK: - telegram_create_group

    public static func createGroupTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_create_group",
                description: "Create a new basic group chat with specified users.",
                inputSchema: objectSchema(
                    properties: [
                        "title": stringProperty(description: "The title of the new group"),
                        "user_ids": arrayProperty(description: "Array of user IDs to add to the group", itemType: "integer")
                    ],
                    required: ["title", "user_ids"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let title = try extractor.requiredString("title")
                let userIds = try extractor.requiredInt64Array("user_ids")
                return try await client.createGroup(title: title, userIds: userIds)
            }
        )
    }

    // MARK: - telegram_create_channel

    public static func createChannelTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_create_channel",
                description: "Create a new channel or supergroup.",
                inputSchema: objectSchema(
                    properties: [
                        "title": stringProperty(description: "The title of the channel"),
                        "description": stringProperty(description: "Description of the channel"),
                        "is_channel": booleanProperty(description: "True for channel, false for supergroup (default true)")
                    ],
                    required: ["title"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let title = try extractor.requiredString("title")
                let description = extractor.optionalString("description") ?? ""
                let isChannel = extractor.optionalBool("is_channel") ?? true
                return try await client.createChannel(title: title, description: description, isChannel: isChannel)
            }
        )
    }

    // MARK: - telegram_leave_chat

    public static func leaveChatTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_leave_chat",
                description: "Leave a group or channel.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat to leave")
                    ],
                    required: ["chat_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                return try await client.leaveChat(chatId: chatId)
            }
        )
    }

    // MARK: - telegram_edit_chat_title

    public static func editChatTitleTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_edit_chat_title",
                description: "Edit the title of a chat.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat"),
                        "title": stringProperty(description: "The new title for the chat")
                    ],
                    required: ["chat_id", "title"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let title = try extractor.requiredString("title")
                return try await client.editChatTitle(chatId: chatId, title: title)
            }
        )
    }
}
