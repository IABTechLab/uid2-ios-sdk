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
            Text(LocalizedStringKey("root.label.identitypackage.notification.publishedStatus"))
                .font(Font.system(size: 18, weight: .bold))
            Text(status)
                .font(Font.system(size: 16, weight: .regular))
        }
    }

    private var status: String {
        if let identityStatus = viewModel.identityStatus {
            if case .noIdentity = identityStatus {
                return NSLocalizedString("common.nil", comment: "")
            }
            return identityStatus.debugDescription
        }

        return NSLocalizedString("common.nil", comment: "")
    }
}
