import FluidAudio
import XCTest

final class DictationCompatibilityTests: XCTestCase {
    func testNativeNumberNormalizationIsPreserved() {
        let normalizer = TextNormalizer.shared
        XCTAssertTrue(normalizer.isNativeAvailable)
        XCTAssertEqual(normalizer.normalize("two hundred"), "200")
        XCTAssertEqual(normalizer.normalize("five dollars and fifty cents"), "$5.50")
        XCTAssertEqual(normalizer.normalizeSentence("I paid five dollars and fifty cents"), "I paid $5.50")
    }

    func testRootshellModelAndVocabularyAPIsRemainAvailable() {
        let versions: [AsrModelVersion] = [.v2, .v3, .ultra, .redux]
        for version in versions {
            XCTAssertFalse(AsrModels.defaultCacheDirectory(for: version).path.isEmpty)
        }
        XCTAssertFalse(CtcModels.defaultCacheDirectory(for: .ctc110m).path.isEmpty)
        let terms = CustomVocabularyContext(terms: [CustomVocabularyTerm(text: "rootshell")])
        XCTAssertFalse(terms.terms.isEmpty)
        XCTAssertGreaterThan(VadManager.chunkSize, 0)
        _ = VadStreamState.initial()
        _ = VadSegmentationConfig()
        _ = TdtDecoderState.make(decoderLayers: 2)
    }

    func testModelCacheLocationsStayCompatibleWithExistingDownloads() {
        let folders: [(AsrModelVersion, String)] = [
            (.v2, "parakeet-tdt-0.6b-v2"),
            (.v3, "parakeet-tdt-0.6b-v3"),
            (.ultra, "parakeet-ultra"),
            (.redux, "parakeet-redux"),
        ]
        for (version, folder) in folders {
            XCTAssertEqual(AsrModels.defaultCacheDirectory(for: version).lastPathComponent, folder)
        }
        XCTAssertEqual(
            CtcModels.defaultCacheDirectory(for: .ctc110m).lastPathComponent,
            "parakeet-ctc-110m-coreml")
        XCTAssertEqual(
            MLModelConfigurationUtils.defaultModelsDirectory(for: .vad).lastPathComponent,
            "silero-vad")
        XCTAssertEqual(ParakeetEncoderPrecision.int4.encoderFileName, "EncoderInt4.mlmodelc")
        XCTAssertEqual(ParakeetEncoderPrecision.int8.encoderFileName, "Encoder.mlmodelc")
    }

    /// Optional integration check using real, previously downloaded models; never downloads test assets.
    @MainActor
    func testLoadCachedDictationModels() async throws {
        guard ProcessInfo.processInfo.environment["FLUIDAUDIO_RUN_MODEL_TESTS"] == "1" else {
            throw XCTSkip("Set FLUIDAUDIO_RUN_MODEL_TESTS=1 to validate existing Parakeet v3 and Silero models")
        }
        let previousOfflineMode = ModelHub.offlineMode
        ModelHub.offlineMode = true
        defer { ModelHub.offlineMode = previousOfflineMode }
        let asrDirectory = AsrModels.defaultCacheDirectory(for: .v3)
        let vadDirectory = MLModelConfigurationUtils.defaultModelsDirectory(for: .vad)
        guard AsrModels.modelsExist(at: asrDirectory, version: .v3, encoderPrecision: .int8),
            FileManager.default.fileExists(
                atPath:
                    vadDirectory
                    .appendingPathComponent(ModelNames.VAD.sileroVadFile).path)
        else {
            throw XCTSkip("Real Parakeet v3 int8 and Silero models must already be cached")
        }
        let models = try await AsrModels.load(from: asrDirectory, version: .v3, encoderPrecision: .int8)
        let asr = AsrManager(config: .default)
        try await asr.loadModels(models)
        let vad = try await VadManager(config: .default, modelDirectory: vadDirectory)
        let available = await vad.isAvailable
        XCTAssertTrue(available)
        await asr.cleanup()
    }
}
