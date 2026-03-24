import AppKit
import ServiceManagement

final class MenuManager: NSObject, NSMenuDelegate {

    let menu = NSMenu()
    private let simulatorService = SimulatorService()
    private var cachedRuntimes: [SimulatorRuntime] = []

    private var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    override init() {
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    // MARK: - Menu Construction

    private func rebuildMenu() {
        menu.removeAllItems()

        do {
            cachedRuntimes = try simulatorService.fetchDevices()
        } catch {
            let errorItem = NSMenuItem(title: "Failed to load simulators", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        for runtime in cachedRuntimes {
            // Runtime header
            let header = NSMenuItem(title: runtime.displayName, action: nil, keyEquivalent: "")
            header.isEnabled = false
            header.attributedTitle = NSAttributedString(
                string: runtime.displayName,
                attributes: [
                    .font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
            menu.addItem(header)

            for device in runtime.devices {
                let item = NSMenuItem(title: device.name, action: #selector(deviceClicked(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = device
                item.image = device.stateImage

                // Hover submenu: data directory contents
                let submenu = buildDataDirectorySubmenu(for: device)
                item.submenu = submenu

                menu.addItem(item)
            }

            menu.addItem(.separator())
        }

        // Footer
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        let githubItem = NSMenuItem(title: "GitHub - Open Source", action: #selector(openGitHub), keyEquivalent: "")
        githubItem.target = self
        githubItem.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        menu.addItem(githubItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit SimDock", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Data Directory Submenu

    private func buildDataDirectorySubmenu(for device: SimulatorDevice) -> NSMenu {
        let submenu = NSMenu(title: device.name)
        submenu.autoenablesItems = false

        // Installed Apps section
        let apps = FileManagerService.installedApps(dataPath: device.dataPath)
        if !apps.isEmpty {
            let appsHeader = NSMenuItem(title: "Installed Apps", action: nil, keyEquivalent: "")
            appsHeader.isEnabled = false
            appsHeader.attributedTitle = NSAttributedString(
                string: "Installed Apps",
                attributes: [
                    .font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
            submenu.addItem(appsHeader)

            let defaultAppIcon = NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)

            for app in apps {
                let appItem = NSMenuItem(title: app.displayName, action: #selector(revealInFinder(_:)), keyEquivalent: "")
                appItem.target = self
                appItem.image = app.icon ?? defaultAppIcon
                appItem.representedObject = app.appURL
                appItem.toolTip = app.bundleIdentifier

                // Add UserDefaults submenu if preferences exist
                if !app.preferenceFiles.isEmpty {
                    let appSubmenu = NSMenu(title: app.displayName)
                    appSubmenu.autoenablesItems = false

                    let openAppItem = NSMenuItem(title: "Reveal App Bundle", action: #selector(revealInFinder(_:)), keyEquivalent: "")
                    openAppItem.target = self
                    openAppItem.representedObject = app.appURL
                    openAppItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
                    appSubmenu.addItem(openAppItem)

                    appSubmenu.addItem(.separator())

                    let prefsHeader = NSMenuItem(title: "UserDefaults", action: nil, keyEquivalent: "")
                    prefsHeader.isEnabled = false
                    prefsHeader.attributedTitle = NSAttributedString(
                        string: "UserDefaults",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize),
                            .foregroundColor: NSColor.secondaryLabelColor
                        ]
                    )
                    appSubmenu.addItem(prefsHeader)

                    if let prefsURL = app.preferencesURL {
                        let openPrefsItem = NSMenuItem(title: "Open Preferences Folder", action: #selector(openFileItem(_:)), keyEquivalent: "")
                        openPrefsItem.target = self
                        openPrefsItem.representedObject = prefsURL
                        openPrefsItem.image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: nil)
                        appSubmenu.addItem(openPrefsItem)
                    }

                    for file in app.preferenceFiles {
                        let fileName = file.lastPathComponent
                        let fileItem = NSMenuItem(title: fileName, action: #selector(openFileItem(_:)), keyEquivalent: "")
                        fileItem.target = self
                        fileItem.representedObject = file
                        fileItem.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
                        appSubmenu.addItem(fileItem)
                    }

                    appItem.submenu = appSubmenu
                }

                submenu.addItem(appItem)
            }

            submenu.addItem(.separator())
        }

        // Data Directory section
        let dataHeader = NSMenuItem(title: "Data Directory", action: nil, keyEquivalent: "")
        dataHeader.isEnabled = false
        dataHeader.attributedTitle = NSAttributedString(
            string: "Data Directory",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        submenu.addItem(dataHeader)

        let openItem = NSMenuItem(title: "Open in Finder", action: #selector(openInFinder(_:)), keyEquivalent: "")
        openItem.target = self
        openItem.representedObject = device.dataPath
        openItem.image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: nil)
        submenu.addItem(openItem)

        let items = FileManagerService.contentsOfDataDirectory(dataPath: device.dataPath)
        for fileItem in items {
            let symbolName = fileItem.isDirectory ? "folder.fill" : "doc"
            let menuItem = NSMenuItem(title: fileItem.name, action: #selector(openFileItem(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            menuItem.representedObject = fileItem.url
            submenu.addItem(menuItem)
        }

        return submenu
    }

    // MARK: - Actions

    @objc private func deviceClicked(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? SimulatorDevice else { return }
        if device.isBooted {
            simulatorService.shutdownDevice(device.udid)
        } else {
            simulatorService.bootDevice(device.udid)
        }
    }

    @objc private func openInFinder(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    @objc private func openFileItem(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func revealInFinder(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if isLaunchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Failed to toggle launch at login: \(error)")
        }
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/techinpark/SimDock")!)
    }

    @objc private func refreshClicked() {
        rebuildMenu()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}
