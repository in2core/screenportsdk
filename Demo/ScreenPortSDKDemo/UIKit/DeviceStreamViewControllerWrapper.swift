//
//  DeviceStreamViewControllerWrapper.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import SwiftUI

struct DeviceStreamViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DeviceStreamViewController {
        DeviceStreamViewController()
    }

    func updateUIViewController(_ uiViewController: DeviceStreamViewController, context: Context) {}
}
