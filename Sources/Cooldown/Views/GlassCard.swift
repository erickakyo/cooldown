import SwiftUI

/// Cartão com Liquid Glass nativo (macOS 26+) e fallback translúcido
/// (.ultraThinMaterial) nas versões anteriores. Toda a UI usa este
/// componente — o resto do código não conhece a diferença.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(macOS 26.0, *) {
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

/// Botão pequeno estilo "pílula de vidro".
struct GlassPillButtonStyle: ButtonStyle {
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(prominent ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
            )
            .foregroundStyle(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Capsule())
    }
}
