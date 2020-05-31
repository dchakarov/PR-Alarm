//
//  RepositoryHelper.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 30/05/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import Foundation
import Combine

class RepositoryHelper: ObservableObject {
    var repositories = [Repository]()
    @Published var pulls = [String: [PullRequest]]()
    @Published var reposWithPRs: [Repository] = []
    @Published var githubToken: String = "" {
        didSet {
            self.poll()
        }
    }
    var cancellable: AnyCancellable?
    var prCancellables: [AnyCancellable] = []
    
    func poll() {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://api.github.com/user/repos")!)
        urlRequest.addValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        cancellable = URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: [Repository].self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { receive in
                print(receive)
            }, receiveValue: { repos in
                self.repositories = repos
                self.reposWithPRs = []
                print(repos)
                for repo in repos {
                    self.pulls(for: repo.full_name)
                }
            })
    }
    
    func pulls(for repo: String) {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/pulls")!)
        urlRequest.addValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        let publisher = URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: [PullRequestId].self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { receive in
                print(receive)
            }, receiveValue: { pulls in
                print(pulls)
                if !pulls.isEmpty {
                    self.reposWithPRs.append(self.repositories.first(where: { r -> Bool in
                        r.full_name == repo
                    })!)
                    self.pulls[repo] = []
                    for pullId in pulls {
                        self.pull(repo: repo, number: pullId.number)
                    }
                }
            })
        prCancellables.append(publisher)
    }
    
    func pull(repo: String, number: Int) {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/pulls/\(number)")!)
        urlRequest.addValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        let publisher = URLSession.shared.dataTaskPublisher(for: urlRequest)
        .map { $0.data }
        .decode(type: PullRequest.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { receive in
            print(receive)
        }, receiveValue: { pull in
            print(pull)
            self.pulls[repo]?.append(pull)
        })
        prCancellables.append(publisher)
    }
    
    func save(_ token: String) {
        githubToken = token
    }
}


struct Repository: Codable, Identifiable {
    let id: Int32
    let name: String
    let full_name: String
}

struct PullRequestId: Codable {
    let number: Int
}

struct PullRequest: Codable {
    let number: Int
    let id: Int32
    let title: String
    let user: User
    let author_association: String
    let mergeable: Bool?
    let mergeable_state: String
    var mergeableDisplayValue: String {
        if let mergeable = mergeable {
            return mergeable ? "🟢": "🔴"
        } else {
            return "🟠"
        }
    }
    var isMine: Bool {
        author_association == "OWNER"
    }
}

struct User: Codable {
    let id: Int32
    let login: String
}
