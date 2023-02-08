//
//  IdentityPackageNotificationsView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 2/8/23.
//

import SwiftUI

struct IdentityPackageNotificationsView: View {

    @ObservedObject
    private var viewModel: RootViewModel

    init(_ viewModel: RootViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            Text(LocalizedStringKey("root.label.identitypackage.notification.refreshSucceed"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshSucceeded)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.identitypackage.notification.optout"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.userOptedOut)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.identitypackage.notification.identityPackageExpired"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.identityPackageExpired)
                .font(Font.system(size: 16, weight: .regular))
            Text(LocalizedStringKey("root.label.identitypackage.notification.refreshTokenExpired"))
                .font(Font.system(size: 18, weight: .bold))
            Text(viewModel.refreshTokenExpired)
                .font(Font.system(size: 16, weight: .regular))
        }
    }
}
