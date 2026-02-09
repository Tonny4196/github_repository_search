//
//  RepositoryListViewModelTests.swift
//  github_repository_searchTests
//
//  Created by Tomohiro Takahashi on 2026/02/09.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
@testable import github_repository_search

// MARK: - Mock

final class MockRepositoryRepository: RepositoryRepositoryProtocol {
    var searchResult: Single<SearchResponse> = .never()
    var searchCallCount = 0
    var lastQuery: String?
    var lastPage: Int?

    func searchRepositories(query: String, page: Int, perPage: Int) -> Single<SearchResponse> {
        searchCallCount += 1
        lastQuery = query
        lastPage = page
        return searchResult
    }
}

// MARK: - Tests

final class RepositoryListViewModelTests: XCTestCase {

    private var disposeBag: DisposeBag!
    private var mockRepository: MockRepositoryRepository!
    private var viewModel: RepositoryListViewModel!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockRepository = MockRepositoryRepository()
    }

    override func tearDown() {
        disposeBag = nil
        mockRepository = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeResponse(items: [Repository], totalCount: Int = 100) -> SearchResponse {
        return SearchResponse(totalCount: totalCount, incompleteResults: false, items: items)
    }

    private func makeRepository(name: String, stargazersCount: Int = 0, language: String? = "Swift") -> Repository {
        return Repository(
            name: name,
            url: URL(string: "https://github.com/test/\(name)")!,
            description: "\(name) description",
            stargazersCount: stargazersCount,
            language: language
        )
    }

    // MARK: - Search Tests

    func testSearchReturnsRepositories() {
        let repos = [makeRepository(name: "repo1"), makeRepository(name: "repo2")]
        mockRepository.searchResult = .just(makeResponse(items: repos, totalCount: 2))
        viewModel = RepositoryListViewModel(repository: mockRepository)

        let expectation = XCTestExpectation(description: "repositories emitted")
        var receivedRepos: [Repository] = []

        viewModel.outputs.repositories
            .drive(onNext: { repos in
                receivedRepos = repos
                if !repos.isEmpty {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        viewModel.inputs.searchText.accept("swift")

        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(receivedRepos.count, 2)
        XCTAssertEqual(receivedRepos.first?.name, "repo1")
        XCTAssertEqual(mockRepository.lastQuery, "swift")
        XCTAssertEqual(mockRepository.lastPage, 1)
    }

    func testEmptyQueryDoesNotTriggerSearch() {
        mockRepository.searchResult = .just(makeResponse(items: [], totalCount: 0))
        viewModel = RepositoryListViewModel(repository: mockRepository)

        viewModel.inputs.searchText.accept("")

        XCTAssertEqual(mockRepository.searchCallCount, 0)
    }

    func testNewSearchClearsPreviousResults() {
        let firstRepos = [makeRepository(name: "first")]
        let secondRepos = [makeRepository(name: "second")]
        var callCount = 0
        mockRepository.searchResult = Single.deferred {
            callCount += 1
            if callCount == 1 {
                return .just(self.makeResponse(items: firstRepos, totalCount: 1))
            } else {
                return .just(self.makeResponse(items: secondRepos, totalCount: 1))
            }
        }
        viewModel = RepositoryListViewModel(repository: mockRepository)

        let expectation = XCTestExpectation(description: "second search results")
        var allEmissions: [[Repository]] = []

        viewModel.outputs.repositories
            .drive(onNext: { repos in
                allEmissions.append(repos)
                if repos.first?.name == "second" {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        viewModel.inputs.searchText.accept("first")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.inputs.searchText.accept("second")
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(allEmissions.last?.first?.name, "second")
    }

    // MARK: - Pagination Tests

    func testLoadMoreAppendsResults() {
        let firstPage = [makeRepository(name: "repo1")]
        let secondPage = [makeRepository(name: "repo2")]
        var callCount = 0
        mockRepository.searchResult = Single.deferred {
            callCount += 1
            if callCount == 1 {
                return .just(self.makeResponse(items: firstPage, totalCount: 100))
            } else {
                return .just(self.makeResponse(items: secondPage, totalCount: 100))
            }
        }
        viewModel = RepositoryListViewModel(repository: mockRepository)

        let expectation = XCTestExpectation(description: "pagination results")
        var lastRepos: [Repository] = []

        viewModel.outputs.repositories
            .drive(onNext: { repos in
                lastRepos = repos
                if repos.count == 2 {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        viewModel.inputs.searchText.accept("swift")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.inputs.loadMore.accept(())
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(lastRepos.count, 2)
        XCTAssertEqual(lastRepos[0].name, "repo1")
        XCTAssertEqual(lastRepos[1].name, "repo2")
        XCTAssertEqual(mockRepository.lastPage, 2)
    }

    // MARK: - HasMore Tests

    func testHasMoreIsFalseWhenAllLoaded() {
        let repos = [makeRepository(name: "repo1")]
        mockRepository.searchResult = .just(makeResponse(items: repos, totalCount: 1))
        viewModel = RepositoryListViewModel(repository: mockRepository)

        let expectation = XCTestExpectation(description: "hasMore emitted")
        var lastHasMore: Bool = true

        viewModel.outputs.hasMore
            .drive(onNext: { hasMore in
                lastHasMore = hasMore
            })
            .disposed(by: disposeBag)

        viewModel.inputs.searchText.accept("swift")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
        XCTAssertFalse(lastHasMore)
    }

    // MARK: - Error Tests

    func testErrorIsEmittedOnFailure() {
        mockRepository.searchResult = .error(APIError(domain: "test", statusCode: .badRequest))
        viewModel = RepositoryListViewModel(repository: mockRepository)

        let expectation = XCTestExpectation(description: "error emitted")

        viewModel.outputs.error
            .drive(onNext: { _ in
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        viewModel.inputs.searchText.accept("swift")

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Retry Tests

    func testRetryResendsRequest() {
        var callCount = 0
        let repos = [makeRepository(name: "retried")]
        mockRepository.searchResult = Single.deferred {
            callCount += 1
            if callCount == 1 {
                return .error(APIError(domain: "test", statusCode: .internalServerError))
            } else {
                return .just(self.makeResponse(items: repos, totalCount: 1))
            }
        }
        viewModel = RepositoryListViewModel(repository: mockRepository)

        let expectation = XCTestExpectation(description: "retry succeeds")
        var lastRepos: [Repository] = []

        viewModel.outputs.repositories
            .drive(onNext: { repos in
                lastRepos = repos
                if !repos.isEmpty {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        viewModel.inputs.searchText.accept("swift")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.inputs.retry.accept(())
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(lastRepos.first?.name, "retried")
        XCTAssertEqual(mockRepository.searchCallCount, 2)
    }
}
