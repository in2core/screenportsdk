//
//  Grid.swift
//  ScreenPortSDKDemo
//
//  Created by Michal Tomlein on 11/01/2023.
//

import SwiftUI

struct Grid<Content: View>: View {
    private let alignment: Alignment
    private let content: () -> Content

    init(alignment: Alignment = .center,
         @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            SwiftUI.Grid(alignment: alignment) {
                content()
            }
        } else {
            VStack {
                content()
            }
        }
    }
}

struct GridRow<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            SwiftUI.GridRow {
                content()
            }
        } else {
            HStack {
                content()
            }
        }
    }
}
