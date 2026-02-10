import Foundation
import MCP

/// 联系人相关工具 (4个)
public enum ContactTools {

    /// 获取所有联系人工具
    public static func all(client: TelegramClient) -> [SimpleTool] {
        [
            getContactsTool(client: client),
            searchContactsTool(client: client),
            addContactTool(client: client),
            deleteContactTool(client: client)
        ]
    }

    // MARK: - telegram_get_contacts

    public static func getContactsTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_get_contacts",
                description: "Get the list of all contacts. Returns user details for each contact.",
                inputSchema: objectSchema(
                    properties: [:],
                    required: []
                )
            ),
            handler: { _ in
                return try await client.getContacts()
            }
        )
    }

    // MARK: - telegram_search_contacts

    public static func searchContactsTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_search_contacts",
                description: "Search for contacts by name or username.",
                inputSchema: objectSchema(
                    properties: [
                        "query": stringProperty(description: "The search query string"),
                        "limit": integerProperty(description: "Maximum number of results to return (default 20)")
                    ],
                    required: ["query"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let query = try extractor.requiredString("query")
                let limit = extractor.optionalInt("limit") ?? 20
                return try await client.searchContacts(query: query, limit: limit)
            }
        )
    }

    // MARK: - telegram_add_contact

    public static func addContactTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_add_contact",
                description: "Add a new contact with phone number and name.",
                inputSchema: objectSchema(
                    properties: [
                        "phone_number": stringProperty(description: "Phone number of the contact (international format)"),
                        "first_name": stringProperty(description: "First name of the contact"),
                        "last_name": stringProperty(description: "Last name of the contact (optional)")
                    ],
                    required: ["phone_number", "first_name"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let phone = try extractor.requiredString("phone_number")
                let firstName = try extractor.requiredString("first_name")
                let lastName = extractor.optionalString("last_name") ?? ""
                return try await client.addContact(phoneNumber: phone, firstName: firstName, lastName: lastName)
            }
        )
    }

    // MARK: - telegram_delete_contact

    public static func deleteContactTool(client: TelegramClient) -> SimpleTool {
        SimpleTool(
            sdkTool: Tool(
                name: "telegram_delete_contact",
                description: "Remove a user from the contact list.",
                inputSchema: objectSchema(
                    properties: [
                        "user_id": integerProperty(description: "The ID of the user to remove from contacts")
                    ],
                    required: ["user_id"]
                )
            ),
            handler: { arguments in
                let extractor = ArgumentExtractor(arguments)
                let userId = try extractor.requiredInt64("user_id")
                return try await client.deleteContact(userId: userId)
            }
        )
    }
}
