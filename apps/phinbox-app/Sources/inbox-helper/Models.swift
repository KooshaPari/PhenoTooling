// Phinbox — Data Models

import Foundation

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
