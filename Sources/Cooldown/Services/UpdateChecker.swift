import AppKit
import Foundation

/// Checa a última release no GitHub e avisa se há versão nova.
/// (Simples e sem dependências; pode ser trocado por Sparkle no futuro.)
@MainActor
final class UpdateChecker: ObservableObject {
    enum Status: Equatable {
        case idle, checking, upToDate
        case available(version: String)
        case failed
    }

    @Published var status: Status = .idle
    private var periodicTimer: Timer?

    /// Re-checa em intervalos enquanto o app está aberto — apps de barra de
    /// menus com "iniciar com o sistema" podem ficar semanas sem relançar,
    /// e a checagem só na inicialização deixaria o aviso pra trás.
    func startPeriodicChecks(every interval: TimeInterval = 24 * 3600) {
        periodicTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
        timer.tolerance = interval * 0.1
        periodicTimer = timer
    }

    /// Abre a página de download e encerra o app: com o Cooldown aberto, o
    /// Finder recusa substituir o bundle em /Applications ("item em uso").
    func openDownloadPageAndQuit() {
        NSWorkspace.shared.open(AppConfig.releasesPageURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NSApp.terminate(nil)
        }
    }

    func check() {
        status = .checking
        Task {
            do {
                var request = URLRequest(url: AppConfig.latestReleaseAPI)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag = json["tag_name"] as? String
                else {
                    status = .failed
                    return
                }
                let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                status = Self.isNewer(latest, than: AppConfig.version)
                    ? .available(version: latest)
                    : .upToDate
            } catch {
                status = .failed
            }
        }
    }

    /// Compara versões semver simples ("1.2.0" > "1.1.9").
    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
