import SwiftUI

struct ChatsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "message.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                Text("Chats")
                    .font(.title)
                    .bold()
                Text("Your conversations will appear here.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
            .navigationTitle("Chats")
        }
    }
}

#Preview {
    ChatsView()
}
