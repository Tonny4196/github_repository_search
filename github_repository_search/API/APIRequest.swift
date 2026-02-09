//
//  APIRequest.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/08.
//

import APIKit
import Foundation

protocol APIRequest: Request {
    
}

extension APIRequest where Response: Decodable {
    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }

    var dataParser: DataParser {
        return RawDataParser()
    }

    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Response.self, from: data)
    }
}

struct RawDataParser: DataParser {
    var contentType: String? { return nil }
    func parse(data: Data) throws -> Any {
        return data
    }
}
