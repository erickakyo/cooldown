import Foundation
import UserNotifications

/// Agenda notificações locais — disparam mesmo com o app fechado.
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    static let categoryID = "COOLDOWN_TIMER_FIRED"
    static let rearmActionID = "COOLDOWN_REARM"

    /// Chamado pelo delegate quando o usuário toca "Comecei agora" na notificação.
    var onRearmRequested: ((UUID) -> Void)?

    /// UNUserNotificationCenter exige rodar dentro de um bundle .app —
    /// em `swift run` direto, desabilita notificações sem crashar.
    private var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    func setup(language: AppLanguage) {
        guard isAvailable else { return }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        updateCategories(language: language)
    }

    func updateCategories(language: AppLanguage) {
        guard isAvailable else { return }
        let rearm = UNNotificationAction(
            identifier: Self.rearmActionID,
            title: L(language).notificationRearm,
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [rearm],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func schedule(for timer: AITimer, defaultSound: String, language: AppLanguage) {
        guard isAvailable, let resetDate = timer.resetDate, resetDate > Date() else { return }
        let l = L(language)
        let content = UNMutableNotificationContent()
        content.title = l.notificationTitle(timer.displayName)
        content.body = l.notificationBody
        content.sound = SoundService.notificationSound(named: timer.soundName ?? defaultSound)
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["timerID": timer.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, resetDate.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: timer.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancel(timerID: UUID) {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerID.uuidString])
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostra banner + som mesmo com o app em primeiro plano.
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let isRearm = response.actionIdentifier == Self.rearmActionID
        if isRearm, let idString = userInfo["timerID"] as? String, let id = UUID(uuidString: idString) {
            Task { @MainActor in
                NotificationService.shared.onRearmRequested?(id)
            }
        }
        completionHandler()
    }
}
