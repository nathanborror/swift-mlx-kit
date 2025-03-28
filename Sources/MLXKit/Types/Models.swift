import Foundation

public struct Model: Codable, Identifiable, Hashable, Sendable {
    public var name: String
    public var path: String
    public var loaded: Double

    public var id: String { path }

    public init(name: String, path: String, loaded: Double = 0.0) {
        self.name = name
        self.path = path
        self.loaded = loaded
    }

    public mutating func apply(_ model: Model) {
        name = model.name
        path = model.path
        loaded = model.loaded
    }
}
