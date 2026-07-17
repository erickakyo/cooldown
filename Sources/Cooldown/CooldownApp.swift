import SwiftUI
import Combine

@main
struct CooldownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Todo o app vive no NSStatusItem do AppDelegate; o SwiftUI só exige
        // uma Scene válida. Não usar Settings{} aqui: o macOS abre essa janela
        // vazia ("Ajustes de Cooldown") sozinho no lançamento, e fechá-la via
        // NSApp.windows quebra o popover do NSStatusItem. Um MenuBarExtra
        // nunca-inserido satisfaz o protocolo sem criar janela nenhuma.
        MenuBarExtra("Cooldown", isInserted: .constant(false)) { EmptyView() }
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

        // O popover é criado uma única vez e reaproveitado — seu
        // NSVisualEffectView/Liquid Glass não recalcula a aparência sozinho
        // quando NSApp.appearance muda depois, então propaga direto pra view.
        settings.$appearance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appearance in
                self?.popover.contentViewController?.view.appearance = appearance.nsAppearance
            }
            .store(in: &observers)

        // Verifica atualizações em toda inicialização; o resultado aparece
        // como banner na tela principal e nas configurações.
        updater.check()

        // Primeira abertura: mostra o popover sozinho, com o card de boas-vindas.
        if !settings.hasOnboarded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.openPopover()
            }
        }
    }

    private func refreshStatusItem() {
        guard let button = statusItem?.button else { return }
        // Ampulheta só aparece quando há algo de fato cronometrando; sem
        // nenhum timer configurado, mostra só a marca (floco de neve).
        button.image = store.timers.isEmpty ? Self.snowflakeOnlyIcon : Self.menuBarIcon
        button.title = store.menuBarText.map { " " + $0 } ?? ""
    }

    private static func drawSymbol(_ name: String, pointSize: CGFloat, x: CGFloat, y: CGFloat) {
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return }
        symbol.draw(
            in: NSRect(x: x, y: y, width: symbol.size.width, height: symbol.size.height),
            from: .zero, operation: .sourceOver, fraction: 1
        )
    }

    /// Ícone da barra sem nenhum timer configurado: só o floco de neve (marca).
    /// Template image = monocromático, adapta ao tema da barra.
    private static let snowflakeOnlyIcon: NSImage = {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        drawSymbol("snowflake", pointSize: 13, x: 1.5, y: 1)
        image.unlockFocus()
        image.isTemplate = true
        return image
    }()

    /// Ícone da barra com timer(s) configurado(s): floco de neve (marca) +
    /// ampulheta menor (semântica de timer).
    private static let menuBarIcon: NSImage = {
        let size = NSSize(width: 22, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        drawSymbol("snowflake", pointSize: 13, x: 0, y: 1)
        drawSymbol("hourglass", pointSize: 8.5, x: 15, y: 0.5)
        image.unlockFocus()
        image.isTemplate = true
        return image
    }()

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

        // Ação mais frequente no caminho mais curto: re-armar timers liberados
        // direto do menu, sem abrir o painel.
        let readyTimers = store.timers.filter { $0.state == .ready }
        for timer in readyTimers {
            let title = "▶ \(l.newCycle(Self.shortDuration(timer.windowDuration))) · \(timer.displayName)"
            let item = NSMenuItem(title: title, action: #selector(menuRearm(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = timer.id
            menu.addItem(item)
        }
        if !readyTimers.isEmpty { menu.addItem(.separator()) }

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

    @objc private func menuRearm(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        store.rearm(id: id)
    }

    private static func shortDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if m == 0 { return "\(h)h" }
        return h > 0 ? "\(h)h\(m)" : "\(m)min"
    }

    @objc private func menuCheckUpdates() {
        updater.check()
        open(screen: .settings)
    }
}
