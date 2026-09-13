// Phinbox — Detail View

import SwiftUI

struct DetailView: View {
    let request: PendingRequest
    @ObservedObject var mgr: InboxManager
    @State private var choice: String?
    @State private var boolVal = false
    @State private var textVal = ""
    @State private var intVal = ""
    @State private var notes = ""
    @State private var submitting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard; questionCard; formCard; notesCard; actionsRow; errorBanner
            }.padding(32)
        }.background(Color.appBG)
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
        switch request.spec.field.kind {
        case "bool":
            Toggle(isOn: $boolVal) { Text(boolVal ? "Yes" : "No").foregroundStyle(.white) }
                .toggleStyle(.switch).tint(Color.teal)
        case "choice": choiceList
        case "text": fieldInput(placeholder: "Enter answer...", binding: $textVal, multiline: false)
        case "long_text": fieldInput(placeholder: "Enter answer...", binding: $textVal, multiline: true)
        case "integer": fieldInput(placeholder: "Enter number...", binding: $intVal, multiline: false)
        case "date_time":
            DatePicker("Date & time", selection: .constant(Date())).datePickerStyle(.compact).tint(Color.teal)
        default: Text("Unknown field type").foregroundStyle(.white.opacity(0.5))
        }
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
            Button("Cancel") { withAnimation { mgr.selected = nil } }
                .buttonStyle(.plain).padding(.horizontal, 20).padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.08)).overlay(Capsule().stroke(Color.white.opacity(0.12))))
                .keyboardShortcut(.cancelAction)
            Button(action: send) {
                HStack(spacing: 8) {
                    if submitting { ProgressView().controlSize(.small).tint(.white) }
                    else { Image(systemName: "paperplane.fill") }
                    Text("Submit").fontWeight(.semibold)
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
            case "error": Label("Urgent", systemImage: "exclamationmark.circle.fill").foregroundStyle(.red)
            case "warning": Label("Warning", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            case "secret": Label("Secret", systemImage: "lock.fill").foregroundStyle(.yellow)
            default: Label("Info", systemImage: "info.circle.fill").foregroundStyle(Color.teal)
            }
        }.font(.caption).fontWeight(.semibold).padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().stroke(.white.opacity(0.15))))
    }

    private func fieldInput(placeholder: String, binding: Binding<String>, multiline: Bool) -> some View {
        Group {
            if multiline {
                TextEditor(text: binding).scrollContentBackground(.hidden).frame(minHeight: 80, maxHeight: 160).padding(12)
            } else {
                TextField(placeholder, text: binding).textFieldStyle(.plain).padding(12)
            }
        }.background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1))))
    }

    private var valid: Bool {
        switch request.spec.field.kind {
        case "choice": return choice != nil
        case "text", "long_text": return !textVal.trimmingCharacters(in: .whitespaces).isEmpty
        case "integer": return Int(intVal) != nil
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
        default: v = ISO8601DateFormatter().string(from: Date())
        }
        submitting = true
        Task { await mgr.submit(request, value: v, notes: notes.isEmpty ? nil : notes); submitting = false }
    }
}
