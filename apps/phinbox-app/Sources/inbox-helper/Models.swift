// Phinbox — Data Models

import Foundation

/// Type-erased Codable wrapper for fields with dynamic types (bool, int, string).
struct AnyCodable: Decodable, Hashable {
    let value: Any
    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else { value = "" }
    }
    func hash(into hasher: inout Hasher) { hasher.combine(String(describing: value)) }
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool { "\(lhs.value)" == "\(rhs.value)" }
}

enum Urgency: String, Decodable, Comparable {
    case error
    case warning
    case info
    case secret

    /// Sort order: error first, then warning, info, secret.
    var sortOrder: Int {
        switch self {
        case .error:   return 0
        case .warning: return 1
        case .info:    return 2
        case .secret:  return 3
        }
    }

    static func < (lhs: Urgency, rhs: Urgency) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

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
    let placeholder: String?
    let maxLength: Int?
    let `default`: AnyCodable?
    let pickerKind: String?
    let min: Int?
    let max: Int?
    let secret: Bool?
    let pattern: String?
    let defaultIndex: Int?
}
struct NotesSpec: Decodable, Hashable {
    let label: String
    let required: Bool?
}
struct ButtonSpec: Decodable, Hashable {
    let confirm: String?
    let cancel: String?
    let defaultIsCancel: Bool?
}
struct PromptSpec: Decodable, Hashable {
    let title: String
    let question: String
    let field: FieldSpec
    let notes: NotesSpec?
    let urgency: Urgency?
    let button: ButtonSpec?
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
