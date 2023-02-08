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

    @State
    private var emailTextField = ""
    
    var body: some View {
        
        VStack {            
            Text(viewModel.titleText)
                .font(Font.system(size: 28, weight: .bold))
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            TextField("Email Address", text: $emailTextField)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .onSubmit {
                    viewModel.handleEmailEntry(emailTextField)
                }
            if viewModel.error != nil {
                ErrorListView(viewModel)
            } else {
                IdentityPackageListView(viewModel)
            }
        }        
    }
}
