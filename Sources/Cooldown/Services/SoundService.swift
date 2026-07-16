import AppKit
import UserNotifications

/// Sons de alerta: usa os sons do sistema, copiando o escolhido para
/// ~/Library/Sounds para que a notificação toque mesmo com o app fechado.
enum SoundService {
    static let systemSoundsDir = URL(fileURLWithPath: "/System/Library/Sounds")

    /// Nomes dos sons do sistema disponíveis (sem extensão), ex.: "Glass", "Ping".
    static var availableSounds: [String] = {
        let names = (try? FileManager.default.contentsOfDirectory(at: systemSoundsDir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "aiff" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted() ?? []
        return names.isEmpty ? ["Glass", "Ping", "Hero", "Submarine"] : names
    }()

    static func preview(_ name: String) {
        NSSound(named: name)?.play()
    }

    /// Som para a notificação. Copia o .aiff do sistema para ~/Library/Sounds
    /// (onde o UNUserNotificationCenter procura sons customizados).
    static func notificationSound(named name: String) -> UNNotificationSound {
        let fileName = "\(name).aiff"
        let source = systemSoundsDir.appendingPathComponent(fileName)
        let soundsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Sounds", isDirectory: true)
        let dest = soundsDir.appendingPathComponent(fileName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: dest.path), fm.fileExists(atPath: source.path) {
            try? fm.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            try? fm.copyItem(at: source, to: dest)
        }
        guard fm.fileExists(atPath: dest.path) else { return .default }
        return UNNotificationSound(named: UNNotificationSoundName(fileName))
    }
}
