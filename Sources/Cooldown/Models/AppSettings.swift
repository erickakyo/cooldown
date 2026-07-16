import SwiftUI

enum AppLanguage: String, Codable, CaseIterable {
    case pt, en

    var flag: String { self == .pt ? "🇧🇷" : "🇺🇸" }
    var label: String { self == .pt ? "Português" : "English" }
}

enum AppAppearance: String, Codable, CaseIterable {
    case system, light, dark

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

/// Configurações globais persistidas em UserDefaults.
final class AppSettings: ObservableObject, Codable {
    @Published var language: AppLanguage
    @Published var appearance: AppAppearance
    @Published var defaultSoundName: String
    @Published var showCountdownInMenuBar: Bool
    /// Minutos de antecedência do pré-alerta ("libera em X min"); 0 = desligado.
    @Published var preAlertMinutes: Int
    /// Primeira abertura já guiada (popover automático + dica de login item).
    @Published var hasOnboarded: Bool

    static let defaultsKey = "cooldown.settings"

    init() {
        // Padrão: inglês (público global); o usuário troca para 🇧🇷 nas configurações.
        language = .en
        appearance = .system
        defaultSoundName = "Glass"
        showCountdownInMenuBar = true
        preAlertMinutes = 0
        hasOnboarded = false
    }

    enum CodingKeys: CodingKey {
        case language, appearance, defaultSoundName, showCountdownInMenuBar,
             preAlertMinutes, hasOnboarded
    }

    convenience init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? language
        appearance = try c.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? appearance
        defaultSoundName = try c.decodeIfPresent(String.self, forKey: .defaultSoundName) ?? defaultSoundName
        showCountdownInMenuBar = try c.decodeIfPresent(Bool.self, forKey: .showCountdownInMenuBar) ?? showCountdownInMenuBar
        preAlertMinutes = try c.decodeIfPresent(Int.self, forKey: .preAlertMinutes) ?? preAlertMinutes
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? hasOnboarded
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(language, forKey: .language)
        try c.encode(appearance, forKey: .appearance)
        try c.encode(defaultSoundName, forKey: .defaultSoundName)
        try c.encode(showCountdownInMenuBar, forKey: .showCountdownInMenuBar)
        try c.encode(preAlertMinutes, forKey: .preAlertMinutes)
        try c.encode(hasOnboarded, forKey: .hasOnboarded)
    }

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }
}
