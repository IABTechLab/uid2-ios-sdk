//
//  UID2TokensView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import Foundation
import SwiftUI

struct UID2TokensView: View {
    
    @ObservedObject
    private var viewModel: RootViewModel

    init(_ viewModel: RootViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            Text(LocalizedStringKey("root.label.uid2Token.advertisingToken"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.advertisingToken)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.uid2Token.refreshToken"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshToken)
                .font(Font.system(size: 16, weight: .regular))
        }
        Group {
            Text(LocalizedStringKey("root.label.uid2Token.identityExpires"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.identityExpires)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.uid2Token.refreshFrom"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshFrom)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.uid2Token.refreshExpires"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshExpires)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.uid2Token.refreshResponseKey"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshResponseKey)
                .font(Font.system(size: 16, weight: .regular))
        }
    }
    
}
