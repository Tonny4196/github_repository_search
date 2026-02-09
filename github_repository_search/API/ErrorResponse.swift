//
//  ErrorResponse.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import Foundation

struct ErrorResponse: Decodable {
    let status: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
    }
}
