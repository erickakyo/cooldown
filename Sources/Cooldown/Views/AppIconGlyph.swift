import SwiftUI

/// Miniatura do ícone real do app (carregado do bundle) para usar dentro do popover.
struct AppIconGlyph: View {
    var size: CGFloat = 44

    var body: some View {
        // NSImage.applicationIconName depende do cache de ícone do
        // LaunchServices, que não é populado para um app.bundle rodando
        // fora de /Applications (ou nunca indexado pelo Finder/LS) — nesse
        // caso ele retorna nil ou o ícone genérico. Carregar o PNG direto
        // dos recursos do bundle é a mesma técnica robusta já usada pelo
        // AppLogoView e não depende de LS.
        if let path = Bundle.main.path(forResource: "Cooldown---Logo-circle", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else if let icon = NSImage(named: NSImage.applicationIconName) {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Fallback em caso de erro
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.65, blue: 0.95),
                            Color(red: 0.08, green: 0.25, blue: 0.65),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "snowflake")
                        .font(.system(size: size * 0.52, weight: .medium))
                        .foregroundStyle(.white)
                )
        }
    }
}

/// Logo em formato circular para os títulos das janelas e telas internas.
struct AppLogoView: View {
    var size: CGFloat = 20

    var body: some View {
        if let path = Bundle.main.path(forResource: "Cooldown---Logo-circle", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Fallback
            AppIconGlyph(size: size)
        }
    }
}

/// Ícone do serviço de IA, carregando PNG da pasta de resources ou caindo de volta para SF Symbol.
struct ServiceIconView: View {
    let serviceID: String
    let fallbackSymbol: String
    var size: CGFloat = 16

    var body: some View {
        if let path = resourcePath(for: serviceID),
           let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(.primary)
        } else {
            Image(systemName: fallbackSymbol)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(.primary)
        }
    }

    private func resourcePath(for id: String) -> String? {
        switch id {
        case "claude": return Bundle.main.path(forResource: "claude", ofType: "png")
        case "chatgpt": return Bundle.main.path(forResource: "chatgpt", ofType: "png")
        case "gemini": return Bundle.main.path(forResource: "gemini", ofType: "png")
        case "codex": return Bundle.main.path(forResource: "codex", ofType: "png")
        case "antigravity": return Bundle.main.path(forResource: "antigravity", ofType: "png")
        case "custom": return Bundle.main.path(forResource: "icon-flat", ofType: "png")
        default: return nil
        }
    }
}
