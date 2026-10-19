//
//  ContentView.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import ScreenPortSDK
import SwiftUI

struct ContentView: View {
    @StateObject
    private var controller = DeviceController()

    var body: some View {
        TabView {
            DeviceView(controller: controller)
                .tabItem {
                    Text("SwiftUI")
                }
            DeviceStreamViewControllerWrapper(controller: controller)
                .tabItem {
                    Text("UIKit")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
