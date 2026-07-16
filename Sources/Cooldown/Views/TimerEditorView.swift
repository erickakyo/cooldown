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
                Picker(l.service, selection: $model.serviceID) {
                    ForEach(ServicePreset.all) { preset in
                        Text(preset.id == "custom" ? l.customName : preset.name).tag(preset.id)
                    }
                }
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
                    Stepper(value: $model.windowHours, in: 0...48) {
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
                Picker("", selection: $model.inputMode) {
                    Text(l.timeRemaining).tag(EditorModel.InputMode.remaining)
                    Text(l.startedAt).tag(EditorModel.InputMode.startedAt)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if model.inputMode == .remaining {
                    HStack {
                        Stepper(value: $model.remainingHours, in: 0...48) {
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

                HStack(spacing: 4) {
                    Image(systemName: "bell")
                    Text(model.computedReset, style: .time)
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var soundAndRepeatSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker(l.sound, selection: $model.soundName) {
                        Text(l.defaultSound).tag(String?.none)
                        ForEach(SoundService.availableSounds, id: \.self) { name in
                            Text(name).tag(String?.some(name))
                        }
                    }
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
