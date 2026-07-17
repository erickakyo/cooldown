import SwiftUI

/// Miniatura do ícone do app (mesmo gradiente azul-gelo + floco de neve
/// gerado em scripts/make_icon.swift), para usar dentro do popover em vez
/// de SF Symbols genéricos — reforça a identidade visual na tela Sobre.
struct AppIconGlyph: View {
    var size: CGFloat = 44

    var body: some View {
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
