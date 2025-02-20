import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom

public final class Client {

    private var cachedModels: [String: ModelContainer]

    public init() {
        self.cachedModels = [:]
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case missingModel(String)

        public var description: String {
            switch self {
            case .missingModel(let detail):
                return "Missing model: \(detail)"
            }
        }
    }
}

extension Client {

    public func models() -> [Model] {
        return Defaults.defaultModels
    }

    public func model(_ id: String) throws -> Model {
        guard let model = models().first(where: { $0.id == id }) else {
            throw Error.missingModel(id)
        }
        return model
    }

    public func modelContainer(_ id: String) throws -> ModelContainer {
        let model = try model(id)
        guard let modelContext = cachedModels[model.path] else {
            throw Error.missingModel(id)
        }
        return modelContext
    }

    public func fetchModelContainer(_ path: String, progress: @Sendable @escaping (Double) -> Void) async throws {
        let config = ModelConfiguration(id: path)

        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024) // limit the buffer cache

        let modelContext = try await LLMModelFactory.shared.loadContainer(configuration: config) { value in
            progress(value.fractionCompleted)
        }
        cachedModels[path] = modelContext
    }
}

extension Client {

    public func chatCompletions(_ request: ChatRequest) async throws -> String {
        let container = try modelContainer(request.model)
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

    public func chatCompletionsStream(_ request: ChatRequest) throws -> AsyncThrowingStream<String, Swift.Error> {
        let container = try modelContainer(request.model)
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
