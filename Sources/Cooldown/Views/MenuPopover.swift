import SwiftUI

enum Screen: Equatable {
    case main
    case editor(AITimer?)   // nil = novo timer
    case settings
    case about
    case donate
}

/// Navegação do popover — compartilhada com o AppDelegate para o menu de
/// contexto do ícone poder abrir telas específicas. (Classe em vez de @State
/// porque o plugin de macros do SwiftUI não existe nas Command Line Tools.)
final class NavModel: ObservableObject {
    @Published var screen: Screen = .main
}

/// Conteúdo do painel da barra de menus, com navegação interna entre telas.
struct MenuPopover: View {
    @EnvironmentObject var store: TimerStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var nav: NavModel

    private var screen: Screen {
        get { nav.screen }
        nonmutating set { nav.screen = newValue }
    }

    private var l: L { L(settings.language) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)

            Group {
                switch screen {
                case .main:
                    MainScreen(screen: $nav.screen)
                case .editor(let timer):
                    TimerEditorView(editing: timer) { screen = .main }
                case .settings:
                    SettingsView { screen = .main }
                case .about:
                    AboutView { screen = .main }
                case .donate:
                    DonateView { screen = .main }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider().opacity(0.4)
            footer
        }
        // Altura fixa: o painel do MenuBarExtra corta o conteúdo quando a
        // altura é variável (min/max) — bug de sizing do estilo .window.
        .frame(width: 340, height: 460)
        // O vidro do macOS 26 é transparente demais para leitura — este
        // material extra escurece o que está atrás do painel.
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack {
            if screen != .main {
                Button {
                    screen = .main
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
            }
            Image(systemName: "hourglass")
                .foregroundStyle(.tint)
            Text(headerTitle)
                .font(.headline)
            Spacer()
            if screen == .main {
                Button {
                    screen = .editor(nil)
                } label: {
                    Label(l.newTimer, systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(GlassPillButtonStyle(prominent: true))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var headerTitle: String {
        switch screen {
        case .main: return AppConfig.appName
        case .editor(let t): return t == nil ? l.newTimer : l.editTimer
        case .settings: return l.settings
        case .about: return l.about
        case .donate: return l.donate
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            footerButton("gearshape", l.settings, active: screen == .settings) { screen = .settings }
            footerButton("cup.and.saucer.fill", l.donate, active: screen == .donate) { screen = .donate }
            footerButton("info.circle", l.about, active: screen == .about) { screen = .about }
            Spacer()
            footerButton("power", l.quit, active: false) { NSApp.terminate(nil) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func footerButton(
        _ symbol: String, _ help: String, active: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .foregroundStyle(active ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
        .help(help)
    }
}

/// Tela principal: banner de atualização + lista de timers.
struct MainScreen: View {
    @EnvironmentObject var store: TimerStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var updater: UpdateChecker
    @Binding var screen: Screen

    private var l: L { L(settings.language) }

    var body: some View {
        VStack(spacing: 0) {
            if case .available(let version) = updater.status {
                updateBanner(version)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
            }

            if !settings.hasOnboarded {
                onboardingCard
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
            }

            if store.timers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(store.timers) { timer in
                            TimerRowView(timer: timer) { screen = .editor(timer) }
                        }
                    }
                    .padding(12)
                }
            }
        }
    }

    /// Primeira abertura: sugere ativar "Iniciar com o sistema" — sem isso o
    /// app pode não estar rodando na hora em que o usuário mais precisa dele.
    private var onboardingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(l.onboardTitle, systemImage: "hand.wave.fill")
                    .font(.subheadline.weight(.semibold))
                Text(l.onboardLoginHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(l.enable) {
                        LaunchAtLogin.set(true)
                        settings.hasOnboarded = true
                    }
                    .buttonStyle(GlassPillButtonStyle(prominent: true))
                    Button(l.notNow) {
                        settings.hasOnboarded = true
                    }
                    .buttonStyle(GlassPillButtonStyle())
                }
            }
        }
    }

    private func updateBanner(_ version: String) -> some View {
        GlassCard {
            HStack {
                Label(l.updateAvailable(version), systemImage: "arrow.down.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
                Spacer()
                Button(l.download) {
                    NSWorkspace.shared.open(AppConfig.releasesPageURL)
                }
                .buttonStyle(GlassPillButtonStyle(prominent: true))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "hourglass.bottomhalf.filled")
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
            Text(l.noTimers).font(.headline)
            Text(l.noTimersHint)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
