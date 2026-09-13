// Phinbox — Detail View

import SwiftUI

struct DetailView: View {
    let request: PendingRequest
    @ObservedObject var mgr: InboxManager
    @State private var choice: String?
    @State private var boolVal = false
    @State private var textVal = ""
    @State private var intVal = ""
    @State private var dateVal = Date()
    @State private var notes = ""
    @State private var submitting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard; questionCard; formCard; notesCard; actionsRow; errorBanner
            }.padding(32)
        }.background(Color.appBG)
            .onAppear { applyDefaults() }
    }

    // Apply default values from spec on first render
    private func applyDefaults() {
        let f = request.spec.field
        guard let anyDef = f.default else { return }
        if choice == nil, let def = anyDef.value as? String { choice = def }
        if let def = anyDef.value as? Bool { boolVal = def }
        if textVal.isEmpty, let def = anyDef.value as? String { textVal = def }
        if intVal.isEmpty, let def = anyDef.value as? Int { intVal = "\(def)" }
        if let def = anyDef.value as? String {
            let fmt = ISO8601DateFormatter()
            if let d = fmt.date(from: def) { dateVal = d }
        }
    }

    private var headerCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(request.spec.title).font(.largeTitle).bold().foregroundStyle(.white)
                HStack(spacing: 14) {
                    Label(request.origin.process, systemImage: "terminal")
                    Label("on \(request.origin.hostname)", systemImage: "desktopcomputer")
                    Label(mgr.timeAgo(request.queued_at_ms), systemImage: "clock")
                }.font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            badge
        }.padding(24).background(glass)
    }

    private var questionCard: some View {
        Text(request.spec.question).font(.title3).foregroundStyle(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true).padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.06))))
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(request.spec.field.label).font(.headline).foregroundStyle(.white)
            fieldBody
        }.padding(24).background(glass)
    }

    @ViewBuilder
    private var fieldBody: some View {
        let f = request.spec.field
        switch f.kind {
        case "bool":
            Toggle(isOn: $boolVal) { Text(boolVal ? "Yes" : "No").foregroundStyle(.white) }
                .toggleStyle(.switch).tint(Color.teal)
        case "choice": choiceList
        case "text":
            if f.secret == true {
                SecretField(placeholder: f.placeholder ?? "Enter secret...", text: $textVal)
            } else {
                fieldInput(placeholder: f.placeholder ?? "Enter answer...", binding: $textVal, multiline: false, maxLength: f.maxLength)
            }
        case "long_text": fieldInput(placeholder: f.placeholder ?? "Enter answer...", binding: $textVal, multiline: true, maxLength: f.maxLength)
        case "integer": fieldInput(placeholder: f.placeholder ?? "Enter number...", binding: $intVal, multiline: false)
        case "date_time": datePicker
        default: Text("Unsupported field type: \(f.kind)").foregroundStyle(.white.opacity(0.5))
        }
    }

    private var datePicker: some View {
        Group {
            switch request.spec.field.pickerKind {
            case "time":
                DatePicker("Time", selection: $dateVal, displayedComponents: .hourAndMinute).tint(Color.teal)
            case "date":
                DatePicker("Date", selection: $dateVal, displayedComponents: .date).tint(Color.teal)
            default:
                DatePicker("Date & time", selection: $dateVal).tint(Color.teal)
            }
        }.datePickerStyle(.compact).foregroundStyle(.white)
    }

    private var choiceList: some View {
        VStack(spacing: 10) {
            if let opts = request.spec.field.options {
                ForEach(opts, id: \.value) { opt in choiceRow(opt) }
            }
        }
    }

    private func choiceRow(_ opt: ChoiceOption) -> some View {
        Button { withAnimation { choice = opt.value } } label: {
            HStack(spacing: 12) {
                Circle().fill(choice == opt.value ? Color.teal : Color.clear)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(choice == opt.value ? Color.teal : Color.white.opacity(0.3), lineWidth: 2))
                VStack(alignment: .leading, spacing: 2) {
                    Text(opt.label).foregroundStyle(.white)
                    if let d = opt.description { Text(d).font(.caption).foregroundStyle(.white.opacity(0.5)) }
                }
                Spacer()
                if choice == opt.value { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.teal) }
            }.padding(14).background(choiceBg(selected: choice == opt.value))
        }.buttonStyle(.plain)
    }

    private func choiceBg(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(selected ? Color.teal.opacity(0.12) : Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? Color.teal.opacity(0.4) : Color.white.opacity(0.08)))
    }

    @ViewBuilder
    private var notesCard: some View {
        if let ns = request.spec.notes {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(ns.label).font(.headline).foregroundStyle(.white)
                    if ns.required == true { Text("*").foregroundStyle(.red) }
                }
                fieldInput(placeholder: "Optional notes...", binding: $notes, multiline: true)
            }
        }
    }

    private var actionsRow: some View {
        HStack(spacing: 12) {
            Spacer()
            Button(cancelLabel) { withAnimation { mgr.selected = nil } }
                .buttonStyle(.plain).padding(.horizontal, 20).padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.08)).overlay(Capsule().stroke(Color.white.opacity(0.12))))
                .keyboardShortcut(.cancelAction)
            Button(action: send) {
                HStack(spacing: 8) {
                    if submitting { ProgressView().controlSize(.small).tint(.white) }
                    else { Image(systemName: "paperplane.fill") }
                    Text(confirmLabel).fontWeight(.semibold)
                }.foregroundStyle(.white).padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Capsule().fill(Color.teal).shadow(color: Color.teal.opacity(0.4), radius: 8, y: 2))
            }.buttonStyle(.plain).disabled(submitting || !valid).keyboardShortcut(.defaultAction)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let e = mgr.submitError {
            Label(e, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline).foregroundStyle(.red).padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(.red.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.red.opacity(0.25))))
        }
    }

    private var glass: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.1)))
    }

    private var badge: some View {
        Group {
            switch request.spec.urgency {
            case .error: Label("Urgent", systemImage: "exclamationmark.circle.fill").foregroundStyle(.red)
            case .warning: Label("Warning", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            case .secret: Label("Secret", systemImage: "lock.fill").foregroundStyle(.yellow)
            case .info, .none: Label("Info", systemImage: "info.circle.fill").foregroundStyle(Color.teal)
            }
        }.font(.caption).fontWeight(.semibold).padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().stroke(.white.opacity(0.15))))
    }

    private func fieldInput(placeholder: String, binding: Binding<String>, multiline: Bool, maxLength: Int? = nil) -> some View {
        Group {
            if multiline {
                TextEditor(text: binding).scrollContentBackground(.hidden).frame(minHeight: 80, maxHeight: 160).padding(12)
            } else {
                TextField(placeholder, text: binding).textFieldStyle(.plain).padding(12)
            }
        }.background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1))))
            .onChange(of: binding.wrappedValue) { _, new in
                if let mx = maxLength, new.count > mx { binding.wrappedValue = String(new.prefix(mx)) }
            }
    }

    /// SecureField wrapper for secret/password input
    private struct SecretField: View {
        let placeholder: String
        @Binding var text: String
        @State private var visible = false
        var body: some View {
            HStack {
                if visible {
                    TextField(placeholder, text: $text).textFieldStyle(.plain)
                } else {
                    SecureField(placeholder, text: $text).textFieldStyle(.plain)
                }
                Button { visible.toggle() } label: {
                    Image(systemName: visible ? "eye.slash" : "eye").foregroundStyle(.white.opacity(0.5))
                }.buttonStyle(.plain)
            }.padding(12)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1))))
        }
    }

    private var cancelLabel: String { request.spec.button?.cancel ?? "Cancel" }
    private var confirmLabel: String { request.spec.button?.confirm ?? "Submit" }

    private var valid: Bool {
        let f = request.spec.field
        switch f.kind {
        case "choice": return choice != nil
        case "text":
            if f.secret == true { return !textVal.trimmingCharacters(in: .whitespaces).isEmpty }
            return !textVal.trimmingCharacters(in: .whitespaces).isEmpty
        case "long_text": return !textVal.trimmingCharacters(in: .whitespaces).isEmpty
        case "integer": return Int(intVal) != nil
        case "date_time": return true
        default: return true
        }
    }

    private func send() {
        let v: String
        switch request.spec.field.kind {
        case "bool": v = boolVal ? "true" : "false"
        case "choice": v = choice ?? ""
        case "text", "long_text": v = textVal
        case "integer": v = intVal
        case "date_time": v = ISO8601DateFormatter().string(from: dateVal)
        default: v = ""
        }
        submitting = true
        Task { await mgr.submit(request, value: v, notes: notes.isEmpty ? nil : notes); submitting = false }
    }
}
