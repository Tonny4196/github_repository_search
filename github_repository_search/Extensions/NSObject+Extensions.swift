//
//  NSObject+Extensions.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import Foundation

extension NSObject {
    class var className: String {
        return String(describing: self)
    }

    var className: String {
        return type(of: self).className
    }
}
