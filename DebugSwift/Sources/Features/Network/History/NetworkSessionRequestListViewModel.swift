//
//  NetworkSessionRequestListViewModel.swift
//  DebugSwift
//
//  Created by Adjie Satryo on 01/10/26.
//

import Foundation
import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class NetworkSessionRequestListViewModel {
    let sessionID: UUID
    private(set) var requests: [NetworkSessionPersistenceManager.RequestRecord] = []
    private(set) var filteredRequests: [NetworkSessionPersistenceManager.RequestRecord] = []

    init(sessionID: UUID) {
        self.sessionID = sessionID
    }

    var numberOfRequests: Int {
        filteredRequests.count
    }

    var isEmpty: Bool {
        filteredRequests.isEmpty
    }

    var totalRequestsCount: Int {
        requests.count
    }

    func request(at index: Int) -> NetworkSessionPersistenceManager.RequestRecord {
        filteredRequests[index]
    }

    func httpModel(at index: Int) -> HttpModel {
        filteredRequests[index].makeHttpModel()
    }

    func loadRequests() async {
        requests = await NetworkSessionPersistenceManager.shared.fetchRequests(for: sessionID)
    }

    func applyFilter(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            filteredRequests = requests
            return
        }

        let lowercaseQuery = trimmed.lowercased()
        filteredRequests = requests.filter { request in
            let url = request.url?.lowercased() ?? ""
            let method = request.method?.lowercased() ?? ""
            let statusCode = request.statusCode?.lowercased() ?? ""
            return url.contains(lowercaseQuery) ||
                method.contains(lowercaseQuery) ||
                statusCode.contains(lowercaseQuery)
        }
    }

    func exportHAR(from indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        let sortedIndexPaths = indexPaths.sorted { $0.row < $1.row }
        let selectedModels = sortedIndexPaths.compactMap { indexPath -> HttpModel? in
            guard indexPath.row < filteredRequests.count else { return nil }
            return filteredRequests[indexPath.row].makeHttpModel()
        }
        HARExportAdapter.exportHAR(selectedModels)
    }

    func importSessionRules() -> Int {
        let rules = NetworkSessionRewriteRuleBuilder.makeRules(
            from: requests.map { $0.makeHttpModel() }
        )
        NetworkInjectionManager.shared.replaceRewriteRulesFromSessionHistory(rules)
        return rules.count
    }
}
#endif
