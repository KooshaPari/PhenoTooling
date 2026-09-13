// Phinbox Inbox Helper — Native SwiftUI with Liquid Glass
// Compiles: swiftc -parse-as-library -o inbox-helper main.swift -framework SwiftUI -framework AppKit

import SwiftUI
import AppKit

// MARK: - Brand

extension Color {
    static let teal = Color(red: 0.494, green: 0.729, blue: 0.710)
    static let appBG = Color(red: 0.075, green: 0.098, blue: 0.145)
}

// MARK: - Models

struct Origin: Decodable, Hashable {
    let hostname: String
    let process: String
    let pid: UInt32
}
struct ChoiceOption: Decodable, Hashable {
    let value: String
    let label: String
    let description: String?
}
struct FieldSpec: Decodable, Hashable {
    let kind: String
    let label: String
    let options: [ChoiceOption]?
}
struct NotesSpec: Decodable, Hashable {
    let label: String
    let required: Bool?
}
struct PromptSpec: Decodable, Hashable {
    let title: String
    let question: String
    let field: FieldSpec
    let notes: NotesSpec?
    let urgency: String?
}
struct PendingRequest: Decodable, Identifiable, Hashable {
    var id: String { request_id }
    let request_id: String
    let origin: Origin
    let spec: PromptSpec
    let queued_at_ms: UInt64
    let expires_at_ms: UInt64
    let state: String
    func hash(into hasher: inout Hasher) { hasher.combine(request_id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.request_id == rhs.request_id }
}

// MARK: - Manager

@MainActor
class InboxManager: ObservableObject {
    @Published var requests: [PendingRequest] = []
    @Published var selected: PendingRequest?
    @Published var submitError: String?
    private let inboxDir: URL
    private var timer: Timer?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        inboxDir = home.appendingPathComponent("Library/Application Support/phinbox/inbox")
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: inboxDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        ) else { requests = []; return }
        var loaded: [PendingRequest] = []
        for f in files where f.pathExtension == "json" {
            guard let data = try? Data(contentsOf: f),
                  let req = try? JSONDecoder().decode(PendingRequest.self, from: data),
                  req.state == "pending" else { continue }
            loaded.append(req)
        }
        let uo = ["error": 0, "warning": 1, "info": 2, "secret": 3]
        loaded.sort { a, b in
            let ua = uo[a.spec.urgency ?? "info"] ?? 2
            let ub = uo[b.spec.urgency ?? "info"] ?? 2
            return ua != ub ? ua < ub : a.queued_at_ms > b.queued_at_ms
        }
        withAnimation(.spring(response: 0.4)) { requests = loaded }
    }

    func submit(_ req: PendingRequest, value: String, notes: String?) async {
        submitError = nil
        var comps = URLComponents(string: "http://127.0.0.1:7117/inbox/\(req.request_id)/answer")!
        var items = [URLQueryItem(name: "value", value: value), URLQueryItem(name: "confirm", value: "ok")]
        if let notes, !notes.isEmpty { items.append(URLQueryItem(name: "notes", value: notes)) }
        comps.queryItems = items
        var r = URLRequest(url: comps.url!); r.httpMethod = "POST"
        do {
            let (_, resp) = try await URLSession.shared.data(for: r)
            if let h = resp as? HTTPURLResponse, h.statusCode == 200 {
                withAnimation { selected = nil }
                try? await Task.sleep(for: .seconds(0.5)); refresh()
            } else { submitError = "Server error" }
        } catch { submitError = error.localizedDescription }
    }

    func timeAgo(_ ms: UInt64) -> String {
        let now = UInt64(Date().timeIntervalSince1970 * 1000)
        guard now > ms else { return "just now" }
        let d = now - ms
        if d < 60_000 { return "\(d/1000)s" }
        if d < 3_600_000 { return "\(d/60_000)m" }
        if d < 86_400_000 { return "\(d/3_600_000)h" }
        return "\(d/86_400_000)d"
    }
}

// MARK: - SwiftUI Views

struct RootView: View {
    @ObservedObject var mgr: InboxManager
    @State private var appeared = false

    var body: some View {
        Group {
            if !appeared {
                splash
            } else {
                mainContent
            }
        }
        .onAppear { appeared = true }
    }

    private var splash: some View {
        ZStack {
            Color(red: 0.075, green: 0.098, blue: 0.145).ignoresSafeArea()
            VStack(spacing: 20) {
                // Teal envelope icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.075, green: 0.098, blue: 0.145))
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.teal.opacity(0.4), lineWidth: 1.5)
                        )
                    envelopeIcon(size: 40)
                }
                Text("Phinbox")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Connecting to daemon...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                ProgressView()
                    .tint(Color.teal)
            }
        }
    }

    private var mainContent: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let r = mgr.selected { DetailView(request: r, mgr: mgr) }
            else {
                VStack(spacing: 16) {
                    envelopeIcon(size: 48).opacity(0.3)
                    Text("Select a request").font(.title3).foregroundStyle(.white.opacity(0.5))
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.appBG)
            }
        }
        .background(Color.appBG.ignoresSafeArea())
        .tint(Color.teal)
    }

    private var sidebar: some View {
        Group {
            if mgr.requests.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    envelopeIcon(size: 48).opacity(0.3)
                    Text("Inbox Empty").font(.title2).fontWeight(.medium).foregroundStyle(.white)
                    Text("Requests from AI agents\nwill appear here.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $mgr.selected) {
                    ForEach(mgr.requests) { RowView(request: $0, mgr: mgr).tag($0) }
                }
                .listStyle(.sidebar).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Inbox")
        .toolbar { ToolbarItem(placement: .automatic) {
            Button { mgr.refresh() } label: { Image(systemName: "arrow.clockwise") }
        }}
    }
}

