import Foundation
import MCP

/// 群组管理相关工具 (6个)
public enum GroupTools {

    /// 获取所有群组管理工具
    public static func all(client: TelegramClient) -> [SimpleTool] {
        [
            getChatMembersTool(client: client),
            addChatMembersTool(client: client),
            promoteAdminTool(client: client),
            demoteAdminTool(client: client),
            banUserTool(client: client),
            unbanUserTool(client: client)
        ]
    }

    // MARK: - telegram_get_chat_members

    public static func getChatMembersTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_chat_members",
                description: "Get the list of members in a group or channel.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat"),
                        "limit": integerProperty(description: "Maximum number of members to return (default 200)")
                    ],
                    required: ["chat_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let limit = extractor.optionalInt("limit") ?? 200
                return try await client.getChatMembers(chatId: chatId, limit: limit)
            }
        )
    }

    // MARK: - telegram_add_chat_members

    public static func addChatMembersTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_add_chat_members",
                description: "Add users to a group or channel.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat"),
                        "user_ids": arrayProperty(description: "Array of user IDs to add", itemType: "integer")
                    ],
                    required: ["chat_id", "user_ids"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let userIds = try extractor.requiredInt64Array("user_ids")
                return try await client.addChatMembers(chatId: chatId, userIds: userIds)
            }
        )
    }

    // MARK: - telegram_promote_admin

    public static func promoteAdminTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_promote_admin",
                description: "Promote a user to administrator in a group or channel. Grants standard admin rights.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat"),
                        "user_id": integerProperty(description: "The ID of the user to promote")
                    ],
                    required: ["chat_id", "user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let userId = try extractor.requiredInt64("user_id")
                return try await client.promoteAdmin(chatId: chatId, userId: userId)
            }
        )
    }

    // MARK: - telegram_demote_admin

    public static func demoteAdminTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_demote_admin",
                description: "Demote an administrator back to a regular member.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat"),
                        "user_id": integerProperty(description: "The ID of the admin to demote")
                    ],
                    required: ["chat_id", "user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let userId = try extractor.requiredInt64("user_id")
                return try await client.demoteAdmin(chatId: chatId, userId: userId)
            }
        )
    }

    // MARK: - telegram_ban_user

    public static func banUserTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_ban_user",
                description: "Ban a user from a group or channel. The user will be removed and cannot rejoin.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat"),
                        "user_id": integerProperty(description: "The ID of the user to ban")
                    ],
                    required: ["chat_id", "user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let userId = try extractor.requiredInt64("user_id")
                return try await client.banUser(chatId: chatId, userId: userId)
            }
        )
    }

    // MARK: - telegram_unban_user

    public static func unbanUserTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_unban_user",
                description: "Unban a previously banned user from a group or channel.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The unique identifier of the chat"),
                        "user_id": integerProperty(description: "The ID of the user to unban")
                    ],
                    required: ["chat_id", "user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let userId = try extractor.requiredInt64("user_id")
                return try await client.unbanUser(chatId: chatId, userId: userId)
            }
        )
    }
}
