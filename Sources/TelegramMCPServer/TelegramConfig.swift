import Foundation

/// Telegram MCP Server 配置
public struct TelegramConfig: Sendable {
    /// Telegram API ID (从 https://my.telegram.org 获取)
    public let apiId: Int32

    /// Telegram API Hash (从 https://my.telegram.org 获取)
    public let apiHash: String

    /// 数据库目录路径 (TDLib 本地存储)
    public let databaseDirectory: String

    /// 文件目录路径 (TDLib 文件缓存)
    public let filesDirectory: String

    /// 是否使用消息数据库
    public let useMessageDatabase: Bool

    /// 是否使用文件数据库
    public let useFileDatabase: Bool

    /// 是否使用聊天信息数据库
    public let useChatInfoDatabase: Bool

    /// 系统语言代码
    public let systemLanguageCode: String

    /// 设备型号
    public let deviceModel: String

    /// 应用版本
    public let applicationVersion: String

    /// 默认数据库目录
    public static let defaultDatabaseDirectory = "tdlib_data"

    /// 默认文件目录
    public static let defaultFilesDirectory = "tdlib_files"

    public init(
        apiId: Int32,
        apiHash: String,
        databaseDirectory: String = TelegramConfig.defaultDatabaseDirectory,
        filesDirectory: String = TelegramConfig.defaultFilesDirectory,
        useMessageDatabase: Bool = true,
        useFileDatabase: Bool = true,
        useChatInfoDatabase: Bool = true,
        systemLanguageCode: String = "en",
        deviceModel: String = "iOS",
        applicationVersion: String = "1.0.0"
    ) {
        self.apiId = apiId
        self.apiHash = apiHash
        self.databaseDirectory = databaseDirectory
        self.filesDirectory = filesDirectory
        self.useMessageDatabase = useMessageDatabase
        self.useFileDatabase = useFileDatabase
        self.useChatInfoDatabase = useChatInfoDatabase
        self.systemLanguageCode = systemLanguageCode
        self.deviceModel = deviceModel
        self.applicationVersion = applicationVersion
    }

    /// 从环境变量创建配置
    public static func fromEnvironment() throws -> TelegramConfig {
        guard let apiIdStr = ProcessInfo.processInfo.environment["TELEGRAM_API_ID"],
              let apiId = Int32(apiIdStr) else {
            throw TelegramError.missingConfiguration("TELEGRAM_API_ID")
        }

        guard let apiHash = ProcessInfo.processInfo.environment["TELEGRAM_API_HASH"] else {
            throw TelegramError.missingConfiguration("TELEGRAM_API_HASH")
        }

        return TelegramConfig(apiId: apiId, apiHash: apiHash)
    }

    /// 验证配置
    public func validate() throws {
        guard apiId > 0 else {
            throw TelegramError.missingConfiguration("API ID must be positive")
        }
        guard !apiHash.isEmpty else {
            throw TelegramError.missingConfiguration("API Hash is required")
        }
    }
}
