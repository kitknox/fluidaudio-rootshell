import Foundation

/// Model repositories retained by the rootshell dictation build.
public enum Repo: String, CaseIterable, Sendable {
    case vad = "FluidInference/silero-vad-coreml"
    case parakeetV3 = "FluidInference/parakeet-tdt-0.6b-v3-coreml"
    case parakeetRedux = "FluidInference/parakeet-redux-coreml"
    case parakeetUltra = "FluidInference/parakeet-ultra-coreml"
    case parakeetV2 = "FluidInference/parakeet-tdt-0.6b-v2-coreml"
    case parakeetCtc110m = "FluidInference/parakeet-ctc-110m-coreml"
    case parakeetCtc06b = "FluidInference/parakeet-ctc-0.6b-coreml"
    case parakeetJa = "FluidInference/parakeet-0.6b-ja-coreml"
    case parakeetTdtCtc110m = "FluidInference/parakeet-tdt-ctc-110m-coreml"

    /// Repository slug (without owner).
    public var name: String {
        switch self {
        case .vad:
            return "silero-vad-coreml"
        case .parakeetV3:
            return "parakeet-tdt-0.6b-v3-coreml"
        case .parakeetRedux:
            return "parakeet-redux-coreml"
        case .parakeetUltra:
            return "parakeet-ultra-coreml"
        case .parakeetV2:
            return "parakeet-tdt-0.6b-v2-coreml"
        case .parakeetCtc110m:
            return "parakeet-ctc-110m-coreml"
        case .parakeetCtc06b:
            return "parakeet-ctc-0.6b-coreml"
        case .parakeetJa:
            return "parakeet-0.6b-ja-coreml"
        case .parakeetTdtCtc110m:
            return "parakeet-tdt-ctc-110m-coreml"
        }
    }

    /// Fully qualified HuggingFace repo path (owner/name)
    public var remotePath: String {
        switch self {
        case .parakeetCtc110m:
            return "FluidInference/parakeet-ctc-110m-coreml"
        case .parakeetCtc06b:
            return "FluidInference/parakeet-ctc-0.6b-coreml"
        case .parakeetTdtCtc110m:
            return "FluidInference/parakeet-tdt-ctc-110m-coreml"
        default:
            return "FluidInference/\(name)"
        }
    }

    /// Preserve upstream download revisions for the retained model repositories.
    public var revision: String {
        "main"
    }

    /// Subdirectory within repo (for repos with multiple model variants)
    public var subPath: String? {
        nil
    }

    /// Local folder name used for caching
    public var folderName: String {
        switch self {
        case .parakeetCtc110m:
            return "parakeet-ctc-110m-coreml"
        case .parakeetCtc06b:
            return "parakeet-ctc-0.6b-coreml"
        case .parakeetJa:
            return "parakeet-ja"
        case .parakeetTdtCtc110m:
            return "parakeet-tdt-ctc-110m"
        default:
            return name.replacingOccurrences(of: "-coreml", with: "")
        }
    }
}

/// Encoder precision for the v3 Parakeet TDT 0.6B encoder.
public enum ParakeetEncoderPrecision: String, Sendable, CaseIterable {
    case int8
    /// Opt-in int8 per-channel linear re-quantization of the v3 encoder
    /// (`Encoder_v2.mlmodelc`, 568M vs 425M). Avoids token corruption the
    /// original 6-bit-LUT palettized `Encoder.mlmodelc` exhibits under
    /// specific right-context (issue #760). `.int8` remains the default and
    /// keeps loading the original file; select this explicitly to use the
    /// rebuild.
    case int8V2 = "int8-v2"
    case int4

    public var encoderFileName: String {
        switch self {
        case .int8:
            return ModelNames.ASR.encoderFile
        case .int8V2:
            return ModelNames.ASR.encoderV2File
        case .int4:
            return ModelNames.ASR.encoderInt4File
        }
    }
}

/// Centralized model names for Parakeet recognition, vocabulary boosting, and Silero VAD.
public enum ModelNames {

    /// ASR model names
    public enum ASR {
        public static let preprocessor = "Preprocessor"
        public static let encoder = "Encoder"
        public static let decoder = "Decoder"
        public static let joint = "JointDecision"
        public static let ctcHead = "CtcHead"

        // Shared vocabulary file across all model versions
        public static let vocabularyFile = "parakeet_vocab.json"

