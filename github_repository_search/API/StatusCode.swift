//
//  StatuCode.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import Foundation

enum StatusCode: Int {
    // Successful
    case ok = 200
    case created = 201
    case accepted = 202
    case noContent = 204
    
    // Redirection
    case movedPermanently = 301
    case found = 302
    case notModified = 304
    
    // Client Error
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case conflict = 409
    case gone = 410
    case preconditionFailed = 412
    case unsupportedMediaType = 415
    case tooManyRequests = 429
    
    // Server Error
    case internalServerError = 500
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    
    // Unknown
    case unknown = 0
    
    init(code: Int) {
        self = StatusCode(rawValue: code) ?? .unknown
    }
}
