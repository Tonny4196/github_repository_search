//
//  UITableView+Extensions.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import UIKit

extension UITableView {
    func registerCell<T: UITableViewCell>(of type: T.Type) {
        self.register(UINib(nibName: T.className, bundle: nil), forCellReuseIdentifier: T.className)
    }

    func dequeueReusableCell<T: UITableViewCell>(with type: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.className, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.className)")
        }
        return cell
    }
}
