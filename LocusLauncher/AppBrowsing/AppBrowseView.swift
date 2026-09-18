import SwiftUI

/// Every indexed app in alphabetical sections.
struct AppBrowseView: View {
    let appIndex: AppIndexStore
    let controller: AppBrowseTableController

    var body: some View {
        let list = BrowseList(apps: appIndex.apps)
        AppBrowseTable(list: list, controller: controller)
            .overlay(alignment: .trailing) {
                BrowseLetterIndex(sectionTitles: list.sectionTitles) { title in
                    controller.jump(toIndexTitle: title)
                }
                .padding(.top, AppBrowseRowMetrics.headerHeight)
            }
    }
}
