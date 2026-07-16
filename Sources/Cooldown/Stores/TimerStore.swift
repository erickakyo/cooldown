import SwiftUI
import Combine

/// Fonte de verdade dos timers: persistência, tick de 1s e agendamento de alertas.
@MainActor
final class TimerStore: ObservableObject {
    @Published private(set) var timers: [AITimer] = []
    let settings: AppSettings

    static let defaultsKey = "cooldown.timers"

    private var ticker: AnyCancellable?
    private var settingsObserver: AnyCancellable?

    init(settings: AppSettings) {
        self.settings = settings
        load()

        // Tick de 1s para atualizar countdowns e detectar disparos com o app aberto.
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }

        settingsObserver = settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.settings.save() }
        }

        NotificationService.shared.onRearmRequested = { [weak self] id in
            self?.rearm(id: id)
        }
    }

    /// Timer mais próximo de disparar (para a contagem na barra de menus).
    var nextRunning: AITimer? {
        timers
            .filter { $0.state == .running }
            .min { ($0.resetDate ?? .distantFuture) < ($1.resetDate ?? .distantFuture) }
    }

    var menuBarText: String? {
        guard settings.showCountdownInMenuBar, let next = nextRunning else { return nil }
        return AITimer.formatRemaining(next.remaining)
    }

    // MARK: - Mutations

    func add(_ timer: AITimer) {
        timers.append(timer)
        scheduleAlert(for: timer)
        save()
    }

    func update(_ timer: AITimer) {
        guard let idx = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        timers[idx] = timer
        NotificationService.shared.cancel(timerID: timer.id)
        scheduleAlert(for: timer)
        save()
    }

    func remove(id: UUID) {
        NotificationService.shared.cancel(timerID: id)
        timers.removeAll { $0.id == id }
        save()
    }

    /// Re-arma um ciclo completo a partir de agora ("Comecei agora").
    func rearm(id: UUID) {
        guard let idx = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[idx].rearm()
        scheduleAlert(for: timers[idx])
        save()
    }

    /// Marca o "Liberado!" como visto, sem iniciar novo ciclo.
    func acknowledge(id: UUID) {
        guard let idx = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[idx].acknowledged = true
        timers[idx].resetDate = nil
        save()
    }

    func stop(id: UUID) {
        guard let idx = timers.firstIndex(where: { $0.id == id }) else { return }
        NotificationService.shared.cancel(timerID: id)
        timers[idx].stop()
        save()
    }

    // MARK: - Tick

    private func tick() {
        var changed = false
        for idx in timers.indices {
            let t = timers[idx]
            guard let reset = t.resetDate, t.acknowledged, reset <= Date() else { continue }
            // Disparou agora (com o app aberto): a notificação agendada cuida
            // do som/banner; aqui só atualizamos o estado.
            if t.autoRepeat {
                // Re-arma a partir do horário do disparo para não acumular atraso.
                timers[idx].resetDate = reset.addingTimeInterval(t.windowDuration)
                timers[idx].acknowledged = true
                scheduleAlert(for: timers[idx])
            } else {
                timers[idx].acknowledged = false   // estado "Liberado!" aguardando re-arme
            }
            changed = true
        }
        if changed { save() }
        // Publica para as views atualizarem countdowns a cada segundo.
        objectWillChange.send()
    }

    // MARK: - Persistence

    private func scheduleAlert(for timer: AITimer) {
        NotificationService.shared.schedule(
            for: timer,
            defaultSound: settings.defaultSoundName,
            language: settings.language
        )
    }

    private func save() {
        if let data = try? JSONEncoder().encode(timers) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let saved = try? JSONDecoder().decode([AITimer].self, from: data)
        else { return }
        timers = saved
        // Timers que venceram com o app fechado: a notificação do sistema já
        // disparou; aqui só refletimos o estado "Liberado!".
        var changed = false
        for idx in timers.indices {
            if let reset = timers[idx].resetDate, reset <= Date(), timers[idx].acknowledged {
                if timers[idx].autoRepeat {
                    timers[idx].rearm()
                    scheduleAlert(for: timers[idx])
                } else {
                    timers[idx].acknowledged = false
                }
                changed = true
            }
        }
        if changed { save() }
    }
}
