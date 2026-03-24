import AppKit

final class MenuManager: NSObject, NSMenuDelegate {

    let menu = NSMenu()
    private let simulatorService = SimulatorService()
    private var cachedRuntimes: [SimulatorRuntime] = []

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

        // Open in Finder
        let openItem = NSMenuItem(title: "Open in Finder", action: #selector(openInFinder(_:)), keyEquivalent: "")
        openItem.target = self
        openItem.representedObject = device.dataPath
        openItem.image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: nil)
        submenu.addItem(openItem)
        submenu.addItem(.separator())

        let items = FileManagerService.contentsOfDataDirectory(dataPath: device.dataPath)

        if items.isEmpty {
            let emptyItem = NSMenuItem(title: "No data", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            for fileItem in items {
                let symbolName = fileItem.isDirectory ? "folder.fill" : "doc"
                let menuItem = NSMenuItem(title: fileItem.name, action: #selector(openFileItem(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
                menuItem.representedObject = fileItem.url
                submenu.addItem(menuItem)
            }
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
