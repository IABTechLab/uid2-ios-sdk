//
//  RootView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import SwiftUI
import UID2

struct RootView: View {

    @ObservedObject
    private var viewModel = RootViewModel()

    var body: some View {
        
        VStack {
            Text(viewModel.titleText)
                .font(Font.system(size: 28, weight: .bold))
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            if viewModel.error != nil {
                ErrorListView(viewModel)
            } else {
                TokenListView(viewModel)
            }
        }        
    }
}
