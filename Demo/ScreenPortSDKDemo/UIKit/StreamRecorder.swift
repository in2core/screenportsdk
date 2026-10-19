//
//  StreamRecorder.swift
//  ScreenPortSDKDemo
//
//  Created by Michal Tomlein on 19/10/2026.
//

import AVFoundation
import Foundation

/// All writer state is accessed on `queue`, which is also the subscription's delivery target.
final class StreamRecorder: @unchecked Sendable {
    enum RecordingError: LocalizedError {
        case missingMedia, invalidSample, unsupportedFormat, writerNotReady, writingFailed, unsupportedEvent

        var errorDescription: String? {
            switch self {
            case .missingMedia: return "The stream did not provide video for recording."
            case .invalidSample: return "The stream supplied an invalid media sample or timestamp."
            case .unsupportedFormat: return "The stream's media format cannot be saved to this movie."
            case .writerNotReady: return "The movie writer could not keep up with the stream."
            case .writingFailed: return "The movie could not be written."
            case .unsupportedEvent: return "The SDK reported an unsupported stream event."
            }
        }
    }

    let queue = DispatchQueue(label: "ScreenPortSDKDemo.recording")
    private let writer: AVAssetWriter
    private var completion: (@MainActor @Sendable (Result<URL, Error>) -> Void)?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var audioDecoder: AudioDecoder?
    private var videoFormat: CMFormatDescription?
    private var audioFormat: CMFormatDescription?
    private var pendingSamples: [(CMSampleBuffer, CMMediaType)] = []
    private var sessionStart: CMTime = .invalid
    private var lastVideoTime: CMTime = .invalid
    private var lastAudioTime: CMTime = .invalid
    private var videoFrameDuration = CMTime(value: 1, timescale: 30)
    private var endTime: CMTime = .invalid
    private var isStopping = false
    private var drainScheduled = false
    private var isFinishing = false
    private var isFinished = false

