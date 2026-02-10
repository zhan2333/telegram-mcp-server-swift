import XCTest
@testable import TelegramMCPServer
import MCP

final class TelegramMCPServerTests: XCTestCase {

    func testServerInitialization() async throws {
        let server = TelegramMCPServer(apiId: 12345, apiHash: "test_hash")

        XCTAssertEqual(server.name, "telegram")
        XCTAssertEqual(server.version, "1.0.0")
        XCTAssertFalse(server.isRunning)
    }

    func testToolRegistration() async throws {
        let server = TelegramMCPServer(apiId: 12345, apiHash: "test_hash")

        // 等待工具初始化
        try await Task.sleep(nanoseconds: 100_000_000)

        let tools = server.getTools()
        XCTAssertEqual(tools.count, 29, "Should have 29 tools registered")
    }

    func testAllExpectedToolNamesAreRegistered() async throws {
        let server = TelegramMCPServer(apiId: 12345, apiHash: "test_hash")

        // 等待工具初始化
        try await Task.sleep(nanoseconds: 100_000_000)

        let toolNames = server.getToolNames()
        let expectedTools = TelegramTools.toolNames

        for expectedName in expectedTools {
            XCTAssertTrue(toolNames.contains(expectedName), "Missing tool: \(expectedName)")
        }
    }

    func testUnknownToolExecution() async throws {
        let server = TelegramMCPServer(apiId: 12345, apiHash: "test_hash")

        // 等待工具初始化
        try await Task.sleep(nanoseconds: 100_000_000)

        do {
            _ = try await server.executeTool(name: "unknown_tool", arguments: [:])
            XCTFail("Should throw error for unknown tool")
        } catch let error as TelegramError {
            if case .toolNotFound(let name) = error {
                XCTAssertEqual(name, "unknown_tool")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
}

final class TelegramConfigTests: XCTestCase {

    func testDefaultConfig() {
        let config = TelegramConfig(apiId: 12345, apiHash: "test_hash")

        XCTAssertEqual(config.apiId, 12345)
        XCTAssertEqual(config.apiHash, "test_hash")
        XCTAssertEqual(config.databaseDirectory, TelegramConfig.defaultDatabaseDirectory)
        XCTAssertEqual(config.filesDirectory, TelegramConfig.defaultFilesDirectory)
        XCTAssertTrue(config.useMessageDatabase)
    }

    func testCustomConfig() {
        let config = TelegramConfig(
            apiId: 99999,
            apiHash: "custom_hash",
            databaseDirectory: "/custom/db",
            filesDirectory: "/custom/files",
            useMessageDatabase: false,
            systemLanguageCode: "zh",
            deviceModel: "iPad",
            applicationVersion: "2.0.0"
        )

        XCTAssertEqual(config.apiId, 99999)
        XCTAssertEqual(config.apiHash, "custom_hash")
        XCTAssertEqual(config.databaseDirectory, "/custom/db")
        XCTAssertFalse(config.useMessageDatabase)
        XCTAssertEqual(config.systemLanguageCode, "zh")
        XCTAssertEqual(config.deviceModel, "iPad")
    }
}

final class ArgumentExtractorTests: XCTestCase {

    func testRequiredString() throws {
        let args: [String: Value] = [
            "name": .string("test")
        ]
        let extractor = ArgumentExtractor(args)

        let value = try extractor.requiredString("name")
        XCTAssertEqual(value, "test")
    }

    func testMissingRequiredString() {
        let args: [String: Value] = [:]
        let extractor = ArgumentExtractor(args)

        XCTAssertThrowsError(try extractor.requiredString("name")) { error in
            XCTAssertTrue(error is TelegramError)
        }
    }

    func testRequiredInt64() throws {
        let args: [String: Value] = [
            "chat_id": .int(123456789)
        ]
        let extractor = ArgumentExtractor(args)

        let value = try extractor.requiredInt64("chat_id")
        XCTAssertEqual(value, 123456789)
    }

    func testInt64FromString() throws {
        let args: [String: Value] = [
            "chat_id": .string("9876543210")
        ]
        let extractor = ArgumentExtractor(args)

        let value = try extractor.requiredInt64("chat_id")
        XCTAssertEqual(value, 9876543210)
    }

    func testOptionalString() {
        let args: [String: Value] = [
            "name": .string("test")
        ]
        let extractor = ArgumentExtractor(args)

        XCTAssertEqual(extractor.optionalString("name"), "test")
        XCTAssertNil(extractor.optionalString("missing"))
    }

    func testOptionalInt() {
        let args: [String: Value] = [
            "count": .int(42)
        ]
        let extractor = ArgumentExtractor(args)

        XCTAssertEqual(extractor.optionalInt("count"), 42)
        XCTAssertNil(extractor.optionalInt("missing"))
    }
}

final class ValueExtensionsTests: XCTestCase {

    func testValueToAny() {
        let stringValue = Value.string("test")
        XCTAssertEqual(stringValue.toAny() as? String, "test")

        let intValue = Value.int(42)
        XCTAssertEqual(intValue.toAny() as? Int, 42)

        let boolValue = Value.bool(true)
        XCTAssertEqual(boolValue.toAny() as? Bool, true)

        let nullValue = Value.null
        XCTAssertNil(nullValue.toAny())
    }

    func testAnyToValue() {
        let stringValue = Value.from("test")
        XCTAssertEqual(stringValue.stringValue, "test")

        let intValue = Value.from(42)
        XCTAssertEqual(intValue.intValue, 42)

        let boolValue = Value.from(true)
        XCTAssertEqual(boolValue.boolValue, true)

        let nullValue = Value.from(nil)
        XCTAssertTrue(nullValue.isNull)
    }
}
