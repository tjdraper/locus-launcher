import Foundation

/// The rows the browse table shows: every app in alphabetical sections, or search results in
/// ranked order with no sections.
nonisolated struct BrowseList: Equatable, Sendable {
    enum Row: Equatable, Sendable {
        case header(String)
        case app(IndexedApp)
    }

    static let otherTitle = "#"
    static let indexTitles = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init) + [otherTitle]

    let rows: [Row]
    let sectionTitles: Set<String>
    let hasSections: Bool
    private let headerRows: [String: Int]

    /// Keeps the order of `apps` within each section.
    init(apps: [IndexedApp]) {
        let grouped = Dictionary(grouping: apps) { Self.sectionTitle(for: $0.name) }
        var rows: [Row] = []
        var headerRows: [String: Int] = [:]
        for title in Self.indexTitles {
            guard let sectionApps = grouped[title] else { continue }
            headerRows[title] = rows.count
            rows.append(.header(title))
            rows += sectionApps.map(Row.app)
        }
        self.rows = rows
        self.headerRows = headerRows
        sectionTitles = Set(headerRows.keys)
        hasSections = true
    }

    init(searchResults: [IndexedApp]) {
        rows = searchResults.map(Row.app)
        headerRows = [:]
        sectionTitles = []
        hasSections = false
    }

    static func sectionTitle(for name: String) -> String {
        guard let first = name.first else { return otherTitle }
        let folded = String(first)
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil)
            .uppercased()
        return indexTitles.contains(folded) ? folded : otherTitle
    }

    func app(at row: Int) -> IndexedApp? {
        guard rows.indices.contains(row), case let .app(app) = rows[row] else { return nil }
        return app
    }

    func isHeader(_ row: Int) -> Bool {
        guard rows.indices.contains(row), case .header = rows[row] else { return false }
        return true
    }

    /// The first app row of a section, or of search results, which has empty space above it.
    func startsSection(_ row: Int) -> Bool {
        isHeader(row - 1) || (!hasSections && row == 0)
    }

    func row(of url: URL) -> Int? {
        rows.firstIndex { row in
            if case let .app(app) = row { return app.url == url }
            return false
        }
    }

    var firstAppRow: Int? {
        appRow(after: -1)
    }

    func appRow(after row: Int) -> Int? {
        rows.indices.first { $0 > row && app(at: $0) != nil }
    }

    func appRow(before row: Int) -> Int? {
        rows.indices.last { $0 < row && app(at: $0) != nil }
    }

    /// Like iOS, a letter with no apps lands on the next section that has some, or the last one
    /// when nothing follows it.
    func headerRow(forIndexTitle title: String) -> Int? {
        guard let position = Self.indexTitles.firstIndex(of: title) else { return nil }
        let following = Self.indexTitles[position...].lazy.compactMap { headerRows[$0] }.first
        return following ?? Self.indexTitles[..<position].reversed().lazy.compactMap { headerRows[$0] }.first
    }
}
