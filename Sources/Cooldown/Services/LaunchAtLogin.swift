import Foundation
import ServiceManagement

/// "Iniciar com o sistema" via SMAppService (macOS 13+).
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            // Falha comum: app rodando fora de /Applications ou sem assinatura válida.
            NSLog("LaunchAtLogin error: \(error.localizedDescription)")
            return false
        }
    }
}
