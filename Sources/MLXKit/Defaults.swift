import Foundation
import MLX
import MLXLMCommon

public struct Defaults: Sendable {

    public static let defaultModel = llama_3_2_1b_4bit

    public static let defaultModels: [Model] = [
        llama_3_2_1b_4bit,
        llama_3_2_3b_4bit,
        deepseek_r1_distill_qwen_1_5b_4bit,
        deepseek_r1_distill_qwen_1_5b_8bit
    ]

    public static let llama_3_2_1b_4bit = Model(
        name: "Llama 3.2 1B Instruct (4 bit)",
        path: "mlx-community/Llama-3.2-1B-Instruct-4bit"
    )

    public static let llama_3_2_3b_4bit = Model(
        name: "Llama 3.2 3B Instruct (4 bit)",
        path: "mlx-community/Llama-3.2-3B-Instruct-4bit"
    )

    public static let deepseek_r1_distill_qwen_1_5b_4bit = Model(
        name: "DeepSeek R1 1.5B (4 bit)",
        path: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit"
    )

    public static let deepseek_r1_distill_qwen_1_5b_8bit = Model(
        name: "DeepSeek R1 1.5B (8 bit)",
        path: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-8bit"
    )
}
