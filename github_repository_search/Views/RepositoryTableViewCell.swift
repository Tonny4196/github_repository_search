//
//  RepositoryTableViewCell.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import UIKit

class RepositoryTableViewCell: UITableViewCell {

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var starCountLabel: UILabel!
    @IBOutlet private var languageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension RepositoryTableViewCell {
    func configure(repository: Repository) {
        nameLabel.text = repository.name
        descriptionLabel.text = repository.description
        starCountLabel.text = "★ \(repository.stargazersCount.formatted())"
        if let language = repository.language {
            languageLabel.text = language
            languageLabel.isHidden = false
        } else {
            languageLabel.isHidden = true
        }
    }
}
