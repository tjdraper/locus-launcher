import SwiftUI

/// The browse list or search results, with the letter index beside the browse list.
struct AppBrowseView: View {
    let list: BrowseList
    let shortcutLabels: [String: String]
    let controller: AppBrowseTableController

    var body: some View {
        AppBrowseTable(list: list, shortcutLabels: shortcutLabels, controller: controller)
            .overlay(alignment: .trailing) {
                if list.hasSections {
                    BrowseLetterIndex(sectionTitles: list.sectionTitles) { title in
                        controller.jump(toIndexTitle: title)
                    }
                    .padding(.top, AppBrowseRowMetrics.headerHeight)
                }
            }
    }
}
