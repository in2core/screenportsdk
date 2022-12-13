//
//  ContentView.swift
//  ScreenPortSDKDemo
//
//  Created by Filip Klembara on 13/12/2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DeviceView()
                .tabItem {
                    Text("SwiftUI")
                }
            DeviceStreamViewControllerWrapper()
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
