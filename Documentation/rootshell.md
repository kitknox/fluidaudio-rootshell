# Rootshell dictation build

The `FluidAudio` product and import name stay unchanged. Both package manifests
build the same dictation subset. NeMo remains a default dependency: do not disable
its trait in rootshell, since the app uses `TextNormalizer.normalizeSentence`.

## Preserved functionality

- Parakeet v2, v3, Ultra, and Redux through `AsrManager` / `AsrModels`, including
  language hints, decoder state, token timings, and int8/int4 encoder selection.
- Silero VAD, its recurrent state, and streaming speech segmentation. Rootshell's
  live partials use repeated `AsrManager` calls, not the excluded EOU, Nemotron,
  Unified, or `SlidingWindowAsrManager` APIs.
- CTC models and `VocabularyBoostingSession`, including aliases, custom vocabulary,
  acoustic rescoring, and terms provided by rootshell's screen-vocabulary feature.
- Native `TextNormalizer` and all of its existing behavior. Its Swift source,
  prebuilt Rust dependency version, and checksum are unchanged.
- SenseVoiceSmall through `SenseVoiceManager` / `SenseVoiceModels`, used for Chinese,
  Cantonese, Japanese, and Korean dictation. Rootshell loads the int8 encoder on the
  Neural Engine and the fp32 encoder on Intel Macs and the simulator.
- Model download/cancellation/progress, cache locations, model file names,
  precision choices, and load/cleanup behavior for all retained models.

The Parakeet TDT Japanese and 110M variants and both CTC variants remain supported
because they share the retained model loader. The app currently exposes a subset.

## Packaging changes

The manifests exclude TTS (including LuxTTS pronunciation resources), diarization,
speaker embedding, enhancement, decision scoring, other ASR families, and unused
streaming backends. FastClusterWrapper is no longer a dependency. The general
upstream CLI is not built because it imports those excluded engines.

`Sources/FluidAudio/Rootshell/ModelNames.swift` contains the retained model metadata.
The full upstream `ModelNames.swift` stays on disk but is excluded. When merging
upstream changes, update the retained metadata too; keep cache-folder names and
filenames stable. `DiarizerError` moved unchanged into Shared because Silero's
shared ANE memory helper throws it. This does not include the diarization engine.

Tests for excluded APIs are omitted from the test target. Two tests for removed
Paraformer and EOU APIs were removed from otherwise retained shared test files.
The generic cache and downloader tests remain.

This scope applies to SwiftPM. The inherited CocoaPods spec and general upstream
CLI/examples are not supported distribution paths for this fork.

## Measured size reduction (2026-09-26)

Baseline: fork commit `67837e95`, including its newer upstream changes; not the
older v0.17.4 tag used by the archived rootshell release.

Both baseline and reduced source sets were compiled with Swift 6.4, `-O` and
whole-module optimization for Catalyst arm64 and x86_64. Their library objects
were substituted into the same rootshell archive link inputs, linked with the
archive's dead stripping and thin LTO flags, then stripped with `strip -D`.
No size-optimization flags or normalization features were disabled.

| Main executable slice | Baseline bytes | Reduced bytes | Saved bytes |
| --- | ---: | ---: | ---: |
| arm64 | 112,734,616 | 101,701,968 | 11,032,648 |
| x86_64 | 120,139,888 | 108,747,496 | 11,392,392 |
| Combined | 232,874,504 | 210,449,464 | 22,425,040 |

Removing LuxTTS resources saves another 1,019,385 bytes, for approximately
**23.44 MB of universal app savings** before minor bundle/signature/alignment
changes. MB here means decimal megabytes. These are controlled link measurements,
not a newly exported/notarized app or App Store download-size measurement. The
measurement binaries reuse compiled app objects and are only for size analysis;
consuming applications must rebuild against the fork, not replace library objects
in an existing release.

The arm64 linker map attributes 4,403,667 -> 1,045,256 bytes to FluidAudio's Swift
object, and 7,964,458 -> 575,237 bytes to the NeMo Rust library. Excluding TTS removes
the sole Swift caller of `nemo_tn_fst` in `TTS/Shared/NemoTextNormalizer.swift`.
Dead stripping can then discard the TTS FST engine and its compressed grammars.
The `nemo_normalize*` functions used for dictation remain linked. Thus the full
roughly 8 MB NeMo payload is not necessary to retain dictation normalization.

The reduced library also compiled successfully for iOS ARM64. An iOS application
archive was not produced; Catalyst savings are not an exact iOS download estimate.

## Validation and maintenance

```sh
swift build -c release --target FluidAudio
swift test --filter DictationCompatibilityTests
```

The compatibility tests verify native normalization, retained public APIs,
precision filenames, and existing model-cache paths. To validate real cached
Parakeet v3 int8 and Silero models without downloading test assets:

```sh
FLUIDAUDIO_RUN_MODEL_TESTS=1 swift test --filter DictationCompatibilityTests
```

Run upstream logic tests in Debug: several upstream tests use helpers that are
only compiled with `DEBUG`. A selected regression run covering decoder state,
VAD segmentation/streaming, vocabulary/BK-tree/CTC logic, model cache/file selection,
encoder precision, argmax, token deduplication, and punctuation passed: 298 tests
passed and four tokenizer tests skipped because the CTC tokenizer was not cached.
The four compatibility tests, including loading real cached models, are included
in that total. No end-to-end microphone or CTC model inference test was performed.

Before releasing, update rootshell's package dependency to an approved commit of
this fork, do a clean app archive, and smoke-test dictation and vocabulary boosting.
Do not ship the temporary measurement binaries.
