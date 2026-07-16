import SwiftUI

/// Estado do editor. (Classe em vez de @State porque o plugin de macros
/// do SwiftUI não existe nas Command Line Tools.)
final class EditorModel: ObservableObject {
    enum InputMode: Hashable { case remaining, startedAt }

    @Published var serviceID = ServicePreset.claude.id
    @Published var customName = ""
    @Published var accountLabel = ""
    @Published var inputMode: InputMode = .remaining
    @Published var remainingHours = 2
    @Published var remainingMinutes = 30
    @Published var startedAt = Date()
    @Published var windowHours = 5
    @Published var windowMinutes = 0
    @Published var soundName: String? = nil
    @Published var autoRepeat = false

    var windowDuration: TimeInterval {
        TimeInterval(windowHours * 3600 + windowMinutes * 60)
    }

    var windowShort: String {
        windowMinutes == 0 ? "\(windowHours)h" : "\(windowHours)h\(windowMinutes)"
    }

    var computedReset: Date {
        switch inputMode {
        case .remaining:
            return Date().addingTimeInterval(TimeInterval(remainingHours * 3600 + remainingMinutes * 60))
        case .startedAt:
            // Horário de hoje; se ficou no futuro, o usuário quis dizer "mais cedo".
            var start = startedAt
            if start > Date() { start = start.addingTimeInterval(-86400) }
            return start.addingTimeInterval(windowDuration)
        }
    }

    var isValid: Bool {
        guard windowDuration > 0, computedReset > Date() else { return false }
        if serviceID == "custom" && customName.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        return true
    }

    func prefill(from timer: AITimer) {
        serviceID = timer.serviceID
        if timer.serviceID == "custom" { customName = timer.serviceName }
        accountLabel = timer.accountLabel
        windowHours = Int(timer.windowDuration) / 3600
        windowMinutes = (Int(timer.windowDuration) % 3600) / 60
        soundName = timer.soundName
        autoRepeat = timer.autoRepeat
        if timer.state == .running {
            let remaining = Int(timer.remaining)
            remainingHours = remaining / 3600
            remainingMinutes = (remaining % 3600) / 60
        }
    }
}

/// Criação/edição de um timer: serviço, conta, tempo restante e som.
struct TimerEditorView: View {
    @EnvironmentObject var store: TimerStore
    @EnvironmentObject var settings: AppSettings
    @StateObject private var model = EditorModel()

    let editing: AITimer?
    var onDone: () -> Void

    private var l: L { L(settings.language) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                serviceSection
                timeSection
                soundAndRepeatSection
                buttons
            }
            .padding(14)
        }
        .onAppear {
            if let timer = editing { model.prefill(from: timer) }
        }
    }

    // MARK: - Sections

    private var serviceSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                PillPicker(
                    title: l.service,
                    selection: $model.serviceID,
                    options: ServicePreset.all.map {
                        ($0.id, $0.id == "custom" ? l.customName : $0.name)
                    }
                )
                .onChange(of: model.serviceID) { _, newValue in
                    let preset = ServicePreset.find(newValue)
                    model.windowHours = Int(preset.windowDuration) / 3600
                    model.windowMinutes = (Int(preset.windowDuration) % 3600) / 60
                }

                if model.serviceID == "custom" {
                    TextField(l.customName, text: $model.customName)
                        .textFieldStyle(.roundedBorder)
                }

                TextField(l.accountOptional, text: $model.accountLabel)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text(l.windowLabel)
                    Spacer()
                    // Até 168h (1 semana) — cobre limites semanais como o do Codex.
                    Stepper(value: $model.windowHours, in: 0...168) {
                        Text("\(model.windowHours)\(l.hoursShort)").monospacedDigit()
                    }
                    Stepper(value: $model.windowMinutes, in: 0...59, step: 5) {
                        Text("\(model.windowMinutes)\(l.minutesShort)").monospacedDigit()
                    }
                }
                .font(.callout)
            }
        }
    }

    private var timeSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                PillSegmented(
                    selection: $model.inputMode,
                    options: [
                        (EditorModel.InputMode.remaining, l.timeRemaining),
                        (EditorModel.InputMode.startedAt, l.startedAt),
                    ]
                )

                if model.inputMode == .remaining {
                    HStack {
                        Stepper(value: $model.remainingHours, in: 0...168) {
                            Text("\(model.remainingHours)\(l.hoursShort)").monospacedDigit()
                        }
                        Stepper(value: $model.remainingMinutes, in: 0...59) {
                            Text("\(model.remainingMinutes)\(l.minutesShort)").monospacedDigit()
                        }
                        Spacer()
                    }
                    .font(.callout)
                } else {
                    DatePicker("", selection: $model.startedAt, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                Button(l.justStarted(model.windowShort)) {
                    model.inputMode = .remaining
                    model.remainingHours = model.windowHours
                    model.remainingMinutes = model.windowMinutes
                }
                .buttonStyle(GlassPillButtonStyle())

                // Horário do alerta rotulado — sem rótulo os usuários confundem
                // com a duração configurada.
                HStack(spacing: 5) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.tint)
                    Text("\(l.alertAt) ")
                        + Text(model.computedReset, style: .time).fontWeight(.semibold)
                }
                .font(.callout)
                .monospacedDigit()
            }
        }
    }

    private var soundAndRepeatSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    PillPicker(
                        title: l.sound,
                        selection: $model.soundName,
                        options: [(String?.none, l.defaultSound)]
                            + SoundService.availableSounds.map { (String?.some($0), $0) }
                    )
                    Button {
                        SoundService.preview(model.soundName ?? settings.defaultSoundName)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.plain)
                }

                Toggle(l.autoRepeat, isOn: $model.autoRepeat)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                if model.autoRepeat {
                    Text(l.autoRepeatWarning)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var buttons: some View {
        HStack {
            Spacer()
            Button(l.cancel, action: onDone)
                .buttonStyle(GlassPillButtonStyle())
                .keyboardShortcut(.cancelAction)
            Button(editing == nil ? l.create : l.save, action: saveTimer)
                .buttonStyle(GlassPillButtonStyle(prominent: true))
                .keyboardShortcut(.defaultAction)
                .disabled(!model.isValid)
        }
    }

    // MARK: - Logic

    private func saveTimer() {
        let preset = ServicePreset.find(model.serviceID)
        let name = model.serviceID == "custom"
            ? model.customName.trimmingCharacters(in: .whitespaces)
            : preset.name

        var timer = editing ?? AITimer(serviceID: model.serviceID, serviceName: name, windowDuration: model.windowDuration)
        timer.serviceID = model.serviceID
        timer.serviceName = name
        timer.accountLabel = model.accountLabel.trimmingCharacters(in: .whitespaces)
        timer.windowDuration = model.windowDuration
        timer.soundName = model.soundName
        timer.autoRepeat = model.autoRepeat
        timer.resetDate = model.computedReset
        timer.acknowledged = true

        if editing == nil {
            store.add(timer)
        } else {
            store.update(timer)
        }
        onDone()
    }
}