        public static let preprocessorFile = preprocessor + ".mlmodelc"
        public static let encoderFile = encoder + ".mlmodelc"
        public static let decoderFile = decoder + ".mlmodelc"
        public static let jointFile = joint + ".mlmodelc"
        /// Joint decoder variant for v3 that exposes top-K outputs
        /// (`top_k_ids`, `top_k_logits`) used for language-aware script filtering.
        public static let jointV3File = "JointDecisionv3.mlmodelc"
        /// v3 encoder re-quantized as int8 per-channel linear (issue #760).
        /// Published alongside the immutable original `Encoder.mlmodelc`;
        /// HF repo files are never mutated in place, fixes ship as new names.
        public static let encoderV2File = "Encoder_v2.mlmodelc"
        public static let encoderInt4File = "EncoderInt4.mlmodelc"
        public static let ctcHeadFile = ctcHead + ".mlmodelc"

        /// Required models for v2 / legacy split-frontend loaders.
        /// v3 uses `requiredModelsV3(precision:)` (with `jointV3File`).
        public static let requiredModels: Set<String> = [
            preprocessorFile,
            encoderFile,
            decoderFile,
            jointFile,
        ]

        public static func requiredModelsV3(
            precision: ParakeetEncoderPrecision = .int8
        ) -> Set<String> {
            [
                preprocessorFile,
                precision.encoderFileName,
                decoderFile,
                jointV3File,
            ]
        }

        /// Required models for fused frontend (110m hybrid: preprocessor contains encoder)
        public static let requiredModelsFused: Set<String> = [
            preprocessorFile,
            decoderFile,
            jointFile,
        ]

        /// Get vocabulary filename for specific model version
        public static func vocabulary(for repo: Repo) -> String {
            // All Parakeet models use the same vocabulary file (format varies: dict for v2/v3, array for 110m)
            return vocabularyFile
        }
    }

    /// CTC model names
    public enum CTC {
        public static let melSpectrogram = "MelSpectrogram"
        public static let audioEncoder = "AudioEncoder"

        public static let melSpectrogramPath = melSpectrogram + ".mlmodelc"
        public static let audioEncoderPath = audioEncoder + ".mlmodelc"

        // Vocabulary JSON path (shared by Python/Nemo and CoreML exports).
        public static let vocabularyPath = "vocab.json"

        public static let requiredModels: Set<String> = [
            melSpectrogramPath,
            audioEncoderPath,
        ]
    }

    /// TDT ja (Japanese) model names.
    ///
    /// Hybrid layout: the CTC-trained preprocessor + encoder from the
    /// `parakeetJa` repo are reused as the acoustic frontend, paired with a TDT
    /// decoder + joint (filenames `Decoderv2.mlmodelc` / `Jointerv2.mlmodelc`
    /// from the same repo). CTC-only inference for Japanese was removed in
    /// 846924a1d.
    public enum TDTJa {
        public static let preprocessor = "Preprocessor"
        public static let encoder = "Encoder"
        public static let decoder = "Decoderv2"
        public static let joint = "Jointerv2"

        public static let preprocessorFile = preprocessor + ".mlmodelc"
        public static let encoderFile = encoder + ".mlmodelc"
        public static let decoderFile = decoder + ".mlmodelc"
        public static let jointFile = joint + ".mlmodelc"

        public static let vocabularyFile = "vocab.json"

        public static let requiredModels: Set<String> = [
            preprocessorFile,
            encoderFile,
            decoderFile,
            jointFile,
        ]
    }

    /// VAD model names
    public enum VAD {
        public static let sileroVad = "silero-vad-unified-256ms-v6.2.1"

        public static let sileroVadFile = sileroVad + ".mlmodelc"

        public static let requiredModels: Set<String> = [
            sileroVadFile
        ]
    }

    static func getRequiredModelNames(for repo: Repo, variant: String?) -> Set<String> {
        switch repo {
        case .vad:
            return ModelNames.VAD.requiredModels
        case .parakeetV3:
            let precision = ParakeetEncoderPrecision(rawValue: variant ?? "") ?? .int8
            return ModelNames.ASR.requiredModelsV3(precision: precision)
        case .parakeetRedux, .parakeetUltra:
            // Single encoder build; no precision variants.
            return ModelNames.ASR.requiredModelsV3()
        case .parakeetV2:
            return ModelNames.ASR.requiredModels
        case .parakeetTdtCtc110m:
            return ModelNames.ASR.requiredModelsFused
        case .parakeetCtc110m, .parakeetCtc06b:
            return ModelNames.CTC.requiredModels
        case .parakeetJa:
            return ModelNames.TDTJa.requiredModels
        }
    }
}
