//
//  TokenListView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import SwiftUI

struct TokenListView: View {
    
    @ObservedObject
    private var viewModel: RootViewModel

    init(_ viewModel: RootViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        List {
            Section(header: Text(LocalizedStringKey("root.title.uid2Token"))
                .font(Font.system(size: 22, weight: .bold))) {
                    UID2TokensView(viewModel)
                }
        }.listStyle(.plain)
    }
}
