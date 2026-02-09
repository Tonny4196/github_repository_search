//
//  RepositorySeachRequest.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/08.
//

import Foundation
import APIKit

struct RepositorySearchRequest: APIRequest {
    // MARK: - Properties
    let query: String
    let page: Int
    let perPage: Int

    // MARK: - APIKit Requirements
    var method: HTTPMethod = .get

    var path: String {
        return "/search/repositories"
    }

    typealias Response = SearchResponse

    var parameters: Any? {
        var params = [String: Any]()
        params["q"] = query
        params["page"] = page
        params["per_page"] = perPage
        return params
    }

    // MARK: - Initializer
    init(query: String, page: Int = 1, perPage: Int = 30) {
        self.query = query
        self.page = page
        self.perPage = perPage
    }
}
