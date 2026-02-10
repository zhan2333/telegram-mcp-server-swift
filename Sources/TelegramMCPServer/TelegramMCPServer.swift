import Foundation
import MCP

// MARK: - Tool Handler Type

/// 工具处理器类型
public typealias ToolHandler = @Sendable ([String: Value]) async throws -> String

// MARK: - Simple Tool

/// 简单工具结构体，封装 SDK Tool 和处理器
public struct SimpleTool: Sendable {
    public let sdkTool: Tool
    public let handler: ToolHandler

    public init(sdkTool: Tool, handler: @escaping ToolHandler) {
        self.sdkTool = sdkTool
        self.handler = handler
    }
}

// MARK: - Registered Tool

/// 已注册的工具
struct RegisteredTool: Sendable {
    let tool: Tool
    let handler: ToolHandler
}

// MARK: - MCP Server Protocol

/// MCP Server 协议（与 PeerBox 兼容）
public protocol MCPServerProtocol: AnyObject, Sendable {
    var name: String { get }
    var version: String { get }
    var isRunning: Bool { get }

    func start() async throws
    func stop() async
    func getTools() -> [Tool]
    func executeTool(name: String, arguments: [String: Value]) async throws -> [Tool.Content]
}

// MARK: - Telegram MCP Server

/// Telegram MCP Server 实现
public final class TelegramMCPServer: MCPServerProtocol, @unchecked Sendable {
    // MARK: - Properties

    public let name = "telegram"
    public let version = "1.0.0"
    public private(set) var isRunning = false

    private let telegramClient: TelegramClient
    private var registeredTools: [String: RegisteredTool] = [:]
    private let toolsQueue = DispatchQueue(label: "com.telegram.mcp.tools", attributes: .concurrent)
    private var toolsInitialized = false

    // MARK: - Initialization

    /// 使用配置初始化
    public init(config: TelegramConfig) {
        self.telegramClient = TelegramClient(config: config)
        initializeTools()
    }

    /// 便捷初始化
    public init(apiId: Int, apiHash: String) {
        let config = TelegramConfig(apiId: apiId, apiHash: apiHash)
        self.telegramClient = TelegramClient(config: config)
        initializeTools()
    }

    private func initializeTools() {
        toolsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, !self.toolsInitialized else { return }
            self.registerAllToolsInternal()
            self.toolsInitialized = true
        }
    }

    // MARK: - Client Access

    /// 获取底层 Telegram 客户端（用于认证等操作）
    public var client: TelegramClient { telegramClient }

    // MARK: - MCPServerProtocol Implementation

    public func start() async throws {
        telegramClient.initialize()
        isRunning = true
    }

    public func stop() async {
        telegramClient.close()
        isRunning = false
    }

    public func getTools() -> [Tool] {
        toolsQueue.sync {
            Array(registeredTools.values.map { $0.tool })
        }
    }

    public func executeTool(name: String, arguments: [String: Value]) async throws -> [Tool.Content] {
        let handler: ToolHandler? = toolsQueue.sync {
            registeredTools[name]?.handler
        }

        guard let handler = handler else {
            throw TelegramError.toolNotFound(name)
        }

        let result = try await handler(arguments)
        return [.text(result)]
    }

    // MARK: - Tool Registration

    private func registerAllToolsInternal() {
        // 聊天工具
        for tool in ChatTools.all(client: telegramClient) {
            registeredTools[tool.sdkTool.name] = RegisteredTool(
                tool: tool.sdkTool,
                handler: tool.handler
            )
        }

        // 消息工具
        for tool in MessageTools.all(client: telegramClient) {
            registeredTools[tool.sdkTool.name] = RegisteredTool(
                tool: tool.sdkTool,
                handler: tool.handler
            )
        }

        // 联系人工具
        for tool in ContactTools.all(client: telegramClient) {
            registeredTools[tool.sdkTool.name] = RegisteredTool(
                tool: tool.sdkTool,
                handler: tool.handler
            )
        }

        // 用户工具
        for tool in UserTools.all(client: telegramClient) {
            registeredTools[tool.sdkTool.name] = RegisteredTool(
                tool: tool.sdkTool,
                handler: tool.handler
            )
        }

        // 群组管理工具
        for tool in GroupTools.all(client: telegramClient) {
            registeredTools[tool.sdkTool.name] = RegisteredTool(
                tool: tool.sdkTool,
                handler: tool.handler
            )
        }

        // 搜索工具
        for tool in SearchTools.all(client: telegramClient) {
            registeredTools[tool.sdkTool.name] = RegisteredTool(
                tool: tool.sdkTool,
                handler: tool.handler
            )
        }
    }

    /// 手动注册自定义工具
    public func registerCustomTool(_ tool: SimpleTool) {
        toolsQueue.async(flags: .barrier) { [weak self] in
            self?.registeredTools[tool.sdkTool.name] = RegisteredTool(
                tool: tool.sdkTool,
                handler: tool.handler
            )
        }
    }

    /// 获取已注册的工具名称列表
    public func getToolNames() -> [String] {
        toolsQueue.sync {
            Array(registeredTools.keys).sorted()
        }
    }
}

// MARK: - Tool Definition Helpers

/// 创建 JSON Schema 对象类型
public func objectSchema(
    properties: [String: Value],
    required: [String] = []
) -> Value {
    .object([
        "type": .string("object"),
        "properties": .object(properties),
        "required": .array(required.map { .string($0) })
    ])
}

/// 创建字符串属性 Schema
public func stringProperty(description: String) -> Value {
    .object([
        "type": .string("string"),
        "description": .string(description)
    ])
}

/// 创建整数属性 Schema
public func integerProperty(description: String) -> Value {
    .object([
        "type": .string("integer"),
        "description": .string(description)
    ])
}

/// 创建布尔属性 Schema
public func booleanProperty(description: String) -> Value {
    .object([
        "type": .string("boolean"),
        "description": .string(description)
    ])
}

/// 创建对象属性 Schema
public func objectProperty(description: String) -> Value {
    .object([
        "type": .string("object"),
        "description": .string(description)
    ])
}

/// 创建数组属性 Schema
public func arrayProperty(description: String, itemType: String = "object") -> Value {
    .object([
        "type": .string("array"),
        "description": .string(description),
        "items": .object([
            "type": .string(itemType)
        ])
    ])
}
