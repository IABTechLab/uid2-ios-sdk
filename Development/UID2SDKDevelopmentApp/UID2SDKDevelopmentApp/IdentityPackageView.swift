//
//  UID2TokensView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import Foundation
import SwiftUI

struct IdentityPackageView: View {
    
    @ObservedObject
    private var viewModel: RootViewModel

    init(_ viewModel: RootViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            Text(LocalizedStringKey("root.label.identitypackage.advertisingToken"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.advertisingToken)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.identitypackage.refreshToken"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshToken)
                .font(Font.system(size: 16, weight: .regular))
        }
        Group {
            Text(LocalizedStringKey("root.label.identitypackage.identityExpires"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.identityExpires)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.identitypackage.refreshFrom"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshFrom)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.identitypackage.refreshExpires"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshExpires)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.identitypackage.refreshResponseKey"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshResponseKey)
                .font(Font.system(size: 16, weight: .regular))
        }
    }
    
}
