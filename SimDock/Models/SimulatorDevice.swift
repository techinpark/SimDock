import AppKit

// MARK: - simctl JSON Response

struct SimctlDevicesResponse: Codable {
    let devices: [String: [SimulatorDevice]]
}

// MARK: - Device Model

final class SimulatorDevice: Codable {
    let name: String
    let udid: String
    let state: String
    let isAvailable: Bool
    let dataPath: String
    let deviceTypeIdentifier: String
    let lastBootedAt: String?

    var isBooted: Bool { state == "Booted" }

    var stateColor: NSColor {
        switch state {
        case "Booted": return .systemGreen
        case "Shutdown": return .tertiaryLabelColor
        case "Shutting Down": return .systemOrange
        default: return .tertiaryLabelColor
        }
    }

    var stateImage: NSImage {
        let size: CGFloat = 9
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let color = self.stateColor
            color.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}

// MARK: - Runtime Grouping

struct SimulatorRuntime {
    let runtimeIdentifier: String
    let displayName: String
    let devices: [SimulatorDevice]

    static func displayName(from identifier: String) -> String {
        let stripped = identifier.replacingOccurrences(
            of: "com.apple.CoreSimulator.SimRuntime.", with: ""
        )
        let parts = stripped.split(separator: "-")
        guard parts.count >= 2 else { return stripped }
        let os = parts[0]
        let version = parts.dropFirst().joined(separator: ".")
        return "\(os) \(version)"
    }
}
