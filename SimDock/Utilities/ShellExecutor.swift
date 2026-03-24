import Foundation

enum ShellExecutor {

    static func run(executable: String = "/usr/bin/xcrun", arguments: [String]) throws -> Data {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return pipe.fileHandleForReading.readDataToEndOfFile()
    }

    static func runFireAndForget(executable: String = "/usr/bin/xcrun", arguments: [String]) {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? run(executable: executable, arguments: arguments)
        }
    }
}
