//
//  VectifyApp.swift
//  Vectify
//
//  Created by Aman Verma on 02/05/26.
//

import SwiftUI

@main
struct VectifyApp: App {
    @NSApplicationDelegateAdaptor(VectifyAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
