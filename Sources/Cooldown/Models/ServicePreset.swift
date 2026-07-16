import Foundation

/// Preset de serviço de IA com janela de limite conhecida.
/// Novos presets chegam via atualização do app.
struct ServicePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String            // SF Symbol
    let windowDuration: TimeInterval

    static let claude = ServicePreset(id: "claude", name: "Claude", symbol: "sparkle", windowDuration: 5 * 3600)
    static let chatgpt = ServicePreset(id: "chatgpt", name: "ChatGPT", symbol: "bubble.left.and.bubble.right", windowDuration: 3 * 3600)
    static let gemini = ServicePreset(id: "gemini", name: "Gemini", symbol: "diamond", windowDuration: 24 * 3600)
    static let custom = ServicePreset(id: "custom", name: "Custom", symbol: "slider.horizontal.3", windowDuration: 5 * 3600)

    static let all: [ServicePreset] = [.claude, .chatgpt, .gemini, .custom]

    static func find(_ id: String) -> ServicePreset {
        all.first { $0.id == id } ?? .custom
    }
}
