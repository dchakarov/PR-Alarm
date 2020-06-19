//
//  GitHubClient.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 04/06/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import Foundation
import Combine

struct GitHubClient {
    private let session: URLSession = URLSession.shared
    let baseUrl: String
    let token: String
    
    init(token: String, baseUrl: String = "api.github.com") {
        self.baseUrl = baseUrl
        self.token = token
    }
    
    func user() -> AnyPublisher<Result<User, NetworkError>, Never> {
        guard let urlRequest = urlRequest(for: .user) else {
            return Just(.failure(NetworkError.invalidRequest))
                .catch { _ in Empty().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
        return gitHubDataTaskPublisher(for: urlRequest)
    }
    
    func repos(org: String?) -> AnyPublisher<Result<[Repository], NetworkError>, Never> {
        guard let urlRequest = urlRequest(for: .repository(org: org)) else {
            return Just(.failure(NetworkError.invalidRequest))
                .catch { _ in Empty().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
        return gitHubDataTaskPublisher(for: urlRequest)
    }
    
    func pulls(for repo: String) -> AnyPublisher<Result<[PullRequestId], NetworkError>, Never> {
        guard let urlRequest = urlRequest(for: .pullRequests(repo: repo)) else {
            return Just(.failure(NetworkError.invalidRequest))
                .catch { _ in Empty().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
        return gitHubDataTaskPublisher(for: urlRequest)
    }
    
    func pull(repo: String, number: Int) -> AnyPublisher<Result<PullRequest, NetworkError>, Never> {
        guard let urlRequest = urlRequest(for: .pullRequest(repo: repo, number: number)) else {
            return Just(.failure(NetworkError.invalidRequest))
                .catch { _ in Empty().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
        return gitHubDataTaskPublisher(for: urlRequest)
    }
    
    func merge(repo: String, number: Int) -> AnyPublisher<Result<MergeResponse, NetworkError>, Never> {
        guard var urlRequest = urlRequest(for: .mergePullRequest(repo: repo, number: number)) else {
            return Just(.failure(NetworkError.invalidRequest))
                .catch { _ in Empty().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
        urlRequest.httpMethod = "PUT"
        return gitHubDataTaskPublisher(for: urlRequest)
    }
    
    func gitHubDataTaskPublisher<T: Decodable>(for urlRequest: URLRequest) -> AnyPublisher<Result<T, NetworkError>, Never> {
        session.dataTaskPublisher(for: urlRequest)
            .mapError { _ in NetworkError.invalidRequest }
            .flatMap { data, response -> AnyPublisher<Data, Error> in
                guard let response = response as? HTTPURLResponse else {
                    return Fail(error: NetworkError.invalidResponse).eraseToAnyPublisher()
                }
                guard 200..<300 ~= response.statusCode else {
                    return Fail(error: NetworkError.dataLoadingError(statusCode: response.statusCode, data: data)).eraseToAnyPublisher()
                }
                return Just(data)
                    .catch { _ in Empty().eraseToAnyPublisher() }
                    .eraseToAnyPublisher()
        }
        .decode(type: T.self, decoder: JSONDecoder())
        .map { .success($0) }
        .catch { error -> AnyPublisher<Result<T, NetworkError>, Never> in
            return Just(.failure(NetworkError.jsonDecodingError(error: error)))
                .catch { _ in Empty().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func urlRequest(for endpoint: Endpoint) -> URLRequest? {
        let endpointUrl: URL? = {
            switch endpoint {
            case .user:
                return URL(string: "https://\(baseUrl)/user")
            case .repository(let org):
                if let org = org, !org.isEmpty {
                    return URL(string: "https://\(baseUrl)/orgs/\(org)/repos")
                } else {
                    return URL(string: "https://\(baseUrl)/user/repos")
                }
            case .pullRequests(let repo):
                return URL(string: "https://\(baseUrl)/repos/\(repo)/pulls")
            case .pullRequest(let repo, let number):
                return URL(string: "https://\(baseUrl)/repos/\(repo)/pulls/\(number)")
            case .mergePullRequest(let repo, let number):
                return URL(string: "https://\(baseUrl)/repos/\(repo)/pulls/\(number)/merge")
            }
        }()
        guard let url = endpointUrl else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
}

enum Endpoint {
    case user
    case repository(org: String?)
    case pullRequests(repo: String)
    case pullRequest(repo: String, number: Int)
    case mergePullRequest(repo: String, number: Int)
}

enum NetworkError: Error {
    case invalidRequest
    case invalidResponse
    case dataLoadingError(statusCode: Int, data: Data)
    case jsonDecodingError(error: Error)
}