struct RowView: View {
    let request: PendingRequest
    let mgr: InboxManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: urgencyIcon).font(.system(size: 11)).foregroundStyle(urgencyColor)
                Text(request.spec.title).font(.system(.body, weight: .semibold))
                    .foregroundStyle(.white).lineLimit(1)
                Spacer()
                Text(mgr.timeAgo(request.queued_at_ms)).font(.caption).foregroundStyle(.white.opacity(0.35))
            }
            Text(request.spec.question).font(.subheadline)
                .foregroundStyle(.white.opacity(0.55)).lineLimit(2)
            HStack(spacing: 10) {
                Label(request.origin.process, systemImage: "terminal")
                Label(request.spec.field.kind, systemImage: fieldIcon)
            }.font(.caption).foregroundStyle(.white.opacity(0.35))
        }.padding(.vertical, 6).contentShape(Rectangle())
    }

    private var urgencyColor: Color {
        switch request.spec.urgency {
        case "error": return .red; case "warning": return .orange; case "secret": return .yellow
        default: return Color.teal
        }
    }
    private var urgencyIcon: String {
        switch request.spec.urgency {
        case "error": return "exclamationmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        case "secret": return "lock.fill"; default: return "envelope.fill"
        }
    }
    private var fieldIcon: String {
        switch request.spec.field.kind {
        case "bool": return "switch.2"; case "choice": return "list.bullet"
        case "text", "long_text": return "text.alignleft"; case "integer": return "number"
        case "date_time": return "calendar"; default: return "questionmark.circle"
        }
    }
}

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

// MARK: - Envelope Icon (branded)

struct EnvelopeIcon: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            // Envelope body
            RoundedRectangle(cornerRadius: size * 0.15, style: .continuous)
                .fill(Color.teal.opacity(0.15))
                .frame(width: size, height: size * 0.72)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15, style: .continuous)
                        .stroke(Color.teal.opacity(0.4), lineWidth: max(1, size * 0.03))
                )
            // Flap (V shape using paths)
            Path { p in
                let w = size
                let h = size * 0.72
                let top = -h / 2
                let mid = h * 0.05
                p.move(to: CGPoint(x: -w/2, y: top))
                p.addLine(to: CGPoint(x: 0, y: mid))
                p.addLine(to: CGPoint(x: w/2, y: top))
            }
            .stroke(Color.teal.opacity(0.6), style: StrokeStyle(lineWidth: max(1, size * 0.03), lineCap: .round, linejoin: .round))
            .frame(width: size * 0.9, height: size * 0.72)
        }
    }
}

extension RootView {
    func envelopeIcon(size: CGFloat) -> some View {
        EnvelopeIcon(size: size)
    }
}

// MARK: - Entry Point (no @main, manual NSApplication)

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.setName("Phinbox")

// Load branded app icon from bundle
if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
   let icon = NSImage(contentsOf: iconURL) {
    app.applicationIconImage = icon
}

let manager: InboxManager = MainActor.assumeIsolated { InboxManager() }

let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
let winW = 720.0, winH = 600.0
let winX = screen.midX - winW / 2, winY = screen.midY - winH / 2

let window = NSWindow(
    contentRect: NSRect(x: winX, y: winY, width: winW, height: winH),
    styleMask: [.titled, .closable, .miniaturizable, .resizable],
    backing: .buffered, defer: false
)
window.title = "Phinbox"
window.minSize = NSSize(width: 520, height: 400)
window.isReleasedWhenClosed = false
window.titlebarAppearsTransparent = false
window.titleVisibility = .visible
window.isMovableByWindowBackground = true
// Set window icon from bundle resource
if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
   let icon = NSImage(contentsOf: iconURL) {
    icon.size = NSSize(width: 16, height: 16)
    window.contentView?.window?.standardWindowButton(.documentIconButton)?.image = icon
}

let hosting = NSHostingView(rootView: RootView(mgr: manager))
hosting.translatesAutoresizingMaskIntoConstraints = false
window.contentView = hosting
if let cv = window.contentView {
    NSLayoutConstraint.activate([
        hosting.topAnchor.constraint(equalTo: cv.topAnchor),
        hosting.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
        hosting.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
        hosting.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
    ])
}

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)
MainActor.assumeIsolated { manager.start() }

// SIGUSR1 handler — bring window to front from tray
signal(30, SIG_IGN)
let sigSrc = DispatchSource.makeSignalSource(signal: 30, queue: .main)
sigSrc.setEventHandler {
    app.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
}
sigSrc.resume()

// Menu bar
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(withTitle: "About Phinbox", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
appMenu.addItem(NSMenuItem.separator())
appMenu.addItem(withTitle: "Quit Phinbox", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenuItem.submenu = appMenu

let editMenuItem = NSMenuItem()
mainMenu.addItem(editMenuItem)
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
editMenu.addItem(NSMenuItem.separator())
editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
editMenuItem.submenu = editMenu

let viewMenuItem = NSMenuItem()
mainMenu.addItem(viewMenuItem)
let viewMenu = NSMenu(title: "View")
viewMenuItem.submenu = viewMenu

app.mainMenu = mainMenu
app.run()
