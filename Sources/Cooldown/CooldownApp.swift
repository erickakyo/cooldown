import SwiftUI
import Combine

@main
struct CooldownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Todo o app vive no NSStatusItem do AppDelegate; o SwiftUI só exige
        // uma Scene válida.
        Settings { EmptyView() }
    }
}

/// Gerencia o ícone da barra de menus manualmente (NSStatusItem) em vez de
/// MenuBarExtra: é o que permite diferenciar clique esquerdo (popover) de
/// clique direito (menu de contexto).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings.load()
    private(set) lazy var store = TimerStore(settings: settings)
    let nav = NavModel()
    let updater = UpdateChecker()

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var observers: [AnyCancellable] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        settings.applyAppearance()
        NotificationService.shared.setup(language: settings.language)

        let root = MenuPopover()
            .environmentObject(store)
            .environmentObject(settings)
            .environmentObject(nav)
            .environmentObject(updater)
        popover.contentViewController = NSHostingController(rootView: root)
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Contagem/ícone na barra acompanham o tick do store e as configurações.
        store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshStatusItem() }
            .store(in: &observers)
        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshStatusItem() }
            .store(in: &observers)
        refreshStatusItem()

        // Verifica atualizações em toda inicialização; o resultado aparece
        // como banner na tela principal e nas configurações.
        updater.check()
    }

    private func refreshStatusItem() {
        guard let button = statusItem?.button else { return }
        let hasReady = store.timers.contains { $0.state == .ready }
        let symbol = hasReady ? "checkmark.circle.fill" : "hourglass"
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Cooldown")
        button.title = store.menuBarText.map { " " + $0 } ?? ""
    }

    // MARK: - Cliques no ícone

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func open(screen: Screen) {
        nav.screen = screen
        if !popover.isShown { openPopover() }
    }

    private func showContextMenu() {
        let l = L(settings.language)
        let menu = NSMenu()
        menu.addItem(makeItem(l.openApp, symbol: "hourglass", action: #selector(menuOpenMain)))
        menu.addItem(makeItem(l.settings, symbol: "gearshape", action: #selector(menuOpenSettings)))
        menu.addItem(makeItem(l.checkUpdates, symbol: "arrow.down.circle", action: #selector(menuCheckUpdates)))
        menu.addItem(makeItem(l.about, symbol: "info.circle", action: #selector(menuOpenAbout)))
        menu.addItem(makeItem(l.donate, symbol: "cup.and.saucer.fill", action: #selector(menuOpenDonate)))
        menu.addItem(.separator())
        menu.addItem(makeItem(l.quit, symbol: "power", action: #selector(menuQuit)))

        // Padrão para menu de contexto em NSStatusItem: atribui o menu,
        // dispara o clique (mostra o menu, síncrono) e remove — assim o
        // clique esquerdo continua abrindo o popover.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func makeItem(_ title: String, symbol: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }

    @objc private func menuOpenMain() { open(screen: .main) }
    @objc private func menuOpenSettings() { open(screen: .settings) }
    @objc private func menuOpenAbout() { open(screen: .about) }
    @objc private func menuOpenDonate() { open(screen: .donate) }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    @objc private func menuCheckUpdates() {
        updater.check()
        open(screen: .settings)
    }
}
