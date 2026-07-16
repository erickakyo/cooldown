import SwiftUI

/// Estado local da tela. (Classe em vez de @State — sem plugin de macros nas CLT.)
final class SettingsScreenModel: ObservableObject {
    @Published var launchAtLogin = LaunchAtLogin.isEnabled
}

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var updater = UpdateChecker()
    @StateObject private var model = SettingsScreenModel()
    var onDone: () -> Void

    private var l: L { L(settings.language) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        // Idioma com bandeirinhas
                        PillPicker(
                            title: l.languageLabel,
                            selection: $settings.language,
                            options: AppLanguage.allCases.map { ($0, "\($0.flag) \($0.label)") }
                        )
                        .onChange(of: settings.language) { _, newValue in
                            NotificationService.shared.updateCategories(language: newValue)
                        }

                        PillPicker(
                            title: l.appearance,
                            selection: $settings.appearance,
                            options: [
                                (AppAppearance.system, l.appearanceSystem),
                                (AppAppearance.light, l.appearanceLight),
                                (AppAppearance.dark, l.appearanceDark),
                            ]
                        )
                        .onChange(of: settings.appearance) { _, _ in
                            settings.applyAppearance()
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(l.launchAtLogin, isOn: $model.launchAtLogin)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: model.launchAtLogin) { _, newValue in
                                if !LaunchAtLogin.set(newValue) {
                                    model.launchAtLogin = LaunchAtLogin.isEnabled
                                }
                            }

                        Toggle(l.showCountdown, isOn: $settings.showCountdownInMenuBar)
                            .toggleStyle(.switch)
                            .controlSize(.small)

                        HStack {
                            PillPicker(
                                title: l.defaultSoundLabel,
                                selection: $settings.defaultSoundName,
                                options: SoundService.availableSounds.map { ($0, $0) }
                            )
                            Button {
                                SoundService.preview(settings.defaultSoundName)
                            } label: {
                                Image(systemName: "play.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(AppConfig.appName) v\(AppConfig.version)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(l.checkUpdates) { updater.check() }
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

    @ViewBuilder
    private var updateStatus: some View {
        switch updater.status {
        case .idle:
            EmptyView()
        case .checking:
            ProgressView().controlSize(.small)
        case .upToDate:
            Label(l.upToDate, systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.green)
        case .available(let version):
            HStack {
                Label(l.updateAvailable(version), systemImage: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Spacer()
                Button(l.download) {
                    NSWorkspace.shared.open(AppConfig.releasesPageURL)
                }
                .buttonStyle(GlassPillButtonStyle(prominent: true))
            }
        case .failed:
            Text(l.updateError)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
