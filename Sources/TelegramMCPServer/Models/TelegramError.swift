import Foundation

/// Telegram MCP Server 错误类型
public enum TelegramError: LocalizedError, Sendable {
    // MARK: - 配置错误
    case missingConfiguration(String)
    case notAuthorized
    case clientNotInitialized

    // MARK: - 参数错误
    case missingRequiredArgument(String)
    case invalidArgument(String, String)
    case invalidArgumentType(String, expected: String, got: String)

    // MARK: - 工具错误
    case toolNotFound(String)
    case toolExecutionFailed(String)

    // MARK: - TDLib 错误
    case tdlibError(code: Int, message: String)
    case authorizationFailed(String)
    case chatNotFound(Int64)
    case userNotFound(Int64)
    case messageNotFound(Int64)

    // MARK: - 通用错误
    case encodingError(String)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration(let detail):
            return "Missing configuration: \(detail)"
        case .notAuthorized:
            return "Telegram client is not authorized"
        case .clientNotInitialized:
            return "Telegram client is not initialized"

        case .missingRequiredArgument(let name):
            return "Missing required argument: \(name)"
        case .invalidArgument(let name, let reason):
            return "Invalid argument '\(name)': \(reason)"
        case .invalidArgumentType(let name, let expected, let got):
            return "Invalid type for '\(name)': expected \(expected), got \(got)"

        case .toolNotFound(let name):
            return "Tool not found: \(name)"
        case .toolExecutionFailed(let reason):
            return "Tool execution failed: \(reason)"

        case .tdlibError(let code, let message):
            return "TDLib error [\(code)]: \(message)"
        case .authorizationFailed(let reason):
            return "Authorization failed: \(reason)"
        case .chatNotFound(let id):
            return "Chat not found: \(id)"
        case .userNotFound(let id):
            return "User not found: \(id)"
        case .messageNotFound(let id):
            return "Message not found: \(id)"

        case .encodingError(let detail):
            return "Encoding error: \(detail)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}
