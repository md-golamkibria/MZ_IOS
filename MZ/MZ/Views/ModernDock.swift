import SwiftUI

struct ModernDock: View {
    @Binding var selectedTab: Int
    let tabs = [
        DockItem(icon: "house.fill", title: "Home", index: 0),
        DockItem(icon: "safari.fill", title: "Explore", index: 1),
        DockItem(icon: "magnifyingglass", title: "Search", index: 2),
        DockItem(icon: "heart.fill", title: "Favorites", index: 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.index) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab.index ? .white : .white.opacity(0.6))
                            .scaleEffect(selectedTab == tab.index ? 1.2 : 1.0)
                        
                        Text(tab.title)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab.index ? .white : .white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

struct DockItem {
    let icon: String
    let title: String
    let index: Int
}