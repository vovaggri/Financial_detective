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
    @State private var showMainInterface = false
    
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
            // оборачиваем ваш MainTabView в ZStack
            ZStack {
                // 1) когда анимация закончилась — показываем основное приложение
                if showMainInterface {
                    MainTabView()
                        .environmentObject(transactionsServiceHolder)
                        .accentColor(Color("AccentColor"))
                } else {
                    // 2) иначе — на весь экран белый фон + LottieView
                    Color.white
                        .ignoresSafeArea()
                    
                    LottieView("pig", loopMode: .playOnce) {
                        // по окончании анимации — переключаемся на MainTabView
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showMainInterface = true
                        }
                    }
                    .ignoresSafeArea() // чтобы Lottie занял весь экран
                }
            }
        }
    }
}

