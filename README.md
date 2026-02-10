# TelegramMCPServer

Telegram MCP Server Swift SDK - 基于 [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) 和 [TDLibKit](https://github.com/Swiftgram/TDLibKit) 的 Telegram API 集成。

参考 [telegram-mcp](https://github.com/chigwell/telegram-mcp) (Python) 用 Swift 一比一实现。

## 功能

实现了 29 个 Telegram MCP 工具，覆盖聊天、消息、联系人、用户、群组管理和搜索功能。

### 工具列表

| 类别 | 工具 |
|------|------|
| **聊天 (6)** | `telegram_get_chats`, `telegram_get_chat`, `telegram_create_group`, `telegram_create_channel`, `telegram_leave_chat`, `telegram_edit_chat_title` |
| **消息 (7)** | `telegram_get_chat_history`, `telegram_get_message`, `telegram_send_message`, `telegram_reply_to_message`, `telegram_edit_message`, `telegram_forward_messages`, `telegram_delete_messages` |
| **联系人 (4)** | `telegram_get_contacts`, `telegram_search_contacts`, `telegram_add_contact`, `telegram_delete_contact` |
| **用户 (4)** | `telegram_get_me`, `telegram_get_user`, `telegram_block_user`, `telegram_unblock_user` |
| **群组管理 (6)** | `telegram_get_chat_members`, `telegram_add_chat_members`, `telegram_promote_admin`, `telegram_demote_admin`, `telegram_ban_user`, `telegram_unban_user` |
| **搜索 (2)** | `telegram_search_messages`, `telegram_search_public_chats` |

## 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/zhan2333/telegram-mcp-server-swift.git", from: "1.0.0"),
]
```

然后在 target 中添加：

```swift
.target(
    name: "YourTarget",
    dependencies: ["TelegramMCPServer"]
),
```

## 使用

### 基础用法

```swift
import TelegramMCPServer
import MCP

// 1. 创建 Server
let server = TelegramMCPServer(apiId: YOUR_API_ID, apiHash: "YOUR_API_HASH")

// 2. 启动（初始化 TDLib 客户端）
try await server.start()

// 3. 处理认证（首次需要）
server.client.onAuthStateChanged = { state in
    switch state {
    case .waitingForPhoneNumber:
        // 提示用户输入手机号
        Task { try await server.client.setPhoneNumber("+1234567890") }
    case .waitingForCode:
        // 提示用户输入验证码
        Task { try await server.client.setAuthenticationCode("12345") }
    case .waitingForPassword:
        // 提示用户输入两步验证密码
        Task { try await server.client.setPassword("password") }
    case .ready:
        print("Authenticated!")
    default:
        break
    }
}

// 4. 获取工具列表
let tools = server.getTools()
print("Available tools: \(tools.count)")

// 5. 执行工具
let result = try await server.executeTool(
    name: "telegram_get_chats",
    arguments: ["limit": .int(20)]
)
```

### 集成到 MCP Manager (PeerBox)

```swift
// 注册到 MCPManager
MCPManager.shared.registerServer(server)
```

## 配置

### API 凭证

从 [my.telegram.org](https://my.telegram.org/apps) 获取 `api_id` 和 `api_hash`。

```swift
// 方式 1: 直接传入
let server = TelegramMCPServer(apiId: 12345, apiHash: "your_api_hash")

// 方式 2: 使用配置对象
let config = TelegramConfig(
    apiId: 12345,
    apiHash: "your_api_hash",
    databaseDirectory: "custom_path",    // 可选
    systemLanguageCode: "zh",            // 可选
    deviceModel: "iPhone",               // 可选
    applicationVersion: "1.0.0"          // 可选
)
let server = TelegramMCPServer(config: config)

// 方式 3: 从环境变量
let config = try TelegramConfig.fromEnvironment()
// 需要设置 TELEGRAM_API_ID 和 TELEGRAM_API_HASH
```

### 认证流程

TDLib 认证是有状态的，首次登录需要：

1. 输入手机号 (`setPhoneNumber`)
2. 输入短信验证码 (`setAuthenticationCode`)
3. 输入两步验证密码 (`setPassword`，如已启用)

认证成功后 TDLib 会自动持久化 Session，后续启动无需重复认证。

## 架构

```
Sources/TelegramMCPServer/
├── TelegramMCPServer.swift      # 主服务器 (MCPServerProtocol)
├── TelegramClient.swift         # TDLib 客户端封装
├── TelegramConfig.swift         # 配置
├── Models/
│   ├── TelegramError.swift      # 错误类型
│   └── TelegramModels.swift     # 数据模型
├── Tools/                       # MCP 工具定义
│   ├── TelegramTools.swift      # 工具注册表
│   ├── ChatTools.swift          # 聊天工具
│   ├── MessageTools.swift       # 消息工具
│   ├── ContactTools.swift       # 联系人工具
│   ├── UserTools.swift          # 用户工具
│   ├── GroupTools.swift         # 群组管理工具
│   └── SearchTools.swift        # 搜索工具
└── Utils/
    └── ValueExtensions.swift    # MCP Value 扩展
```

## 与 NotionMCPServer 对比

| 维度 | NotionMCPServer | TelegramMCPServer |
|------|----------------|-------------------|
| 底层通信 | HTTP REST API | TDLib (C++ 本地库) |
| 认证方式 | API Key (一次配置) | Session (首次需验证码) |
| 状态模型 | 无状态 | 有状态 (本地数据库) |
| 数据获取 | 主动请求 | 请求 + 被动推送 (updates) |
| 依赖库 | 无 (纯 URLSession) | TDLibKit + TDLibFramework |

## 系统要求

- Swift 6.0+
- iOS 16.0+ / macOS 13.0+

## 依赖

- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) (0.10.0+)
- [TDLibKit](https://github.com/Swiftgram/TDLibKit) (1.8.0+)

## License

MIT
