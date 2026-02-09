//
//  Session+Extensions.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/08.
//

import Foundation
import APIKit
import RxSwift

extension Session {
    static func send<T: Request>(_ request: T) -> Single<T.Response> {
        #if DEBUG
        print(" -- Start API Request -- :\(request.baseURL.absoluteString + request.path) | parameter: \(request.parameters)")
        #endif
        return Single.create { single in
            let task = Session.send(request) { result in
                switch result {
                case .success(let response):
                    #if DEBUG
                    print(" -- Succeed API Request -- : ", request.baseURL.absoluteString + request.path, response.self)
                    #endif
                    return single(.success(response))
                case .failure(let error):
                    #if DEBUG
                    print(" -- Error API Request -- : ", request.baseURL.absoluteString + request.path, error)
                    #endif
                    // APIKitのエラーをAPIErrorに変換
                    let apiError = convertToAPIError(error)
                    return single(.failure(apiError))
                }
            }
            return Disposables.create {
                task?.cancel()
            }
        }
    }
}

extension Session {
    private static func convertToAPIError(_ error: Error) -> Error {
        // SessionTaskErrorの場合
        if let sessionTaskError = error as? SessionTaskError {
            switch sessionTaskError {
            case .connectionError:
                // 接続エラー（タイムアウトなど）
                if let urlError = (try? (sessionTaskError as NSError).userInfo[NSUnderlyingErrorKey] as? URLError),
                   urlError.code == .timedOut {
                    return APIError(domain: "tonny.github-repository-search.api", statusCode: .gatewayTimeout, originalError: error)
                }
                return APIError(domain: "tonny.github-repository-search.api", statusCode: .unknown, originalError: error)
            case .requestError(let requestError):
                // リクエストエラーのメッセージを取得
                return APIError(domain: "tonny.github-repository-search.api", statusCode: .badRequest, responseObject: requestError.localizedDescription, originalError: error)
            case .responseError(let responseError):
                // APIErrorとして既に変換されている場合はそのまま返す
                if let apiError = responseError as? APIError {
                    return apiError
                }
                
                // レスポンスエラーからステータスコードを取得して適切なStatusCodeに変換
                // APIKitのResponseErrorからステータスコードを取得する
                let nsError = responseError as NSError
                let statusCode = nsError.userInfo["statusCode"] as? Int ?? nsError.code
                
                return APIError(domain: "tonny.github-repository-search.api", statusCode: StatusCode(code: statusCode), originalError: error)
            default:
                return APIError(domain: "tonny.github-repository-search.api", statusCode: .unknown, originalError: error)
            }
        }
        // デコードエラーの処理
        if let decodingError = error as? DecodingError {
            return APIError(domain: "tonny.github-repository-search.api", statusCode: .badRequest, responseObject: decodingError.localizedDescription, originalError: decodingError)
        }
        // それ以外のエラー
        return APIError(domain: "tonny.github-repository-search.api", statusCode: .unknown, originalError: error)
    }
    
    static func handleError(_ error: Error) -> APIError {
        let convertedError = convertToAPIError(error)
        if let apiError = convertedError as? APIError {
            return apiError
        } else {
            return APIError(error: error)
        }
    }
}
