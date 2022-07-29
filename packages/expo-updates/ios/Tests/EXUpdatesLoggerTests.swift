//  Copyright (c) 2022 650 Industries, Inc. All rights reserved.

import XCTest

@testable import EXUpdates
@testable import ExpoModulesCore

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class EXUpdatesLoggerTests: XCTestCase {
  func test_BasicLoggingWorks() {
    let logger = UpdatesLogger()
    let logReader = UpdatesLogReader()

    // Mark the date
    let epoch = Date()

    // Write a log message
    logger.error(message: "Test message", code: .NoUpdatesAvailable)

    // Write another log message
    logger.warn(message: "Warning message", code: .AssetsFailedToLoad, updateId: "myUpdateId", assetId: "myAssetId")

    // Use reader to retrieve messages
    var logEntries: [String] = []
    do {
      logEntries = try logReader.getLogEntries(newerThan: epoch)
    } catch {
      XCTFail("logEntries call failed: \(error.localizedDescription)")
    }

    // Verify number of log entries and decoded values
    XCTAssertTrue(logEntries.count >= 2)

    // Check number of entries and values in each entry

    let logEntryText: String = logEntries[logEntries.count - 2]

    let logEntry = UpdatesLogEntry.create(from: logEntryText)
    XCTAssertTrue(logEntry?.timestamp == UInt(epoch.timeIntervalSince1970) * 1000)
    XCTAssertTrue(logEntry?.message == "Test message")
    XCTAssertTrue(logEntry?.code == "NoUpdatesAvailable")
    XCTAssertTrue(logEntry?.level == "error")
    XCTAssertNil(logEntry?.updateId)
    XCTAssertNil(logEntry?.assetId)
    XCTAssertNotNil(logEntry?.stacktrace)

    let logEntryText2: String = logEntries[logEntries.count - 1] as String
    let logEntry2 = UpdatesLogEntry.create(from: logEntryText2)
    XCTAssertTrue(logEntry2?.timestamp == UInt(epoch.timeIntervalSince1970) * 1000)
    XCTAssertTrue(logEntry2?.message == "Warning message")
    XCTAssertTrue(logEntry2?.code == "AssetsFailedToLoad")
    XCTAssertTrue(logEntry2?.level == "warn")
    XCTAssertTrue(logEntry2?.updateId == "myUpdateId")
    XCTAssertTrue(logEntry2?.assetId == "myAssetId")
    XCTAssertNil(logEntry2?.stacktrace)
}

  func test_OnlyExpoUpdatesLogsAppear() {
    let logger = UpdatesLogger()
    let logReader = UpdatesLogReader()
    let otherLogger = Logger.init(category: "bogus")

    // Mark the date
    let epoch = Date()

    // Write an updates log
    logger.error(message: "Test message", code: .NoUpdatesAvailable)

    // Write a log message with a different category
    otherLogger.error("Bogus")

    // Get all entries newer than the date
    // Use reader to retrieve messages
    var logEntries: [String] = []
    do {
      logEntries = try logReader.getLogEntries(newerThan: epoch)
    } catch {
      XCTFail("logEntries call failed: \(error.localizedDescription)")
    }

    // Verify that only the expected message shows up in the reader
    let logEntryText: String = logEntries[logEntries.count - 1] as String
    XCTAssertFalse(logEntryText.contains("Bogus"))
    XCTAssertTrue(logEntryText.contains("Test message"))
  }
}
