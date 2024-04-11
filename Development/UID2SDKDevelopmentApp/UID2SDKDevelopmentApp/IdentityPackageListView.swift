//
//  TokenListView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import SwiftUI

struct IdentityPackageListView: View {
    
    @ObservedObject
    private var viewModel: RootViewModel

    init(_ viewModel: RootViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        List {
            Section(header: Text(LocalizedStringKey("root.title.identitypackage"))
                .font(Font.system(size: 22, weight: .bold))) {
                    IdentityPackageView(viewModel)
                    IdentityPackageNotificationsView(viewModel)
                }
        }.listStyle(.plain)
    }
}
