//
//  RepositoryListViewModel.swift
//  github_repository_search
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import Foundation
import RxRelay
import RxCocoa
import RxSwift
import Action

// MARK: - Protocols

protocol RepositoryListViewModelInputs {
    var searchText: PublishRelay<String> { get }
    var loadMore: PublishRelay<Void> { get }
    var retry: PublishRelay<Void> { get }
}

protocol RepositoryListViewModelOutputs {
    var repositories: Driver<[Repository]> { get }
    var isLoading: Driver<Bool> { get }
    var error: Driver<Error> { get }
    var hasMore: Driver<Bool> { get }
}

protocol RepositoryListViewModelType {
    var inputs: RepositoryListViewModelInputs { get }
    var outputs: RepositoryListViewModelOutputs { get }
}

// MARK: - Implementation

class RepositoryListViewModel: RepositoryListViewModelType, RepositoryListViewModelInputs, RepositoryListViewModelOutputs {

    // MARK: - Protocol Conformance
    var inputs: RepositoryListViewModelInputs { return self }
    var outputs: RepositoryListViewModelOutputs { return self }

    // MARK: - Inputs
    let searchText = PublishRelay<String>()
    let loadMore = PublishRelay<Void>()
    let retry = PublishRelay<Void>()

    // MARK: - Outputs
    let repositories: Driver<[Repository]>
    let isLoading: Driver<Bool>
    let error: Driver<Error>
    let hasMore: Driver<Bool>

    // MARK: - Private Properties
    private let searchAction: Action<(String, Int), SearchResponse>
    private let disposeBag = DisposeBag()
    private let _repositories = BehaviorRelay<[Repository]>(value: [])
    private let _currentPage = BehaviorRelay<Int>(value: 1)
    private let _currentQuery = BehaviorRelay<String>(value: "")
    private let _totalCount = BehaviorRelay<Int>(value: 0)

    // MARK: - Initializer
    init(repository: RepositoryRepositoryProtocol) {
        // Setup Search Action
        self.searchAction = Action { (query, page) in
            repository.searchRepositories(query: query, page: page, perPage: 30)
                .asObservable()
        }

        // Setup Outputs
        self.isLoading = searchAction.executing
            .asDriver(onErrorDriveWith: .empty())

        self.error = searchAction.errors
            .map { $0 as Error }
            .asDriver(onErrorDriveWith: .empty())

        self.hasMore = Observable.combineLatest(
            _repositories.asObservable(),
            _totalCount.asObservable()
        ) { repos, total in
            return repos.count < total
        }
        .asDriver(onErrorDriveWith: .just(false))

        self.repositories = _repositories
            .asDriver(onErrorDriveWith: .empty())

        // MARK: - Bind Inputs to Actions

        // New search: reset page and replace repositories
        searchText
            .filter { !$0.isEmpty }
            .do(onNext: { [weak self] query in
                self?._currentQuery.accept(query)
                self?._currentPage.accept(1)
                self?._repositories.accept([]) // Clear previous results
            })
            .withLatestFrom(Observable.combineLatest(
                _currentQuery.asObservable(),
                _currentPage.asObservable()
            )) { _, combined in
                return combined
            }
            .bind(to: searchAction.inputs)
            .disposed(by: disposeBag)

        // Load more: increment page and append repositories
        loadMore
            .withLatestFrom(_currentQuery.asObservable())
            .filter { !$0.isEmpty }
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                let nextPage = self._currentPage.value + 1
                self._currentPage.accept(nextPage)
            })
            .withLatestFrom(Observable.combineLatest(
                _currentQuery.asObservable(),
                _currentPage.asObservable()
            )) { _, combined in
                return combined
            }
            .bind(to: searchAction.inputs)
            .disposed(by: disposeBag)

        // Retry: use current query and page
        retry
            .withLatestFrom(Observable.combineLatest(
                _currentQuery.asObservable(),
                _currentPage.asObservable()
            ))
            .bind(to: searchAction.inputs)
            .disposed(by: disposeBag)

        // Handle successful search results
        searchAction.elements
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }

                // Update total count for pagination
                self._totalCount.accept(response.totalCount)

                // Append or replace based on page
                if self._currentPage.value == 1 {
                    self._repositories.accept(response.items)
                } else {
                    let current = self._repositories.value
                    self._repositories.accept(current + response.items)
                }
            })
            .disposed(by: disposeBag)
    }
}
