//
//  ErrorListView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import SwiftUI

struct ErrorListView: View {
    
    @ObservedObject
    private var viewModel: RootViewModel

    init(_ viewModel: RootViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        List {
            Group {
                Text(LocalizedStringKey("root.label.error"))
                    .font(Font.system(size: 20, weight: .bold))
                    .foregroundColor(.red)
                Text(String(viewModel.error?.localizedDescription ?? "Error"))
                    .font(Font.system(size: 16, weight: .regular))
            }
        }.listStyle(.plain)
    }
}
