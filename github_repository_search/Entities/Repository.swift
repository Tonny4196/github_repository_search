//
//  Repository.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/08.
//

import Foundation

struct Repository: Decodable {
    let name: String
    let url: URL
    let description: String?
    let stargazersCount: Int
    let language: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case url = "html_url"
        case description
        case stargazersCount = "stargazers_count"
        case language
    }
}
