//
//  RepositoryListViewController.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/07.
//

import UIKit
import RxSwift
import RxCocoa

class RepositoryListViewController: UIViewController {

    // MARK: - Type Alias
    typealias Dependency = RepositoryListViewModelType

    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    // MARK: - Properties
    private let viewModel: Dependency
    private let disposeBag = DisposeBag()

    // MARK: - Initializer
    init(viewModel: Dependency) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Repository Search"
        view.backgroundColor = .systemBackground

        // Search Bar
        view.addSubview(searchBar)
        searchBar.placeholder = "Search repositories..."
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        // Table View
        view.addSubview(tableView)
        tableView.registerCell(of: RepositoryTableViewCell.self)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Loading Indicator
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true

        // Error Label
        view.addSubview(errorLabel)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.textColor = .systemRed
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.isHidden = true

        // Retry Button
        view.addSubview(retryButton)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.isHidden = true

        // Layout Constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Binding
    private func bind() {
        // Bind Search Bar to ViewModel Input
        searchBar.rx.text
            .orEmpty
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: viewModel.inputs.searchText)
            .disposed(by: disposeBag)

        // Bind Retry Button
        retryButton.rx.tap
            .bind(to: viewModel.inputs.retry)
            .disposed(by: disposeBag)

        // Bind Repositories to Table View
        viewModel.outputs.repositories
            .drive(tableView.rx.items(cellIdentifier: RepositoryTableViewCell.className, cellType: RepositoryTableViewCell.self)) { index, repository, cell in
                cell.configure(repository: repository)
            }
            .disposed(by: disposeBag)

        // Bind Loading State
        viewModel.outputs.isLoading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)

        // Bind Error State
        viewModel.outputs.error
            .drive(onNext: { [weak self] error in
                self?.errorLabel.text = "Error: \(error.localizedDescription)"
                self?.errorLabel.isHidden = false
                self?.retryButton.isHidden = false
            })
            .disposed(by: disposeBag)

        // Hide error when loading starts
        viewModel.outputs.isLoading
            .filter { $0 }
            .drive(onNext: { [weak self] _ in
                self?.errorLabel.isHidden = true
                self?.retryButton.isHidden = true
            })
            .disposed(by: disposeBag)

        // Detect scroll to bottom for pagination
        tableView.rx.contentOffset
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withLatestFrom(
                Observable.combineLatest(
                    viewModel.outputs.hasMore.asObservable(),
                    viewModel.outputs.isLoading.asObservable()
                )
            ) { offset, state in
                return (offset, hasMore: state.0, isLoading: state.1)
            }
            .filter { [weak self] offset, hasMore, isLoading in
                guard let self = self, hasMore, !isLoading else { return false }
                let contentHeight = self.tableView.contentSize.height
                let scrollOffset = offset.y
                let tableHeight = self.tableView.frame.size.height
                return scrollOffset > contentHeight - tableHeight - 100
            }
            .map { _ in () }
            .bind(to: viewModel.inputs.loadMore)
            .disposed(by: disposeBag)

        // Open repository URL when cell tapped
        tableView.rx.modelSelected(Repository.self)
            .subscribe(onNext: { repository in
                UIApplication.shared.open(repository.url)
            })
            .disposed(by: disposeBag)
    }
}
