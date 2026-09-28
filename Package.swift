// swift-tools-version: 6.0
import PackageDescription
import Foundation

let package = Package(
    name: "FluidAudio",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "FluidAudio",
            targets: ["FluidAudio"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FluidAudio",
            dependencies: [
                "MachTaskSelfWrapper",
                "NemoTextProcessing",
            ],
            path: "Sources/FluidAudio",
            // Rootshell dictation only. Keep upstream sources on disk for merges,
            // but do not compile unused engines or bundle their TTS resources.
            exclude: [
                "ASR/Canary",
                "ASR/Cohere",
                "ASR/Paraformer",
                "ASR/Parakeet/Streaming",
                "ASR/Parakeet/Unified",
                "ASR/Parakeet/SlidingWindow/SlidingWindowAsrManager.swift",
                "ASR/Parakeet/SlidingWindow/SlidingWindowAsrSession.swift",
                "Decision",
                "Diarizer",
                "Enhancement",
                "Speaker",
                "TTS",
                "VAD/Fsmn",
                "FluidAudioSwift.swift",
                "ModelNames.swift",
            ]
        ),
        // Keep native NeMo inverse text normalization for rootshell dictation.
        // With TTS callers excluded, dead stripping removes the unused FST grammars.
        // Prebuilt xcframework from FluidInference/text-processing-rs v0.3.1
        // (macOS, iOS, iOS Simulator and Mac Catalyst slices).
        // Always linked on tools < 6.2; Package@swift-6.2.swift exposes it as
        // the opt-out `NemoTextProcessing` trait (#880, #888).
        .binaryTarget(
            name: "NemoTextProcessing",
            url:
                "https://github.com/FluidInference/text-processing-rs/releases/download/v0.3.1/NemoTextProcessing.xcframework.zip",
            checksum: "5fa8c10d4ec26c1bb2413125f351a7222a4c68a23b74476680fbada7e26fc6aa"
        ),
        .target(
            name: "MachTaskSelfWrapper",
            path: "Sources/MachTaskSelfWrapper",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "FluidAudioTests",
            dependencies: ["FluidAudio"],
            exclude: [
                "Shared/ArraySliceTests.swift",
                "Shared/RandomAccessCollectionTests.swift",
                "VAD/FsmnVadChunkingTests.swift",
                "ASR/Parakeet/SlidingWindow/CTC/sample_medical.arpa",
                "ASR/Canary",
                "ASR/Cohere",
                "ASR/Parakeet/EnglishBlocklistTests.swift",
                "ASR/Parakeet/ModelNamesTests.swift",
                "ASR/Parakeet/NemotronBenchmarkTests.swift",
                "ASR/Parakeet/PerformanceMetricsTests.swift",
                "ASR/Parakeet/SlidingWindow/SlidingWindowAsrManagerTests.swift",
                "ASR/Parakeet/SlidingWindow/SlidingWindowAsrSessionTests.swift",
                "ASR/Parakeet/SlidingWindow/SlidingWindowFinalWindowRegressionTests.swift",
                "ASR/Parakeet/SlidingWindow/SlidingWindowVocabularyBoostingStreamingTests.swift",
                "ASR/Parakeet/Streaming",
                "ASR/Parakeet/UnifiedTokenTimingTests.swift",
                "ASR/Parakeet/UnifiedVocabularySegmentTests.swift",
                "ASR/Parakeet/UnifiedWindowingTests.swift",
                "ASR/Parakeet/WordTimingTests.swift",
                "CI",
                "CLI",
                "Decision",
                "Diarizer",
                "Enhancement",
                "TTS",
            ],
            resources: [.copy("ASR/Parakeet/SlidingWindow/Fixtures")]
        ),
        .testTarget(
            name: "RootshellCompatibilityTests",
            dependencies: ["FluidAudio"]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
