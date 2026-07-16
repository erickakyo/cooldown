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

    static let defaultsKey = "cooldown.settings"

    init() {
        let systemIsPT = Locale.preferredLanguages.first?.hasPrefix("pt") ?? false
        language = systemIsPT ? .pt : .en
        appearance = .system
        defaultSoundName = "Glass"
        showCountdownInMenuBar = true
    }

    enum CodingKeys: CodingKey {
        case language, appearance, defaultSoundName, showCountdownInMenuBar
    }

    convenience init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? language
        appearance = try c.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? appearance
        defaultSoundName = try c.decodeIfPresent(String.self, forKey: .defaultSoundName) ?? defaultSoundName
        showCountdownInMenuBar = try c.decodeIfPresent(Bool.self, forKey: .showCountdownInMenuBar) ?? showCountdownInMenuBar
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(language, forKey: .language)
        try c.encode(appearance, forKey: .appearance)
        try c.encode(defaultSoundName, forKey: .defaultSoundName)
        try c.encode(showCountdownInMenuBar, forKey: .showCountdownInMenuBar)
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
