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
    @StateObject private var transactionsServiceHolder = TransactionsServiceHolder(token: Bundle.main.apiToken)
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color( red: 0x6F/255, green: 0x5D/255, blue: 0xB7/255))
        UITableView.appearance().sectionHeaderTopPadding = 0
    }


    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(transactionsServiceHolder)
                .accentColor(Color("AccentColor"))
        }
    }
}

