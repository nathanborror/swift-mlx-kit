import Foundation

public struct ChatRequest: Codable {
    public var model: String
    public var messages: [Message]
    public var max_tokens: Int

    public struct Message: Codable {
        public var role: Role
        public var content: String

        public enum Role: String, Codable {
            case system
            case assistant
            case user
        }

        public init(role: Role, content: String) {
            self.role = role
            self.content = content
        }
    }

    public init(model: String, messages: [Message], max_tokens: Int) {
        self.model = model
        self.messages = messages
        self.max_tokens = max_tokens
    }
}
