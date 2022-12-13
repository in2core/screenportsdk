//
//  DeviceStreamViewController.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import Combine
import ScreenPortSDK
import UIKit

/// Presenting ScreenPort's stream in UIKit
class DeviceStreamViewController: UIViewController {
    private let deviceController = DeviceController()
    private let videoViewController = VideoViewController()

    private var subscriptions: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        videoViewController.view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(videoViewController.view)
        NSLayoutConstraint.activate([
            videoViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            videoViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])

        addChild(videoViewController)
        videoViewController.didMove(toParent: self)

        deviceController.availableDevicesPublisher
            .sink { [weak self] devices in
                self?.update(with: devices)
            }
            .store(in: &subscriptions)
    }

    private func update(with devices: [Device]) {
        videoViewController.device = devices.first
    }
}
