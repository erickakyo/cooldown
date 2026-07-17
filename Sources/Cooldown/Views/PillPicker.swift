import SwiftUI

/// Só o menu em formato de pílula, sem rótulo — para linhas que já têm o
/// próprio título (ex.: SettingsView no estilo Ajustes do Sistema).
struct PillMenu<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String)]

    var body: some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button {
                    selection = option.value
                } label: {
                    if option.value == selection {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
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
}

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
