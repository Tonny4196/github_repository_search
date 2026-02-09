//
//  SearchResponse.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import Foundation

struct SearchResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [Repository]

    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }

    init(totalCount: Int, incompleteResults: Bool, items: [Repository]) {
        self.totalCount = totalCount
        self.incompleteResults = incompleteResults
        self.items = items
    }
}
