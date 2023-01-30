//
//  ContentView.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import SwiftUI
import UID2

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, UID2 world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
