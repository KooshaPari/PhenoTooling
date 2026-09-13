// Phinbox — Inbox Manager

import Foundation
import SwiftUI

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
