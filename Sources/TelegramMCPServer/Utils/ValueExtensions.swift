import Foundation
import MCP

// MARK: - Value 便捷扩展

extension Value {
    /// 获取字符串值
    public var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    /// 获取整数值
    public var intValue: Int? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }

    /// 获取 Int64 值
    public var int64Value: Int64? {
        switch self {
        case .int(let value):
            return Int64(value)
        case .string(let value):
            return Int64(value)
        default:
            return nil
        }
    }

    /// 获取 Int32 值
    public var int32Value: Int32? {
        if case .int(let value) = self {
            return Int32(value)
        }
        return nil
    }

    /// 获取浮点数值
    public var doubleValue: Double? {
        switch self {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        default:
            return nil
        }
    }

    /// 获取布尔值
    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }

    /// 获取数组值
    public var arrayValue: [Value]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }

    /// 获取字典值
    public var objectValue: [String: Value]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }

    /// 是否为 null
    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }
}

// MARK: - Value 转换为 Any

extension Value {
    /// 转换为 Swift 原生类型
    public func toAny() -> Any? {
        switch self {
        case .null:
            return nil
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        case .data(_, let value):
            return value
        case .array(let value):
            return value.map { $0.toAny() }
        case .object(let value):
            return value.mapValues { $0.toAny() }
        }
    }
}

// MARK: - Any 转换为 Value

extension Value {
    /// 从 Swift 原生类型创建 Value
    public static func from(_ any: Any?) -> Value {
        guard let any = any else {
            return .null
        }

        switch any {
        case let value as Bool:
            return .bool(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as String:
            return .string(value)
        case let value as Data:
            return .data(value)
        case let value as [Any]:
            return .array(value.map { Value.from($0) })
        case let value as [String: Any]:
            return .object(value.mapValues { Value.from($0) })
        default:
            return .string(String(describing: any))
        }
    }
}

// MARK: - 参数提取帮助器

/// 从 Value 字典中提取参数的帮助器
public struct ArgumentExtractor {
    private let arguments: [String: Value]

    public init(_ arguments: [String: Value]) {
        self.arguments = arguments
    }

    /// 获取必需的字符串参数
    public func requiredString(_ key: String) throws -> String {
        guard let value = arguments[key] else {
            throw TelegramError.missingRequiredArgument(key)
        }
        guard let stringValue = value.stringValue else {
            throw TelegramError.invalidArgumentType(key, expected: "string", got: value.typeName)
        }
        return stringValue
    }

    /// 获取可选的字符串参数
    public func optionalString(_ key: String) -> String? {
        arguments[key]?.stringValue
    }

    /// 获取必需的 Int64 参数 (Telegram ID)
    public func requiredInt64(_ key: String) throws -> Int64 {
        guard let value = arguments[key] else {
            throw TelegramError.missingRequiredArgument(key)
        }
        guard let int64Value = value.int64Value else {
            throw TelegramError.invalidArgumentType(key, expected: "integer (int64)", got: value.typeName)
        }
        return int64Value
    }

    /// 获取可选的 Int64 参数
    public func optionalInt64(_ key: String) -> Int64? {
        arguments[key]?.int64Value
    }

    /// 获取可选的整数参数
    public func optionalInt(_ key: String) -> Int? {
        arguments[key]?.intValue
    }

    /// 获取可选的布尔参数
    public func optionalBool(_ key: String) -> Bool? {
        arguments[key]?.boolValue
    }

    /// 获取必需的 Int64 数组参数
    public func requiredInt64Array(_ key: String) throws -> [Int64] {
        guard let value = arguments[key] else {
            throw TelegramError.missingRequiredArgument(key)
        }
        guard let arrayValue = value.arrayValue else {
            throw TelegramError.invalidArgumentType(key, expected: "array", got: value.typeName)
        }
        return arrayValue.compactMap { $0.int64Value }
    }

    /// 获取可选的数组参数
    public func optionalArray(_ key: String) -> [Value]? {
        arguments[key]?.arrayValue
    }

    /// 检查参数是否存在
    public func has(_ key: String) -> Bool {
        if let value = arguments[key], !value.isNull {
            return true
        }
        return false
    }
}

// MARK: - Value Type Name

extension Value {
    /// 获取类型名称
    var typeName: String {
        switch self {
        case .null: return "null"
        case .bool: return "boolean"
        case .int: return "integer"
        case .double: return "number"
        case .string: return "string"
        case .data: return "data"
        case .array: return "array"
        case .object: return "object"
        }
    }
}
