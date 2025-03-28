import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom

@MainActor
@Observable
public final class Client {
    public static let shared = Client()

    public var models: [Model]
    public var modelsCached: [String: ModelState]

    public enum Error: Swift.Error, CustomStringConvertible {
        case missingModel(String)
        case loadingModel

        public var description: String {
            switch self {
            case .missingModel(let detail):
                return "Missing model: \(detail)"
            case .loadingModel:
                return "Actively loading model"
            }
        }
    }

    public enum ModelState {
        case idle
        case loading
        case cached(ModelContainer)
    }

    public init() {
        self.models = Defaults.defaultModels
        self.modelsCached = [:]
    }
}

extension Client {

    public func getModel(_ path: String) throws -> Model {
        guard let model = models.first(where: { $0.path == path }) else {
            throw Error.missingModel(path)
        }
        return model
    }

    public func upsertModel(_ model: Model) {
        if let index = models.firstIndex(where: { $0.id == model.id }) {
            var existing = models[index]
            existing.apply(model)
            models[index] = existing
        } else {
            models.append(model)
        }
    }

    public func fetchModel(id: String) async throws -> ModelContainer {
        let model = try getModel(id)
        return try await fetchModel(path: model.path)
    }

    public func fetchModel(path: String) async throws -> ModelContainer {
        if modelsCached[path] == nil {
            modelsCached[path] = .idle
        }
        switch modelsCached[path]! {
        case .idle:
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024) // limit the buffer cache
            let config = ModelConfiguration(id: path)
            let url = URL.documentsDirectory.appending(path: ".app")
            let container = try await LLMModelFactory.shared.loadContainer(hub: .init(downloadBase: url), configuration: config) { value in
                print("Loading \(path): \(value.fractionCompleted)")
                Task { @MainActor [weak self] in
                    self?.modelsCached[path] = .loading

                    if var model = try? self?.getModel(path) {
                        model.loaded = value.fractionCompleted
                        self?.upsertModel(model)
                    }
                }
            }
            modelsCached[path] = .cached(container)
            return container
        case .loading:
            throw Error.loadingModel
        case .cached(let container):
            return container
        }
    }
}

extension Client {

    public func chatCompletions(_ request: ChatRequest) async throws -> String {
        let container = try await fetchModel(id: request.model)
        let messages = encode(request.messages)

        // Each time you generate you will get something new
        MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

        let result = try await container.perform { context in
            let input = try await context.processor.prepare(input: .init(messages: messages))
            let parameters = GenerateParameters(temperature: 0.5)
            let maxTokens = 4096

            return try MLXLMCommon.generate(input: input, parameters: parameters, context: context) { tokens in
                if tokens.count >= maxTokens {
                    return .stop
                } else {
                    return .more
                }
            }
        }
        return result.output
    }

    public func chatCompletionsStream(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Swift.Error> {
        let container = try await fetchModel(id: request.model)
        let messages = encode(request.messages)

        // Each time you generate you will get something new
        MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let result = try await container.perform { context in
                        let input = try await context.processor.prepare(input: .init(messages: messages))
                        let parameters = GenerateParameters(temperature: 0.5)
                        let displayEveryNTokens = 4
                        let maxTokens = 4096

                        return try MLXLMCommon.generate(input: input, parameters: parameters, context: context) { tokens in
                            if tokens.count % displayEveryNTokens == 0 {
                                let text = context.tokenizer.decode(tokens: tokens)
                                continuation.yield(text)
                            }
                            if tokens.count >= maxTokens {
                                return .stop
                            } else {
                                return .more
                            }
                        }
                    }
                    continuation.yield(result.output)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func encode(_ messages: [ChatRequest.Message]) -> [[String: String]] {
        var out = [[String: String]]()
        for message in messages {
            out.append(["role": message.role.rawValue, "content": message.content])
        }
        return out
    }
}
