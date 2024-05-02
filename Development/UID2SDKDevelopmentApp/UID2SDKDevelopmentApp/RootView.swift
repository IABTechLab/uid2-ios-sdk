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
    private var email = ""

    @State
    private var phone = ""

    @State
    private var isClientSide = true

    var body: some View {
        
        VStack {            
            Text("root.navigation.title")
                .font(Font.system(size: 28, weight: .bold))
            HStack {
                TextField("Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
                Button("Submit Email", systemImage: "arrow.right.circle.fill") {
                    viewModel.handleEmailEntry(email, clientSide: isClientSide)
                }
                .labelStyle(.iconOnly)
            }
            HStack {
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                Button("Submit Phone", systemImage: "arrow.right.circle.fill") {
                    viewModel.handlePhoneEntry(phone, clientSide: isClientSide)
                }
                .labelStyle(.iconOnly)
            }
            Toggle(isOn: $isClientSide) {
                Label("Client Side", systemImage: isClientSide ? "circle.fill" : "circle.slash")
            }
            .toggleStyle(.button)
            .frame(height: 32)
            if viewModel.error != nil {
                ErrorListView(viewModel)
            } else {
                IdentityPackageListView(viewModel)
            }
            HStack(alignment: .center, spacing: 20.0) {
                Button("root.button.reset") {
                    viewModel.reset()
                }.padding()
                Button("root.button.refresh") {
                    viewModel.refresh()
                }.padding()
            }
        }
        .textFieldStyle(.roundedBorder)
        .autocorrectionDisabled()
        .imageScale(.large)
        .padding()
    }
}