    init(completion: @escaping @MainActor @Sendable (Result<URL, Error>) -> Void) throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScreenPort-\(UUID().uuidString).mov")
        writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        self.completion = completion
        queue.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self, !self.sessionStart.isValid else { return }
            self.fail(RecordingError.missingMedia)
        }
    }

    func append(_ sample: CMSampleBuffer, mediaType: CMMediaType) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard !isStopping, !isFinishing, !isFinished else { return }
        do {
            guard CMSampleBufferDataIsReady(sample),
                  CMSampleBufferGetPresentationTimeStamp(sample).isNumeric,
                  let format = CMSampleBufferGetFormatDescription(sample),
                  CMFormatDescriptionGetMediaType(format) == mediaType else {
                throw RecordingError.invalidSample
            }
            switch mediaType {
            case kCMMediaType_Video:
                guard CMSampleBufferGetImageBuffer(sample) != nil else { throw RecordingError.invalidSample }
                if let previous = videoFormat, !CMFormatDescriptionEqual(previous, otherFormatDescription: format) {
                    finish()
                    return
                }
                if videoFormat == nil {
                    // Allow audio a short startup window, then record video alone if it is absent.
                    queue.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                        guard let self = self, !self.isStopping, !self.isFinishing, !self.isFinished,
                              !self.sessionStart.isValid else { return }
                        do { try self.startPendingSamples() }
                        catch { self.fail(error) }
                    }
                }
                videoFormat = format
            case kCMMediaType_Audio:
                // Writer inputs cannot be added after writing starts. Ignore audio that arrives
                // after the startup window when this movie has already started without a track.
                if sessionStart.isValid, audioInput == nil { return }
                if let previous = audioFormat, !CMFormatDescriptionEqual(previous, otherFormatDescription: format) {
                    finish()
                    return
                }
                audioFormat = format
            default:
                return
            }

            if !sessionStart.isValid {
                // Bound startup buffering, including when audio arrives before any video.
                if pendingSamples.count == 16 { pendingSamples.removeFirst() }
                pendingSamples.append((sample, mediaType))
                if videoFormat != nil, audioFormat != nil || pendingSamples.count == 16 {
                    try startPendingSamples()
                }
            } else {
                guard pendingSamples.count < 64 else { throw RecordingError.writerNotReady }
                pendingSamples.append((sample, mediaType))
                try drainPendingSamples()
            }
        } catch {
            fail(error)
        }
    }

    private func startPendingSamples() throws {
        guard let videoFormat = videoFormat else { throw RecordingError.missingMedia }
        try start(videoFormat: videoFormat, audioFormat: audioFormat)
        try drainPendingSamples()
    }

    private func drainPendingSamples() throws {
        guard !isFinishing, !isFinished else { return }
        while let (sample, type) = pendingSamples.first {
            if let input = type == kCMMediaType_Video ? videoInput : audioInput,
               !input.isReadyForMoreMediaData {
                guard writer.status == .writing else { throw writer.error ?? RecordingError.writingFailed }
                // Startup samples can arrive at the writer faster than live frames do.
                if !drainScheduled {
                    drainScheduled = true
                    queue.asyncAfter(deadline: .now() + 0.01) {
                        self.drainScheduled = false
                        do { try self.drainPendingSamples() }
                        catch { self.fail(error) }
                    }
                }
                return
            }
            pendingSamples.removeFirst()
            try write(sample, mediaType: type)
            guard !isFinishing, !isFinished else { return }
        }
        if isStopping { finishWriting() }
    }

    private func start(videoFormat: CMFormatDescription, audioFormat: CMFormatDescription?) throws {
        let dimensions = CMVideoFormatDescriptionGetDimensions(videoFormat)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: Int(dimensions.width),
            AVVideoHeightKey: Int(dimensions.height),
        ], sourceFormatHint: videoFormat)

        videoInput.expectsMediaDataInRealTime = true
        guard writer.canAdd(videoInput) else { throw RecordingError.unsupportedFormat }
        writer.add(videoInput)
        self.videoInput = videoInput

        if let audioFormat = audioFormat {
            // Decode compressed source audio before feeding the AAC writer, for system-player playback.
            var audioFormatHint = audioFormat
            if CMFormatDescriptionGetMediaSubType(audioFormat) != kAudioFormatLinearPCM {
                let firstAudioSample = pendingSamples.first { $0.1 == kCMMediaType_Audio }!.0
                let decoder = try AudioDecoder(sample: firstAudioSample)
                audioDecoder = decoder
                audioFormatHint = decoder.outputFormat.formatDescription
            }
            guard let format = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatHint)?.pointee else {
                throw RecordingError.unsupportedFormat
            }
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: format.mSampleRate,
                AVNumberOfChannelsKey: Int(format.mChannelsPerFrame),
            ], sourceFormatHint: audioFormatHint)
            audioInput.expectsMediaDataInRealTime = true
            guard writer.canAdd(audioInput) else { throw RecordingError.unsupportedFormat }
            writer.add(audioInput)
            self.audioInput = audioInput
        }
        guard writer.startWriting() else { throw writer.error ?? RecordingError.writingFailed }
        // Preserve the relative source timestamps, regardless of which medium arrived first.
        sessionStart = pendingSamples.map { CMSampleBufferGetPresentationTimeStamp($0.0) }.min()!
        writer.startSession(atSourceTime: sessionStart)
    }

    private func write(_ sample: CMSampleBuffer, mediaType: CMMediaType) throws {
        guard !isFinishing, !isFinished else { return }
        guard let input = mediaType == kCMMediaType_Video ? videoInput : audioInput else { return }
        let sample = mediaType == kCMMediaType_Audio ? try audioDecoder?.decode(sample) ?? sample : sample
        let time = CMSampleBufferGetPresentationTimeStamp(sample)
        let lastTime = mediaType == kCMMediaType_Video ? lastVideoTime : lastAudioTime
        guard time >= sessionStart, !lastTime.isValid || time >= lastTime else {
            pendingSamples.removeAll()
            finish()
            return
        }
        guard input.isReadyForMoreMediaData else { throw writer.error ?? RecordingError.writerNotReady }
        guard input.append(sample) else { throw writer.error ?? RecordingError.writingFailed }

        var duration = CMSampleBufferGetDuration(sample)
        if mediaType == kCMMediaType_Video {
            if lastVideoTime.isValid, time > lastVideoTime {
                videoFrameDuration = CMTimeSubtract(time, lastVideoTime)
            }
            lastVideoTime = time
            if !duration.isNumeric || duration <= .zero { duration = videoFrameDuration }
        } else {
            lastAudioTime = time
        }
        let sampleEnd = duration.isNumeric && duration > .zero ? CMTimeAdd(time, duration) : time
        if !endTime.isValid || sampleEnd > endTime { endTime = sampleEnd }
    }

    func sourceDidChange() {
        dispatchPrecondition(condition: .onQueue(queue))
        // Ignore the subscription's initial connection event, before any media has arrived.
        if sessionStart.isValid || !pendingSamples.isEmpty { finish() }
    }

    func stop() {
        queue.async { self.finish() }
    }

    private func finish() {
        guard !isStopping, !isFinishing, !isFinished else { return }
        isStopping = true
        do {
            if !sessionStart.isValid {
                // Stopping during the startup window must also produce a video-only movie.
                try startPendingSamples()
            } else {
                try drainPendingSamples()
            }
        } catch {
            fail(error)
        }
    }

    private func finishWriting() {
        guard !isFinishing, !isFinished else { return }
        isFinishing = true
        if endTime.isNumeric, endTime > sessionStart { writer.endSession(atSourceTime: endTime) }
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        writer.finishWriting {
            self.queue.async {
                if self.writer.status == .completed {
                    self.complete(.success(self.writer.outputURL))
                } else {
                    self.fail(self.writer.error ?? RecordingError.writingFailed)
                }
            }
        }
    }

    func fail(_ error: Error) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard !isFinished else { return }
        if writer.status == .writing || writer.status == .unknown { writer.cancelWriting() }
        try? FileManager.default.removeItem(at: writer.outputURL)
        complete(.failure(error))
    }

    private func complete(_ result: Result<URL, Error>) {
        guard !isFinished else { return }
        isFinished = true
        pendingSamples.removeAll()
        let completion = completion
        self.completion = nil
        Task { @MainActor in completion?(result) }
    }

    func cancel() {
        queue.async {
            guard !self.isFinished else { return }
            self.completion = nil
            self.fail(CancellationError())
        }
    }

    private final class AudioDecoder {
        let outputFormat: AVAudioFormat
        private let converter: AVAudioConverter

        init(sample: CMSampleBuffer) throws {
            guard let description = CMSampleBufferGetFormatDescription(sample),
                  var format = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee else {
                throw RecordingError.unsupportedFormat
            }
            // The SDK permits variable-size Opus packets; the converter also needs a nominal size.
            if format.mFramesPerPacket == 0 {
                let duration = CMSampleBufferGetDuration(sample)
                guard duration.isNumeric, duration > .zero else { throw RecordingError.invalidSample }
                format.mFramesPerPacket = UInt32(CMTimeConvertScale(duration, timescale: Int32(format.mSampleRate),
                                                                    method: .default).value)
            }
            guard let inputFormat = AVAudioFormat(streamDescription: &format),
                  let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: format.mSampleRate,
                                                   channels: format.mChannelsPerFrame, interleaved: false),
                  let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                throw RecordingError.unsupportedFormat
            }
            self.outputFormat = outputFormat
            self.converter = converter
            var cookieSize = 0
            if let cookie = CMAudioFormatDescriptionGetMagicCookie(description, sizeOut: &cookieSize) {
                converter.magicCookie = Data(bytes: cookie, count: cookieSize)
            }
        }

        func decode(_ sample: CMSampleBuffer) throws -> CMSampleBuffer {
            guard let block = CMSampleBufferGetDataBuffer(sample), CMSampleBufferGetNumSamples(sample) == 1 else {
                throw RecordingError.invalidSample
            }
            let size = CMBlockBufferGetDataLength(block)
            let input = AVAudioCompressedBuffer(format: converter.inputFormat, packetCapacity: 1,
                                                maximumPacketSize: size)
            input.packetCount = 1
            input.byteLength = UInt32(size)
            try check(CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: size, destination: input.data))
            if let descriptions = input.packetDescriptions {
                try check(CMSampleBufferGetAudioStreamPacketDescriptions(
                    sample,
                    allocatedSize: MemoryLayout<AudioStreamPacketDescription>.size,
                    packetDescriptionsOut: descriptions,
                    packetDescriptionsSizeNeededOut: nil
                ))
            }
            // 120 ms is the maximum Opus packet duration; allow extra capacity for other codecs.
            let capacity = AVAudioFrameCount(max(outputFormat.sampleRate / 5,
                                                 Double(converter.inputFormat.streamDescription.pointee.mFramesPerPacket)))
            guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
                throw RecordingError.unsupportedFormat
            }
            var suppliedInput = false
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { _, inputStatus in
                if suppliedInput {
                    inputStatus.pointee = .noDataNow
                    return nil
                }
                suppliedInput = true
                inputStatus.pointee = .haveData
                return input
            }
            guard status != .error, output.frameLength > 0 else {
                throw error ?? RecordingError.invalidSample
            }
            var timing = CMSampleTimingInfo(
                duration: CMTime(value: 1, timescale: Int32(outputFormat.sampleRate)),
                presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sample),
                decodeTimeStamp: .invalid
            )
            var decoded: CMSampleBuffer?
            try check(CMSampleBufferCreateReady(
                allocator: kCFAllocatorDefault,
                dataBuffer: nil,
                formatDescription: outputFormat.formatDescription,
                sampleCount: Int(output.frameLength),
                sampleTimingEntryCount: 1,
                sampleTimingArray: &timing,
                sampleSizeEntryCount: 0,
                sampleSizeArray: nil,
                sampleBufferOut: &decoded
            ))
            try check(CMSampleBufferSetDataBufferFromAudioBufferList(
                decoded!,
                blockBufferAllocator: kCFAllocatorDefault,
                blockBufferMemoryAllocator: kCFAllocatorDefault,
                flags: 0,
                bufferList: output.audioBufferList
            ))
            return decoded!
        }

        private func check(_ status: OSStatus) throws {
            guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        }
    }
}
