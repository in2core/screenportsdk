//
//  DeviceStreamViewController.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import AVFoundation
import AVKit
import Combine
import ScreenPortSDK
import UIKit

/// Presenting ScreenPort's stream in UIKit
final class DeviceStreamViewController: UIViewController {
    private let deviceController: DeviceController
    private let videoViewController = VideoViewController()
    private let recordButton = UIButton(type: .system)

    private var subscriptions: Set<AnyCancellable> = []
    private var streamSubscription: StreamSubscription?
    private var recorder: StreamRecorder?
    private var isFinishingRecording = false
    private var pendingRecordingResult: Result<URL, Error>?

    init(deviceController: DeviceController) {
        self.deviceController = deviceController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        addChild(videoViewController)
        videoViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoViewController.view)
        NSLayoutConstraint.activate([
            videoViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            videoViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        videoViewController.didMove(toParent: self)

        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.backgroundColor = .systemRed
        recordButton.tintColor = .white
        recordButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        recordButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        recordButton.layer.cornerRadius = 12
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        view.addSubview(recordButton)
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])

        deviceController.availableDevicesPublisher
            .sink { [weak self] devices in
                self?.update(with: devices)
            }
            .store(in: &subscriptions)
        update(with: deviceController.availableDevices)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let result = pendingRecordingResult {
            pendingRecordingResult = nil
            presentRecordingResult(result)
        }
    }

    private func update(with devices: [Device]) {
        let device = devices.first
        if videoViewController.device !== device, recorder != nil {
            stopRecording()
        }
        videoViewController.device = device
        updateRecordButton()
    }

    private func updateRecordButton() {
        recordButton.setTitle(isFinishingRecording ? "Finishing…" : recorder == nil ? "Record" : "Stop Recording",
                              for: .normal)
        recordButton.isEnabled = !isFinishingRecording && (recorder != nil || videoViewController.device != nil)
        recordButton.alpha = recordButton.isEnabled ? 1 : 0.5
    }

    @objc private func toggleRecording() {
        guard recorder == nil else {
            stopRecording()
            return
        }
        guard let device = videoViewController.device else { return }
        do {
            let recorder = try StreamRecorder { [weak self] result in
                self?.recordingDidFinish(result)
            }
            self.recorder = recorder
            streamSubscription = device.subscribe(queue: recorder.queue) { event in
                switch event {
                case let .sampleBuffer(sample, mediaType: mediaType):
                    recorder.append(sample, mediaType: mediaType)
                case .discontinuity:
                    recorder.sourceDidChange()
                case let .failure(error):
                    recorder.fail(error)
                @unknown default:
                    recorder.fail(StreamRecorder.RecordingError.unsupportedEvent)
                }
            }
            updateRecordButton()
        } catch {
            showRecordingError(error)
        }
    }

    private func stopRecording() {
        guard let recorder, !isFinishingRecording else { return }
        isFinishingRecording = true
        streamSubscription?.cancel()
        streamSubscription = nil
        recorder.stop()
        updateRecordButton()
    }

    private func recordingDidFinish(_ result: Result<URL, Error>) {
        streamSubscription?.cancel()
        streamSubscription = nil
        recorder = nil
        isFinishingRecording = false
        updateRecordButton()

        // A recording can finish after the user switches to the SwiftUI demo tab.
        guard viewIfLoaded?.window != nil else {
            pendingRecordingResult = result
            return
        }
        presentRecordingResult(result)
    }

    private func presentRecordingResult(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            let controller = AVPlayerViewController()
            controller.player = AVPlayer(url: url)
            present(controller, animated: true) {
                controller.player?.play()
            }
        case let .failure(error):
            showRecordingError(error)
        }
    }

    private func showRecordingError(_ error: Error) {
        let alert = UIAlertController(title: "Recording Failed", message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    deinit {
        streamSubscription?.cancel()
        recorder?.cancel()
    }
}
