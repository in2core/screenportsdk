//
//  DeviceStreamViewControllerWrapper.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import ScreenPortSDK
import SwiftUI

struct DeviceStreamViewControllerWrapper: UIViewControllerRepresentable {
    let controller: DeviceController

    func makeUIViewController(context: Context) -> DeviceStreamViewController {
        DeviceStreamViewController(deviceController: controller)
    }

    func updateUIViewController(_ uiViewController: DeviceStreamViewController, context: Context) {}
}
