import Foundation
import MCP

/// 消息相关工具 (7个)
public enum MessageTools {

    /// 获取所有消息工具
    public static func all(client: TelegramClient) -> [SimpleTool] {
        [
            getChatHistoryTool(client: client),
            getMessageTool(client: client),
            sendMessageTool(client: client),
            replyToMessageTool(client: client),
            editMessageTool(client: client),
            forwardMessagesTool(client: client),
            deleteMessagesTool(client: client)
        ]
    }

    // MARK: - telegram_get_chat_history

    public static func getChatHistoryTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_chat_history",
                description: "Get message history from a chat. Returns messages in reverse chronological order.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The chat to get messages from"),
                        "from_message_id": integerProperty(description: "Message ID to start from (0 for most recent)"),
                        "limit": integerProperty(description: "Maximum number of messages to return (default 50, max 100)")
                    ],
                    required: ["chat_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let fromMessageId = extractor.optionalInt64("from_message_id") ?? 0
                let limit = extractor.optionalInt("limit") ?? 50
                return try await client.getChatHistory(chatId: chatId, fromMessageId: fromMessageId, limit: min(limit, 100))
            }
        )
    }

    // MARK: - telegram_get_message

    public static func getMessageTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_message",
                description: "Get a single message by its ID from a chat.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The chat containing the message"),
                        "message_id": integerProperty(description: "The ID of the message to retrieve")
                    ],
                    required: ["chat_id", "message_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let messageId = try extractor.requiredInt64("message_id")
                return try await client.getMessage(chatId: chatId, messageId: messageId)
            }
        )
    }

    // MARK: - telegram_send_message

    public static func sendMessageTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_send_message",
                description: "Send a text message to a chat.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The chat to send the message to"),
                        "text": stringProperty(description: "The text content of the message")
                    ],
                    required: ["chat_id", "text"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let text = try extractor.requiredString("text")
                return try await client.sendMessage(chatId: chatId, text: text)
            }
        )
    }

    // MARK: - telegram_reply_to_message

    public static func replyToMessageTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_reply_to_message",
                description: "Reply to a specific message in a chat.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The chat containing the message"),
                        "message_id": integerProperty(description: "The ID of the message to reply to"),
                        "text": stringProperty(description: "The reply text")
                    ],
                    required: ["chat_id", "message_id", "text"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let messageId = try extractor.requiredInt64("message_id")
                let text = try extractor.requiredString("text")
                return try await client.replyToMessage(chatId: chatId, messageId: messageId, text: text)
            }
        )
    }

    // MARK: - telegram_edit_message

    public static func editMessageTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_edit_message",
                description: "Edit an existing text message.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The chat containing the message"),
                        "message_id": integerProperty(description: "The ID of the message to edit"),
                        "text": stringProperty(description: "The new text content")
                    ],
                    required: ["chat_id", "message_id", "text"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let messageId = try extractor.requiredInt64("message_id")
                let text = try extractor.requiredString("text")
                return try await client.editMessage(chatId: chatId, messageId: messageId, text: text)
            }
        )
    }

    // MARK: - telegram_forward_messages

    public static func forwardMessagesTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_forward_messages",
                description: "Forward messages from one chat to another.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The target chat to forward messages to"),
                        "from_chat_id": integerProperty(description: "The source chat containing the messages"),
                        "message_ids": arrayProperty(description: "Array of message IDs to forward", itemType: "integer")
                    ],
                    required: ["chat_id", "from_chat_id", "message_ids"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let fromChatId = try extractor.requiredInt64("from_chat_id")
                let messageIds = try extractor.requiredInt64Array("message_ids")
                return try await client.forwardMessages(chatId: chatId, fromChatId: fromChatId, messageIds: messageIds)
            }
        )
    }

    // MARK: - telegram_delete_messages

    public static func deleteMessagesTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_delete_messages",
                description: "Delete messages from a chat. Deletes for all participants when possible.",
                inputSchema: objectSchema(
                    properties: [
                        "chat_id": integerProperty(description: "The chat containing the messages"),
                        "message_ids": arrayProperty(description: "Array of message IDs to delete", itemType: "integer")
                    ],
                    required: ["chat_id", "message_ids"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let chatId = try extractor.requiredInt64("chat_id")
                let messageIds = try extractor.requiredInt64Array("message_ids")
                return try await client.deleteMessages(chatId: chatId, messageIds: messageIds)
            }
        )
    }
}
