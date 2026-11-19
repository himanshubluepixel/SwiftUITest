//
//  SwiftUITestApp.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI

@main
struct SwiftUITestApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()          // owns Router, TabView, sheets (from Router.swift)
                .themed()       // appearance + tint (from Theme.swift)
        }
    }
}
