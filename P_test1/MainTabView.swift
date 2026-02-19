//
//  MainTabView.swift
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ContentView()
                    .navigationTitle("Home")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            NavigationStack {
                ChatsView()
                    .navigationTitle("Chats")
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chats")
            }

            NavigationStack {
                CallsView()
                    .navigationTitle("Calls")
            }
            .tabItem {
                Image(systemName: "phone.fill")
                Text("Calls")
            }
        }
    }
}

#Preview {
    MainTabView()
}
