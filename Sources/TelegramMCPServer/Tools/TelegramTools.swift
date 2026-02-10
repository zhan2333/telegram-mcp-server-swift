import Foundation
import MCP

/// Telegram 工具集合入口
///
/// 提供便捷方法获取所有 Telegram MCP 工具
public enum TelegramTools {

    /// 获取所有工具 (29个)
    public static func all(client: TelegramClient) -> [SimpleTool] {
        var tools: [SimpleTool] = []

        // 聊天工具 (6个)
        tools.append(contentsOf: ChatTools.all(client: client))

        // 消息工具 (7个)
        tools.append(contentsOf: MessageTools.all(client: client))

        // 联系人工具 (4个)
        tools.append(contentsOf: ContactTools.all(client: client))

        // 用户工具 (4个)
        tools.append(contentsOf: UserTools.all(client: client))

        // 群组管理工具 (6个)
        tools.append(contentsOf: GroupTools.all(client: client))

        // 搜索工具 (2个)
        tools.append(contentsOf: SearchTools.all(client: client))

        return tools
    }

    /// 获取工具数量统计
    public static var toolCounts: [String: Int] {
        [
            "chat": 6,
            "message": 7,
            "contact": 4,
            "user": 4,
            "group": 6,
            "search": 2,
            "total": 29
        ]
    }

    /// 获取所有工具名称
    public static var toolNames: [String] {
        [
            // 聊天
            "telegram_get_chats",
            "telegram_get_chat",
            "telegram_create_group",
            "telegram_create_channel",
            "telegram_leave_chat",
            "telegram_edit_chat_title",
            // 消息
            "telegram_get_chat_history",
            "telegram_get_message",
            "telegram_send_message",
            "telegram_reply_to_message",
            "telegram_edit_message",
            "telegram_forward_messages",
            "telegram_delete_messages",
            // 联系人
            "telegram_get_contacts",
            "telegram_search_contacts",
            "telegram_add_contact",
            "telegram_delete_contact",
            // 用户
            "telegram_get_me",
            "telegram_get_user",
            "telegram_block_user",
            "telegram_unblock_user",
            // 群组管理
            "telegram_get_chat_members",
            "telegram_add_chat_members",
            "telegram_promote_admin",
            "telegram_demote_admin",
            "telegram_ban_user",
            "telegram_unban_user",
            // 搜索
            "telegram_search_messages",
            "telegram_search_public_chats"
        ]
    }
}
