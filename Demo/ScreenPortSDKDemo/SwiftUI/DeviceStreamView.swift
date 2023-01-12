//
//  DeviceStreamView.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import ScreenPortSDK
import SwiftUI

struct DeviceStreamView: View {
    let id: Int

    @ObservedObject
    var device: Device

    @State
    private var connectionType: ConnectionType = .auto

    @State
    private var sepiaTone: Float = 0.0

    @State
    private var vignetteIntensity: Float = 0.0

    @Environment(\.renderImage)
    private var renderImage

    private var filters: [CIFilter] {
        var filters: [CIFilter] = []
        if sepiaTone > 0.0, let sepia = CIFilter(name: "CISepiaTone") {
            sepia.setValue(sepiaTone, forKey: kCIInputIntensityKey)
            filters.append(sepia)
        }
        if vignetteIntensity > 0.0, let vignette = CIFilter(name: "CIVignette") {
            vignette.setValue(vignetteIntensity, forKey: kCIInputIntensityKey)
            filters.append(vignette)
        }
        return filters
    }

    var body: some View {
        Group {
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
            Grid(alignment: .trailing) {
                GridRow {
                    Text("Sepia:")
                    Slider(value: $sepiaTone, in: 0...1)
                }
                GridRow {
                    Text("Vignette:")
                        .multilineTextAlignment(.trailing)
                    Slider(value: $vignetteIntensity, in: 0...1)
                }
            }
            Button("Capture Image") {
                if let image = renderImage(for: id) {
                    print(image.description)
                }
            }
        }.padding()
        VideoView(id: id, device: device, connectionType: connectionType, filters: filters)
    }
}
