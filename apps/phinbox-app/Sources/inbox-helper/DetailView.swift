// Phinbox — Detail View

import SwiftUI

struct DetailView: View {
    let request: PendingRequest
    @ObservedObject var mgr: InboxManager

    @State private var textVal = ""
    @State private var intVal = ""
    @State private var boolVal = false
    @State private var dateVal = Date()
    @State private var choice: String?
    @State private var notes = ""
    @State private var submitting = false
    @State private var remainingSeconds: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard
                questionCard
                formCard
                notesCard
                actionsRow
                errorBanner
            }
            .padding(32)
        }
        .background(Color.appBG)
        .onAppear { loadDefaults(); updateRemaining() }
        .onReceive(timer) { _ in updateRemaining() }
    }

    // MARK: - Initialize state from field defaults

    private func loadDefaults() {
        switch request.spec.field {
        case .text(_, let def, _, _, _, _):
            textVal = def ?? ""
        case .longText(_, let def, _):
            textVal = def ?? ""
        case .integer(_, _, _, let def):
            intVal = def.map(String.init) ?? ""
        case .boolean(_, let def):
            boolVal = def ?? false
        case .choice(_, let opts, let defaultIndex):
            if let idx = defaultIndex, idx >= 0, idx < opts.count {
                choice = opts[idx].value
            }
        case .dateTime(_, let def, _):
            if let def, let parsed = Self.rfc3339Date(def) {
                dateVal = parsed
            }
        case .unknown:
            break
        }
    }

    private func updateRemaining() {
        let now = UInt64(Date().timeIntervalSince1970 * 1000)
        if request.expires_at_ms <= now {
            remainingSeconds = 0
        } else {
            remainingSeconds = Int((request.expires_at_ms - now) / 1000)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(request.spec.title)
                    .font(.largeTitle).bold().foregroundStyle(.white)
                HStack(spacing: 14) {
                    Label(request.origin.process, systemImage: "terminal")
                    Label("on \(request.origin.hostname)", systemImage: "desktopcomputer")
                    Label(mgr.timeAgo(request.queued_at_ms), systemImage: "clock")
                }
                .font(.caption).foregroundStyle(.white.opacity(0.5))
                .textSelection(.enabled)
            }
            Spacer()
            if remainingSeconds > 0 {
                let mins = remainingSeconds / 60
                let secs = remainingSeconds % 60
                Text(String(format: "%d:%02d", mins, secs))
                    .font(.caption).fontWeight(.semibold).monospacedDigit()
                    .foregroundStyle(remainingSeconds < 30 ? .red : .white.opacity(0.7))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(remainingSeconds < 30 ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(remainingSeconds < 30 ? Color.red.opacity(0.3) : Color.white.opacity(0.12))))
            } else if request.expires_at_ms > 0 {
                Text("Expired").font(.caption).foregroundStyle(.red.opacity(0.7))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color.red.opacity(0.1)))
            }
            badge
        }
        .padding(24).background(glass)
    }

    // MARK: - Question

    private var questionCard: some View {
        Text(request.spec.question)
            .font(.title3).foregroundStyle(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.06)))
            )
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(request.spec.field.labelText)
                .font(.headline).foregroundStyle(.white)
            fieldBody
        }
        .padding(24).background(glass)
    }

    // MARK: - Field Body (enum-based)

    @ViewBuilder
    private var fieldBody: some View {
        switch request.spec.field {
        case .boolean(_, _):
            Toggle(isOn: $boolVal) {
                Text(boolVal ? "Yes" : "No").foregroundStyle(.white)
            }
            .toggleStyle(.switch).tint(Color.teal)

        case .choice(_, let opts, _):
            choiceList(opts)

        case .text(_, _, let placeholder, let maxLen, let secret, _):
            if secret == true {
                secretField(placeholder: placeholder ?? "Enter answer...")
            } else {
                fieldInput(placeholder: placeholder ?? "Enter answer...",
                           binding: $textVal, multiline: false, maxLength: maxLen)
            }

        case .longText(_, _, let maxLen):
            fieldInput(placeholder: "Enter answer...",
                       binding: $textVal, multiline: true, maxLength: maxLen)

        case .integer(_, _, _, _):
            fieldInput(placeholder: "Enter number...",
                       binding: $intVal, multiline: false, maxLength: nil)

        case .dateTime(_, _, let pickerKind):
            datePicker(kind: pickerKind)

        case .unknown(_, let kind):
            Text("Unsupported field type: \(kind)")
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Secret field

    private func secretField(placeholder: String) -> some View {
        SecureField(placeholder, text: $textVal)
            .textFieldStyle(.plain).padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.1)))
            )
    }

    // MARK: - Date Picker

    @ViewBuilder
    private func datePicker(kind: String?) -> some View {
        let kind = kind ?? "datetime"
        switch kind {
        case "date":
            DatePicker("Date", selection: $dateVal, displayedComponents: .date)
                .datePickerStyle(.compact).tint(Color.teal)
        case "time":
            DatePicker("Time", selection: $dateVal, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact).tint(Color.teal)
        case "datetime", "composite", _:
            DatePicker("Date & time", selection: $dateVal, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact).tint(Color.teal)
        }
    }

    private func datePickerComponents(_ kind: String?) -> DatePickerComponents {
        switch kind {
        case "date":  return [.date]
        case "time":  return [.hourAndMinute]
        default:      return [.date, .hourAndMinute]
        }
    }

    // MARK: - Choice list

    private func choiceList(_ opts: [ChoiceOption]) -> some View {
        VStack(spacing: 10) {
            ForEach(opts, id: \.value) { opt in choiceRow(opt) }
        }
    }

    private func choiceRow(_ opt: ChoiceOption) -> some View {
        Button { withAnimation { choice = opt.value } } label: {
            HStack(spacing: 12) {
                Circle().fill(choice == opt.value ? Color.teal : Color.clear)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(
                        choice == opt.value ? Color.teal : Color.white.opacity(0.3), lineWidth: 2))
                VStack(alignment: .leading, spacing: 2) {
                    Text(opt.label).foregroundStyle(.white)
                    if let d = opt.description {
                        Text(d).font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                }
                Spacer()
                if choice == opt.value {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.teal)
                }
            }
            .padding(14)
            .background(choiceBg(selected: choice == opt.value))
        }
        .buttonStyle(.plain)
    }

    private func choiceBg(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(selected ? Color.teal.opacity(0.12) : Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? Color.teal.opacity(0.4) : Color.white.opacity(0.08)))
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesCard: some View {
        if let ns = request.spec.notes {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(ns.label).font(.headline).foregroundStyle(.white)
                    if ns.required == true { Text("*").foregroundStyle(.red) }
                }
                fieldInput(placeholder: "Optional notes...", binding: $notes, multiline: true, maxLength: nil)
            }
        }
    }

    // MARK: - Actions

    private var actionsRow: some View {
        let buttons = request.spec.buttons
        let cancelLabel = buttons?.cancel ?? "Cancel"
        let confirmLabel = buttons?.confirm ?? "Submit"
        let cancelIsDefault = buttons?.default_is_cancel ?? false

        return HStack(spacing: 12) {
            Spacer()
            // Cancel button
            Button(cancelLabel) {
                withAnimation { mgr.selected = nil }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.08))
                .overlay(Capsule().stroke(Color.white.opacity(0.12))))
            .keyboardShortcut(cancelIsDefault ? .defaultAction : .cancelAction)

            // Confirm / Submit button
            Button(action: send) {
                HStack(spacing: 8) {
                    if submitting {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(confirmLabel).fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(Color.teal)
                    .shadow(color: Color.teal.opacity(0.4), radius: 8, y: 2))
            }
            .buttonStyle(.plain)
            .disabled(submitting || !valid)
            .keyboardShortcut(cancelIsDefault ? .cancelAction : .defaultAction)
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
        if let e = mgr.submitError {
            Label(e, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline).foregroundStyle(.red)
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(.red.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.red.opacity(0.25)))
                )
        }
    }

    // MARK: - Helpers

    private var glass: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1)))
    }

    private var badge: some View {
        Group {
            switch request.spec.urgency {
            case .error:
                Label("Urgent", systemImage: "exclamationmark.circle.fill").foregroundStyle(.red)
            case .warning:
                Label("Warning", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            case .secret:
                Label("Secret", systemImage: "lock.fill").foregroundStyle(.yellow)
            case .info, .none:
                Label("Info", systemImage: "info.circle.fill").foregroundStyle(Color.teal)
            }
        }
        .font(.caption).fontWeight(.semibold)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(.ultraThinMaterial)
            .overlay(Capsule().stroke(.white.opacity(0.15))))
    }

    private func fieldInput(placeholder: String, binding: Binding<String>,
                            multiline: Bool, maxLength: Int?) -> some View {
        Group {
            if multiline {
                TextEditor(text: binding)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 160).padding(12)
            } else {
                TextField(placeholder, text: binding)
                    .textFieldStyle(.plain).padding(12)
            }
        }
        .modifier(MaxLengthModifier(text: binding, maxLength: maxLength))
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.1)))
        )
    }

    // MARK: - Validation

    private var valid: Bool {
        switch request.spec.field {
        case .choice(_, _, _):
            return choice != nil

        case .text(_, _, _, _, let secret, _):
            if secret == true { return !textVal.isEmpty }
            return !textVal.trimmingCharacters(in: .whitespaces).isEmpty

        case .longText(_, _, _):
            return !textVal.trimmingCharacters(in: .whitespaces).isEmpty

        case .integer(_, let min, let max, _):
            guard let v = Int(intVal) else { return false }
            if let mn = min, v < mn { return false }
            if let mx = max, v > mx { return false }
            return true

        case .dateTime:
            return true

        case .boolean:
            return true

        case .unknown:
            return true
        }
    }

    // MARK: - Submit

    private func send() {
        let v: String
        switch request.spec.field {
        case .boolean:
            v = boolVal ? "true" : "false"
        case .choice(_, _, _):
            v = choice ?? ""
        case .text:
            v = textVal
        case .longText:
            v = textVal
        case .integer:
            v = intVal
        case .dateTime:
            v = ISO8601DateFormatter().string(from: dateVal)
        case .unknown:
            v = ""
        }

        submitting = true
        Task {
            await mgr.submit(request, value: v, notes: notes.isEmpty ? nil : notes)
            submitting = false
        }
    }

    // MARK: - Utilities

    private static let rfc3339: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let rfc3339NoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func rfc3339Date(_ str: String) -> Date? {
        rfc3339.date(from: str) ?? rfc3339NoFractional.date(from: str)
    }
}

// MARK: - MaxLength modifier

private struct MaxLengthModifier: ViewModifier {
    let text: Binding<String>
    let maxLength: Int?

    func body(content: Content) -> some View {
        if let limit = maxLength {
            content
                .onChange(of: text.wrappedValue) { _, new in
                    if new.count > limit {
                        text.wrappedValue = String(new.prefix(limit))
                    }
                }
        } else {
            content
        }
    }
}
