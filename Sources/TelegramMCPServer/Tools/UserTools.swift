import Foundation
import MCP

/// 用户相关工具 (4个)
public enum UserTools {

    /// 获取所有用户工具
    public static func all(client: TelegramClient) -> [SimpleTool] {
        [
            getMeTool(client: client),
            getUserTool(client: client),
            blockUserTool(client: client),
            unblockUserTool(client: client)
        ]
    }

    // MARK: - telegram_get_me

    public static func getMeTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_me",
                description: "Get information about the currently authenticated user.",
                inputSchema: objectSchema(
                    properties: [:],
                    required: []
                )
            ),
            handler: { _ in
                return try await client.getMe()
            }
        )
    }

    // MARK: - telegram_get_user

    public static func getUserTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_user",
                description: "Get information about a user by their ID.",
                inputSchema: objectSchema(
                    properties: [
                        "user_id": integerProperty(description: "The unique identifier of the user")
                    ],
                    required: ["user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let userId = try extractor.requiredInt64("user_id")
                return try await client.getUser(userId: userId)
            }
        )
    }

    // MARK: - telegram_block_user

    public static func blockUserTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_block_user",
                description: "Block a user. Blocked users cannot send you messages.",
                inputSchema: objectSchema(
                    properties: [
                        "user_id": integerProperty(description: "The ID of the user to block")
                    ],
                    required: ["user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let userId = try extractor.requiredInt64("user_id")
                return try await client.blockUser(userId: userId)
            }
        )
    }

    // MARK: - telegram_unblock_user

    public static func unblockUserTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_unblock_user",
                description: "Unblock a previously blocked user.",
                inputSchema: objectSchema(
                    properties: [
                        "user_id": integerProperty(description: "The ID of the user to unblock")
                    ],
                    required: ["user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let userId = try extractor.requiredInt64("user_id")
                return try await client.unblockUser(userId: userId)
            }
        )
    }
}
