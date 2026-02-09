//
//  APIError.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import Foundation

struct APIError: Error {
    // MARK: - Properties
    let domain: String
    let statusCode: StatusCode
    let responseObject: Any?
    let originalError: Error?
    var responseString: String? {
        guard let data = responseObject as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    var errorMessage: String {
        let defaultMessage = "通信中にエラーが発生しました。時間をおいて再度お試しください。"
        guard let data = responseObject as? Data else {
            return defaultMessage
        }
        // JSONとしてデコード
        guard let message = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
            return defaultMessage
        }
        return message.message
    }
    
    var status: StatusCode {
        let defaultCode: StatusCode = .badRequest
        guard let data = responseObject as? Data,
              let message = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
            return defaultCode
        }
        
        return StatusCode(code: message.status)
    }
    // MARK: - NSError
    var _domain: String {
        return domain
    }
    var _code: Int {
        return statusCode.rawValue
    }
    // MARK: - Initialize
    init(domain: String, statusCode: StatusCode, responseObject: Any? = nil, originalError: Error? = nil) {
        self.domain = domain
        self.statusCode = statusCode
        self.responseObject = responseObject
        self.originalError = originalError
    }
    init(error: Error) {
        if let error = error as? APIError {
            self.domain = error.domain
            self.statusCode = error.statusCode
            self.responseObject = error.responseObject
            self.originalError = error.originalError
        } else {
            self.domain = error._domain
            self.statusCode = StatusCode(code: error._code)
            self.responseObject = nil
            self.originalError = error
        }
    }
    
    // MARK: - Factory methods
        static func from(statusCode: Int, message: String) -> APIError {
        let domain = "tonny.github-repository-search.api"
        let statusCodeEnum = StatusCode(code: statusCode)
        
        // Convert raw message to Data for compatibility with errorMessage property
        let messageData = message.data(using: .utf8)
        
        // Create JSON data that can be decoded by JSONDecoder().decode(ErrorMessage.self, from: data)
        if let messageData = messageData {
            let jsonData = try? JSONSerialization.data(withJSONObject: ["message": message], options: [])
            return APIError(domain: domain, statusCode: statusCodeEnum, responseObject: jsonData ?? messageData)
        }
        
        return APIError(domain: domain, statusCode: statusCodeEnum, responseObject: message)
    }
}

