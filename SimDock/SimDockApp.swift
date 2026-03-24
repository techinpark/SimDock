import SwiftUI

@main
struct SimDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let menuManager = MenuManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let icon = NSImage(systemSymbolName: "iphone", accessibilityDescription: "SimDock")
            icon?.size = NSSize(width: 18, height: 18)
            button.image = icon
        }

        statusItem.menu = menuManager.menu
    }
}
