import AppKit

struct FileItem {
    let url: URL
    var name: String { url.lastPathComponent }
    var isDirectory: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}

struct InstalledApp {
    let displayName: String
    let bundleIdentifier: String
    let appURL: URL
    let icon: NSImage?
    let preferencesURL: URL?
    let preferenceFiles: [URL]
}

enum FileManagerService {

    static func contentsOfDataDirectory(dataPath: String) -> [FileItem] {
        let url = URL(fileURLWithPath: dataPath)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .map { FileItem(url: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func installedApps(dataPath: String) -> [InstalledApp] {
        let baseURL = URL(fileURLWithPath: dataPath)
        let bundlePath = baseURL.appendingPathComponent("Containers/Bundle/Application")

        guard let containers = try? FileManager.default.contentsOfDirectory(
            at: bundlePath,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        // Build bundle ID → data container mapping
        let dataContainerMap = buildDataContainerMap(dataPath: dataPath)

        var apps: [InstalledApp] = []

        for container in containers {
            guard let appDirs = try? FileManager.default.contentsOfDirectory(
                at: container,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            guard let appDir = appDirs.first(where: { $0.pathExtension == "app" }) else { continue }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            guard let plistData = try? Data(contentsOf: infoPlistURL),
                  let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
                  let bundleId = plist["CFBundleIdentifier"] as? String else { continue }

            // Skip Apple system apps
            if bundleId.hasPrefix("com.apple.") { continue }

            let rawDisplayName = (plist["CFBundleDisplayName"] as? String)
                ?? (plist["CFBundleName"] as? String)
                ?? ""
            let displayName = rawDisplayName.isEmpty
                ? appDir.deletingPathExtension().lastPathComponent
                : rawDisplayName

            let icon = loadAppIcon(from: appDir, plist: plist)

            // Find UserDefaults plist files
            var preferencesURL: URL? = nil
            var preferenceFiles: [URL] = []
            if let dataContainerURL = dataContainerMap[bundleId] {
                let prefsDir = dataContainerURL.appendingPathComponent("Library/Preferences")
                preferencesURL = prefsDir
                if let files = try? FileManager.default.contentsOfDirectory(
                    at: prefsDir,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ) {
                    preferenceFiles = files
                        .filter { $0.pathExtension == "plist" }
                        .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
                }
            }

            apps.append(InstalledApp(
                displayName: displayName,
                bundleIdentifier: bundleId,
                appURL: appDir,
                icon: icon,
                preferencesURL: preferencesURL,
                preferenceFiles: preferenceFiles
            ))
        }

        return apps.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Maps bundle ID → Data Container URL via metadata plist
    private static func buildDataContainerMap(dataPath: String) -> [String: URL] {
        let dataContainersURL = URL(fileURLWithPath: dataPath)
            .appendingPathComponent("Containers/Data/Application")

        guard let containers = try? FileManager.default.contentsOfDirectory(
            at: dataContainersURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [:] }

        var map: [String: URL] = [:]
        for container in containers {
            let metadataURL = container.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            guard let data = try? Data(contentsOf: metadataURL),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let bundleId = plist["MCMMetadataIdentifier"] as? String else { continue }
            map[bundleId] = container
        }
        return map
    }

    private static func loadAppIcon(from appURL: URL, plist: [String: Any]) -> NSImage? {
        // Try CFBundleIcons > CFBundlePrimaryIcon > CFBundleIconFiles
        if let icons = plist["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let iconName = iconFiles.last {
            // Look for the actual file (may have @2x, @3x suffixes)
            let candidates = [
                "\(iconName)@3x.png",
                "\(iconName)@2x.png",
                "\(iconName).png",
                iconName
            ]
            for candidate in candidates {
                let iconURL = appURL.appendingPathComponent(candidate)
                if let image = NSImage(contentsOf: iconURL) {
                    return resizeIcon(image)
                }
            }
            // Try without extension (asset catalog compiled name)
            if let image = findAssetIcon(named: iconName, in: appURL) {
                return resizeIcon(image)
            }
        }

        // Fallback: CFBundleIconFile
        if let iconFile = plist["CFBundleIconFile"] as? String {
            let iconURL = appURL.appendingPathComponent(iconFile)
            if let image = NSImage(contentsOf: iconURL) {
                return resizeIcon(image)
            }
        }

        return nil
    }

    private static func findAssetIcon(named name: String, in appURL: URL) -> NSImage? {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: appURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }

        if let match = contents.first(where: {
            $0.lastPathComponent.hasPrefix(name) && $0.pathExtension == "png"
        }) {
            return NSImage(contentsOf: match)
        }
        return nil
    }

    private static func resizeIcon(_ image: NSImage) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let resized = NSImage(size: size)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        return resized
    }
}
