//
//  RepositoryRepository.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import Foundation
import APIKit
import RxSwift

protocol RepositoryRepositoryProtocol {
    func searchRepositories(query: String, page: Int, perPage: Int) -> Single<SearchResponse>
}

class RepositoryRepository: RepositoryRepositoryProtocol {
    func searchRepositories(query: String, page: Int = 1, perPage: Int = 30) -> Single<SearchResponse> {
        let request = RepositorySearchRequest(query: query, page: page, perPage: perPage)
        return Session.send(request)
    }
}
