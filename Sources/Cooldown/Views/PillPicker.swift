import SwiftUI

/// Só o menu em formato de pílula, sem rótulo — para linhas que já têm o
/// próprio título (ex.: SettingsView no estilo Ajustes do Sistema).
struct PillMenu<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String)]
    /// Emoji opcional (ex.: bandeira) mostrado antes do rótulo selecionado.
    var glyph: ((T) -> String)? = nil

    var body: some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button {
                    selection = option.value
                } label: {
                    let text = glyph.map { "\($0(option.value)) \(option.label)" } ?? option.label
                    if option.value == selection {
                        Label(text, systemImage: "checkmark")
                    } else {
                        Text(text)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                if let glyph {
                    // Emoji como bitmap: o vibrancy do vidro dessatura texto
                    // (inclusive emoji, mesmo com .compositingGroup()), mas
                    // não imagens não-template — mantém a cor original da
                    // bandeira nos dois modos.
                    Image(nsImage: Self.emojiImage(glyph(selection)))
                }
                Text(currentLabel)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .font(.callout.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(.quaternary))
            .contentShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var currentLabel: String {
        options.first { $0.value == selection }?.label ?? ""
    }

    private static func emojiImage(_ emoji: String) -> NSImage {
        if let cached = emojiImageCache[emoji] { return cached }
        let str = NSAttributedString(string: emoji, attributes: [
            .font: NSFont.systemFont(ofSize: 13)
        ])
        let size = str.size()
        let image = NSImage(size: size)
        image.lockFocus()
        str.draw(at: .zero)
        image.unlockFocus()
        emojiImageCache[emoji] = image
        return image
    }
}

private var emojiImageCache: [String: NSImage] = [:]

/// Seletor em formato de pílula, substituindo o Picker nativo — os pop-ups
/// do sistema ficam ilegíveis (texto branco sobre vidro claro) no macOS 26.
struct PillPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [(value: T, label: String)]

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            PillMenu(selection: $selection, options: options)
        }
    }
}

/// Segmentado custom (dois estados) — o segmentado nativo também sofre de
/// baixo contraste sobre o vidro.
struct PillSegmented<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String)]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.value) { option in
                Button {
                    selection = option.value
                } label: {
                    Text(option.label)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassPillButtonStyle(prominent: option.value == selection))
            }
        }
    }
}
