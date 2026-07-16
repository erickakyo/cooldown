import SwiftUI

@main
struct CooldownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings: AppSettings
    @StateObject private var store: TimerStore

    init() {
        let settings = AppSettings.load()
        _settings = StateObject(wrappedValue: settings)
        _store = StateObject(wrappedValue: TimerStore(settings: settings))
        NotificationService.shared.setup(language: settings.language)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuPopover()
                .environmentObject(store)
                .environmentObject(settings)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App de barra de menus: sem ícone no Dock.
        NSApp.setActivationPolicy(.accessory)
        AppSettings.load().applyAppearance()
    }
}

/// Ícone na barra de menus + contagem opcional do próximo timer.
struct MenuBarLabel: View {
    @ObservedObject var store: TimerStore

    var body: some View {
        if let text = store.menuBarText {
            HStack(spacing: 3) {
                Image(systemName: hasReadyTimer ? "checkmark.circle.fill" : "hourglass")
                Text(text).monospacedDigit()
            }
        } else {
            Image(systemName: hasReadyTimer ? "checkmark.circle.fill" : "hourglass")
        }
    }

    private var hasReadyTimer: Bool {
        store.timers.contains { $0.state == .ready }
    }
}
