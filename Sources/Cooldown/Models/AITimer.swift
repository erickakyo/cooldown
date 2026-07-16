import Foundation

/// Um timer de cooldown para uma conta de um serviço de IA.
struct AITimer: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var serviceID: String                  // id do ServicePreset ("claude", "custom", ...)
    var serviceName: String                // nome exibido (editável quando custom)
    var accountLabel: String = ""          // ex.: "Pessoal", "Trabalho"
    var windowDuration: TimeInterval       // duração da janela (ex.: 5h)
    var resetDate: Date?                   // quando o limite reseta; nil = parado
    var soundName: String?                 // nil = som padrão das configurações
    var autoRepeat: Bool = false           // re-arma sozinho ao disparar
    /// Marca que o alerta já foi tratado (usuário viu/rearmou) — evita
    /// mostrar "liberado" para timers antigos já resolvidos.
    var acknowledged: Bool = true

    enum State {
        case idle       // sem contagem
        case running    // contando
        case ready      // disparou — IA liberada, aguardando re-arme
    }

    var state: State {
        guard let resetDate else { return .idle }
        if resetDate > Date() { return .running }
        return acknowledged ? .idle : .ready
    }

    var remaining: TimeInterval {
        guard let resetDate else { return 0 }
        return max(0, resetDate.timeIntervalSinceNow)
    }

    var displayName: String {
        accountLabel.isEmpty ? serviceName : "\(serviceName) — \(accountLabel)"
    }

    var symbol: String { ServicePreset.find(serviceID).symbol }

    /// Inicia um novo ciclo completo a partir de agora.
    mutating func rearm(from date: Date = Date()) {
        resetDate = date.addingTimeInterval(windowDuration)
        acknowledged = true
    }

    /// Define a contagem a partir do tempo restante informado.
    mutating func setRemaining(_ interval: TimeInterval) {
        resetDate = Date().addingTimeInterval(interval)
        acknowledged = true
    }

    mutating func stop() {
        resetDate = nil
        acknowledged = true
    }

    static func formatRemaining(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}
