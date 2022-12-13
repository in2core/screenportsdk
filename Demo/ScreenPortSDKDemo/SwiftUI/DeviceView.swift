//
//  DeviceView.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import ScreenPortSDK
import SwiftUI

/// Presenting ScreenPort's stream in SwiftUI
struct DeviceView: View {
    @StateObject
    private var controller = DeviceController()

    var body: some View {
        let devices = controller.availableDevices
        if let device = devices.first {
            VStack {
                Text("Available Devices Count: \(devices.count)")
                DeviceStreamView(device: device)
            }
        } else {
            Text("No Available Device")
        }
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView()
    }
}
