//
//  ContentView.swift
//  api
//
//  Created by Carlos Jaramillo on 2/11/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {        
        Button("call service") {
            Task {
                let result = await API.shared.fetchGlobalCryptoCurrencies()
                switch result {
                case .success(let value):
                    print("Success! Value: \(value)")
                case .failure(let error):
                    print("Error! \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
