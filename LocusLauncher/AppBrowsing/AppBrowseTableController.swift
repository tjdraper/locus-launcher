import AppKit

/// Owns the browse table: fills it from the list, keeps one app selected, and launches apps from
/// clicks and the keyboard. It outlives the SwiftUI view, so the selection and scroll position
/// survive while the panel is hidden.
final class AppBrowseTableController: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let icons: AppIconCache
    private let onLaunch: (IndexedApp) -> Void
    private var list = BrowseList(apps: [])
    private weak var tableView: AppBrowseTableView?

    init(icons: AppIconCache, onLaunch: @escaping (IndexedApp) -> Void) {
        self.icons = icons
        self.onLaunch = onLaunch
    }

    func makeScrollView() -> NSScrollView {
        let tableView = AppBrowseTableView()
        tableView.style = .plain
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.intercellSpacing = .zero
        tableView.floatsGroupRows = true
        tableView.allowsEmptySelection = false
        // Keyboard focus stays in the search field; the arrow keys reach the table through the panel.
        tableView.refusesFirstResponder = true
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("App"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.action = #selector(launchClickedRow)
        tableView.onHoverRow = { [weak self] row in
            self?.select(row, reveal: false)
        }
        self.tableView = tableView

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        // The scroller would draw over the letter index, which already shows the position.
        scrollView.hasVerticalScroller = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: AppBrowseRowMetrics.bottomPadding, right: 0)
        return scrollView
    }

    /// Keeps the selected app selected while the browse list updates. Anything else, including each
    /// new set of search results, starts from the first app.
    func show(_ newList: BrowseList) {
        guard newList != list, let tableView else { return }

        let selectedURL = list.hasSections && newList.hasSections ? list.app(at: tableView.selectedRow)?.url : nil
        list = newList
        tableView.showsSections = list.hasSections
        tableView.reloadData()
        if let row = selectedURL.flatMap(list.row(of:)) {
            select(row, reveal: false)
        } else if let row = list.firstAppRow {
            // Scrolling to the top rather than revealing the row, because on the first fill the
            // table has no size yet and every row looks out of view.
            select(row, reveal: false)
            scroll(tableView, toY: 0)
        }
    }

    func moveSelectionUp() {
        guard let tableView, let row = list.appRow(before: tableView.selectedRow) else { return }
        select(row, reveal: true)
    }

    func moveSelectionDown() {
        guard let tableView, let row = list.appRow(after: tableView.selectedRow) else { return }
        select(row, reveal: true)
    }

    func launchSelection() {
        guard let tableView, let app = list.app(at: tableView.selectedRow) else { return }
        onLaunch(app)
    }

    /// Scrolls the section to the top and selects its first app, so the keyboard carries on from
    /// there.
    func jump(toIndexTitle title: String) {
        guard let tableView, let header = list.headerRow(forIndexTitle: title) else { return }
        scroll(tableView, toY: tableView.rect(ofRow: header).minY)
        if let row = list.appRow(after: header) {
            select(row, reveal: false)
        }
    }

    @objc private func launchClickedRow() {
        guard let tableView, let event = NSApp.currentEvent,
              tableView.visibleRow(atWindowLocation: event.locationInWindow) == tableView.clickedRow,
              let app = list.app(at: tableView.clickedRow) else {
            return
        }
        onLaunch(app)
    }

    private func select(_ row: Int, reveal: Bool) {
        guard let tableView, list.app(at: row) != nil else { return }
        if row != tableView.selectedRow {
            tableView.selectRowIndexes([row], byExtendingSelection: false)
        }
        if reveal {
            self.reveal(row, in: tableView)
        }
    }

    /// `scrollRowToVisible` would leave a row hidden under the pinned section header. Moving onto a
    /// section's first app also brings its header into view.
    private func reveal(_ row: Int, in tableView: NSTableView) {
        guard let visible = tableView.enclosingScrollView?.contentView.bounds else { return }
        var target = tableView.rect(ofRow: row)
        if row == list.rows.count - 1 {
            target.size.height += AppBrowseRowMetrics.bottomPadding
        }
        // Leaves the same gap under a pinned header as under a section's own header.
        var coveredTop = list.hasSections ? AppBrowseRowMetrics.headerHeight + AppBrowseRowMetrics.sectionTopGap : 0
        if list.isHeader(row - 1) {
            target = target.union(tableView.rect(ofRow: row - 1))
            coveredTop = 0
        }

        if target.minY < visible.minY + coveredTop {
            scroll(tableView, toY: target.minY - coveredTop)
        } else if target.maxY > visible.maxY {
            scroll(tableView, toY: target.maxY - visible.height)
        }
    }

    private func scroll(_ tableView: NSTableView, toY y: CGFloat) {
        guard let clipView = tableView.enclosingScrollView?.contentView else { return }
        let maxY = max(0, tableView.bounds.height + AppBrowseRowMetrics.bottomPadding - clipView.bounds.height)
        clipView.scroll(to: NSPoint(x: 0, y: min(max(0, y), maxY)))
        tableView.enclosingScrollView?.reflectScrolledClipView(clipView)
    }

    func numberOfRows(in _: NSTableView) -> Int {
        list.rows.count
    }

    func tableView(_: NSTableView, isGroupRow row: Int) -> Bool {
        list.isHeader(row)
    }

    func tableView(_: NSTableView, shouldSelectRow row: Int) -> Bool {
        list.app(at: row) != nil
    }

    func tableView(_: NSTableView, heightOfRow row: Int) -> CGFloat {
        if list.isHeader(row) {
            return AppBrowseRowMetrics.headerHeight
        }
        return AppBrowseRowMetrics.appHeight + (list.startsSection(row) ? AppBrowseRowMetrics.sectionTopGap : 0)
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if list.isHeader(row) {
            return tableView.makeView(withIdentifier: AppBrowseHeaderRowView.identifier, owner: nil) as? NSTableRowView
                ?? AppBrowseHeaderRowView()
        }
        let rowView = tableView.makeView(withIdentifier: AppBrowseRowView.identifier, owner: nil) as? AppBrowseRowView
            ?? AppBrowseRowView()
        rowView.reservesLetterIndex = list.hasSections
        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        switch list.rows[row] {
        case let .header(title):
            let view = tableView.makeView(withIdentifier: AppBrowseHeaderView.identifier, owner: nil) as? AppBrowseHeaderView
                ?? AppBrowseHeaderView()
            view.textField?.stringValue = title
            return view
        case let .app(app):
            let view = tableView.makeView(withIdentifier: AppBrowseCellView.identifier, owner: nil) as? AppBrowseCellView
                ?? AppBrowseCellView()
            if let icon = icons.cachedIcon(for: app) {
                view.show(app, icon: icon)
            } else {
                view.show(app, icon: icons.placeholder)
                Task { [icons] in
                    let icon = await icons.icon(for: app)
                    if view.appURL == app.url {
                        view.imageView?.image = icon
                    }
                }
            }
            return view
        }
    }
}
