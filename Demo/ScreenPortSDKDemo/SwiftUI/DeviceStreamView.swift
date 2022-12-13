//
//  DeviceStreamView.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import ScreenPortSDK
import SwiftUI

struct DeviceStreamView: View {
    @ObservedObject
    var device: Device

    @State
    private var connectionType: ConnectionType = .auto

    var body: some View {
        Picker("Connection Type", selection: $connectionType) {
            if device.isUSBConnectionAvailable {
                Text("USB").tag(ConnectionType.usb)
            }
            if device.isNetworkConnectionAvailable {
                Text("Network").tag(ConnectionType.network)
            }
            Text("Auto").tag(ConnectionType.auto)
        }
        .pickerStyle(.segmented)
        VideoView(device: device, connectionType: connectionType)
    }
}
