import Foundation
import MCP

/// 搜索相关工具 (2个)
public enum SearchTools {

    /// 获取所有搜索工具
    public static func all(client: TelegramClient) -> [SimpleTool] {
        [
            searchMessagesTool(client: client),
            searchPublicChatsTool(client: client)
        ]
    }

    // MARK: - telegram_search_messages

    public static func searchMessagesTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_search_messages",
                description: "Search for messages in a specific chat by text query.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The chat to search in"),
                        "query": stringProperty(description: "The search query text"),
                        "limit": integerProperty(description: "Maximum number of results to return (default 20)")
                    ],
                    required: ["chat_id", "query"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let query = try extractor.requiredString("query")
                let limit = extractor.optionalInt("limit") ?? 20
                return try await client.searchMessages(chatId: chatId, query: query, limit: limit)
            }
        )
    }

    // MARK: - telegram_search_public_chats

    public static func searchPublicChatsTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_search_public_chats",
                description: "Search for public chats (channels and supergroups) by username or title.",
                inputSchema: objectSchema(
                    properties: [
                        "query": stringProperty(description: "The search query (username or title)")
                    ],
                    required: ["query"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let query = try extractor.requiredString("query")
                return try await client.searchPublicChats(query: query)
            }
        )
    }
}
