import SwiftUI

struct TabScaffold<Content: View>: View {

    @Binding var selectedTab: DashboardView.Tab
    let content: Content

    private let sidePadding: CGFloat = 16

    private let dashboardHeight: CGFloat = 96

    init(selectedTab: Binding<DashboardView.Tab>,
         @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, dashboardHeight)

            VStack {
                Spacer()
                BottomTabBar(selected: $selectedTab)
                    .padding(.horizontal, sidePadding)
                    .padding(.bottom, 14)
            }
        }
    }
}
