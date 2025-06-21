//
//  Financial_detectiveApp.swift
//  Financial_detective
//
//  Created by Vladimir Grigoryev on 11.06.2025.
//

import SwiftUI

//@main
//struct Financial_detectiveApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ServicesTestView()
//        }
//    }
//}

@main
struct Financial_detectiveApp: App {
    @StateObject private var transactionsServiceHolder = TransactionsServiceHolder()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }


    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(transactionsServiceHolder)
                .accentColor(Color("AccentColor"))
        }
    }
}

