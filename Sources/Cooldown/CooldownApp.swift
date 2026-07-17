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
    private var clickOutsideMonitor: Any?
    private var deactivateObserver: NSObjectProtocol?
    private var statusItemMouseMonitor: Any?
    private var popoverKeyMonitor: Any?
    private var lastPopoverKeyDown = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.swizzleCanBecomeKey()
        NSApp.setActivationPolicy(.accessory)
        settings.applyAppearance()
        NotificationService.shared.setup(language: settings.language)

        let root = MenuPopover()
            .environmentObject(store)
            .environmentObject(settings)
            .environmentObject(nav)
            .environmentObject(updater)
        popover.contentViewController = NSHostingController(rootView: root)
        popover.contentSize = NSSize(width: 340, height: 500)
        // .applicationDefined em vez de .transient: o auto-dismiss do .transient
        // reage a QUALQUER keyDown não tratado (inclusive a barra de espaço
        // dentro de um TextField, ex.: nome customizado de serviço), fechando
        // o popover no meio da digitação. Fechamos manualmente (clique fora,
        // Esc, app perde foco) para reproduzir o mesmo comportamento sem
        // interceptar teclas destinadas aos campos de texto.
        popover.behavior = .applicationDefined
        popover.delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            button.refusesFirstResponder = true
            button.setAccessibilityElement(false)
            // Sem target/action: evita que o botão seja "clicado" pelo macOS
            // sem mouse real (Acesso Total pelo Teclado, VoiceOver etc.).
            // Detectamos clique real só via monitor de mouse abaixo.
        }
        statusItemMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let button = self.statusItem.button, event.window === button.window else { return event }
            if event.type == .rightMouseDown {
                self.showContextMenu()
            } else if self.popover.isShown {
                // O cursor costuma ficar em cima do ícone logo após abri-lo;
                // um toque acidental no trackpad (Tap to Click) bem no
                // instante em que a mão alcança a barra de espaço registra
                // um clique real nele, fechando o popover no meio da
                // digitação. Ignoramos um clique no ícone que chega colado
                // (< 500ms) a uma tecla digitada no próprio popover — clique
                // intencional de "fechar de novo" não costuma vir tão rápido
                // depois de uma tecla.
                let sinceLastKey = Date().timeIntervalSince(self.lastPopoverKeyDown)
                if sinceLastKey > 0.5 {
                    self.popover.performClose(nil)
                }
            } else {
                self.openPopover()
            }
            return nil
        }
        popoverKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.window?.className.contains("Popover") == true {
                self?.lastPopoverKeyDown = Date()
            }
            return event
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

        // Verifica atualizações em toda inicialização e a cada 24h; o
        // resultado aparece como banner na tela principal e nas configurações.
        updater.check()
        updater.startPeriodicChecks()

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

    private static func drawIconFlat(in rect: NSRect) {
        if let path = Bundle.main.path(forResource: "icon-flat", ofType: "png"),
           let img = NSImage(contentsOfFile: path) {
            img.isTemplate = true
            img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        } else {
            drawSymbol("snowflake", pointSize: rect.height, x: rect.minX, y: rect.minY)
        }
    }

    /// Ícone da barra sem nenhum timer configurado: só o floco de neve (marca).
    /// Template image = monocromático, adapta ao tema da barra.
    private static let snowflakeOnlyIcon: NSImage = {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        drawIconFlat(in: NSRect(x: 1.5, y: 1.5, width: 13, height: 13))
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
        drawIconFlat(in: NSRect(x: 0, y: 1.5, width: 13, height: 13))
        drawSymbol("hourglass", pointSize: 8.5, x: 15, y: 0.5)
        image.unlockFocus()
        image.isTemplate = true
        return image
    }()

    // MARK: - Cliques no ícone

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        installDismissMonitors()
    }

    /// Substitui o auto-dismiss do `.transient`: fecha ao clicar fora do
    /// popover ou ao o app perder foco (Cmd+Tab, clicar noutro app). Não
    /// observa teclado — Esc é tratado pelos próprios botões "Cancelar"
    /// (`.keyboardShortcut(.cancelAction)`) dentro de cada tela.
    private func installDismissMonitors() {
        removeDismissMonitors()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover.performClose(nil)
        }
        deactivateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.popover.performClose(nil)
        }
    }

    private func removeDismissMonitors() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        if let observer = deactivateObserver {
            NotificationCenter.default.removeObserver(observer)
            deactivateObserver = nil
        }
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

        // Sem passar por statusItem.menu/performClick (dependeria da ação do
        // botão, que removemos de propósito): mostra o menu direto sob o ícone.
        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        }
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

extension AppDelegate: NSPopoverDelegate {
    func popoverDidShow(_ notification: Notification) {
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidClose(_ notification: Notification) {
        removeDismissMonitors()
    }
}

extension NSWindow {
    static func swizzleCanBecomeKey() {
        let originalSelector = #selector(getter: NSWindow.canBecomeKey)
        let swizzledSelector = #selector(getter: NSWindow.customCanBecomeKey)
        
        guard let originalMethod = class_getInstanceMethod(NSWindow.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(NSWindow.self, swizzledSelector) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc var customCanBecomeKey: Bool {
        if self.className.contains("Popover") {
            return true
        }
        return self.customCanBecomeKey // Chama a implementação original
    }
}
