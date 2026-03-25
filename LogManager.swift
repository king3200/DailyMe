import Foundation
import AppKit

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
}

class LogManager {
    static let shared = LogManager()

    private let fileHandle: FileHandle?
    private let logDirectory: URL
    private let logFilePath: URL
    private let dateFormatter: DateFormatter
    private let writeQueue = DispatchQueue(label: "com.dailyme.logmanager.write")

    private init() {
        // 设置日志目录: ~/Library/Logs/DailyMe/
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        logDirectory = homeDirectory.appendingPathComponent("Library/Logs/DailyMe/")
        logFilePath = logDirectory.appendingPathComponent("app.log")

        // 设置日期格式化
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // 创建日志目录（如果不存在）
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)

        // 打开或创建日志文件
        if FileManager.default.fileExists(atPath: logFilePath.path) {
            fileHandle = try? FileHandle(forWritingTo: logFilePath)
            fileHandle?.seekToEndOfFile()
        } else {
            FileManager.default.createFile(atPath: logFilePath.path, contents: nil)
            fileHandle = try? FileHandle(forWritingTo: logFilePath)
        }

        // 记录启动日志
        log("DailyMe 应用启动", level: .info)
    }

    func log(_ message: String, level: LogLevel = .debug) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)\n"

        writeQueue.async {
            if let data = logMessage.data(using: .utf8) {
                self.fileHandle?.write(data)
            }
        }

        // 同时打印到控制台
        print("[DailyMe] \(message)")
    }

    func openLogFile() {
        NSWorkspace.shared.open(logFilePath)
    }

    func getLogFilePath() -> URL {
        return logFilePath
    }

    deinit {
        try? fileHandle?.close()
    }
}