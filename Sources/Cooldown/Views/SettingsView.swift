import SwiftUI

/// Estado local da tela. (Classe em vez de @State — sem plugin de macros nas CLT.)
final class SettingsScreenModel: ObservableObject {
    @Published var launchAtLogin = LaunchAtLogin.isEnabled
}

/// Configurações no estilo dos Ajustes do Sistema do macOS: linhas com
/// ícone colorido + rótulo à esquerda e controle à direita, agrupadas em
/// cards com divisórias internas.
struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: TimerStore
    @EnvironmentObject var updater: UpdateChecker
    @StateObject private var model = SettingsScreenModel()
    var onDone: () -> Void

    private var l: L { L(settings.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Idioma e aparência
                GlassCard {
                    VStack(spacing: 0) {
                        row(icon: "globe", color: .blue, title: l.languageLabel) {
                            PillMenu(
                                selection: $settings.language,
                                options: AppLanguage.allCases.map { ($0, $0.label) },
                                glyph: { $0.flag }
                            )
                        }
                        .onChange(of: settings.language) { _, newValue in
                            NotificationService.shared.updateCategories(language: newValue)
                        }

                        rowDivider

                        row(icon: "circle.lefthalf.filled", color: .indigo, title: l.appearance) {
                            PillMenu(
                                selection: $settings.appearance,
                                options: [
                                    (AppAppearance.system, l.appearanceSystem),
                                    (AppAppearance.light, l.appearanceLight),
                                    (AppAppearance.dark, l.appearanceDark),
                                ]
                            )
                        }
                        .onChange(of: settings.appearance) { _, _ in
                            settings.applyAppearance()
                        }
                    }
                }

                // Comportamento
                GlassCard {
                    VStack(spacing: 0) {
                        row(icon: "power", color: .green, title: l.launchAtLogin) {
                            Toggle("", isOn: $model.launchAtLogin)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: model.launchAtLogin) { _, newValue in
                                    if !LaunchAtLogin.set(newValue) {
                                        model.launchAtLogin = LaunchAtLogin.isEnabled
                                    }
                                }
                        }

                        rowDivider

                        row(icon: "clock", color: .teal, title: l.showCountdown) {
                            Toggle("", isOn: $settings.showCountdownInMenuBar)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }

                        rowDivider

                        row(icon: "speaker.wave.2.fill", color: .pink, title: l.defaultSoundLabel) {
                            HStack(spacing: 6) {
                                PillMenu(
                                    selection: $settings.defaultSoundName,
                                    options: SoundService.availableSounds.map { ($0, $0) }
                                )
                                Button {
                                    SoundService.preview(settings.defaultSoundName)
                                } label: {
                                    Image(systemName: "play.circle")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                        }

                        rowDivider

                        row(icon: "bell.badge.fill", color: .orange, title: l.preAlertLabel) {
                            PillMenu(
                                selection: $settings.preAlertMinutes,
                                options: [(0, l.off), (5, l.minutesBefore(5)),
                                          (10, l.minutesBefore(10)), (15, l.minutesBefore(15))]
                            )
                        }
                        .onChange(of: settings.preAlertMinutes) { _, _ in
                            store.rescheduleAll()
                        }
                    }
                }

                // Versão e atualizações
                GlassCard {
                    VStack(spacing: 0) {
                        row(icon: "arrow.triangle.2.circlepath", color: .gray,
                            title: l.versionLabel(AppConfig.version)) {
                            Button(l.checkUpdatesShort) { updater.check() }
                                .buttonStyle(GlassPillButtonStyle())
                                .disabled(updater.status == .checking)
                        }
                        updateStatus
                    }
                }
            }
            .padding(14)
        }
    }

    // MARK: - Linha no estilo Ajustes do Sistema

    private func row<Content: View>(
        icon: String, color: Color, title: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                .fill(color.gradient)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                )
            Text(title)
                .font(.callout)
                .lineLimit(1)
            Spacer(minLength: 8)
            control()
        }
        .padding(.vertical, 5)
    }

    private var rowDivider: some View {
        Divider()
            .opacity(0.5)
            .padding(.leading, 30)
            .padding(.vertical, 2)
    }

    @ViewBuilder
    private var updateStatus: some View {
        switch updater.status {
        case .idle:
            EmptyView()
        case .checking:
            HStack {
                ProgressView().controlSize(.small)
                Spacer()
            }
            .padding(.top, 6)
        case .upToDate:
            HStack {
                Label(l.upToDate, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
                Spacer()
            }
            .padding(.top, 6)
        case .available(let version):
            HStack {
                Label(l.updateAvailable(version), systemImage: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Spacer()
                Button(l.download) {
                    updater.openDownloadPageAndQuit()
                }
                .buttonStyle(GlassPillButtonStyle(prominent: true))
            }
            .padding(.top, 6)
        case .failed:
            HStack {
                Text(l.updateError)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.top, 6)
        }
    }
}
