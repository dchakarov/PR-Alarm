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
    @Published var userLogin: String = ""
    @Published var githubToken: String = ""
    @Published var enterpriseUrl: String?
    var org: String?
    var cancellables: [AnyCancellable] = []
    let publicUrl = "api.github.com"
    
    var baseUrl: String {
        if let url = self.enterpriseUrl {
            return "\(url)/api/v3"
        } else {
            return publicUrl
        }
    }
    
    func poll() {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://\(baseUrl)/user")!)
        urlRequest.addValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        let publisher = URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { receive in
                print(receive)
            }, receiveValue: { user in
                self.userLogin = user.login
                print(user)
                self.repos()
            })
        cancellables.append(publisher)
    }
    
    func repos() {
        guard !githubToken.isEmpty else { return }
        let urlString: String = {
            if let org = org, !org.isEmpty {
                return "https://\(baseUrl)/orgs/\(org)/repos"
            } else {
                return "https://\(baseUrl)/user/repos"
            }
        }()
        var urlRequest = URLRequest(url: URL(string: urlString)!)
        urlRequest.addValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        let publisher = URLSession.shared.dataTaskPublisher(for: urlRequest)
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
        cancellables.append(publisher)
    }
    
    func pulls(for repo: String) {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://\(baseUrl)/repos/\(repo)/pulls")!)
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
        cancellables.append(publisher)
    }
    
    func pull(repo: String, number: Int) {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://\(baseUrl)/repos/\(repo)/pulls/\(number)")!)
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
        cancellables.append(publisher)
    }
    
    func settingsUpdated(token: String, enterpriseEnabled: Bool, baseUrl: String?, org: String?) {
        githubToken = token
        self.org = org
        if enterpriseEnabled {
            enterpriseUrl = baseUrl
        } else {
            enterpriseUrl = nil
        }
        self.poll()
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
            if !mergeable { return "🔴" }
            return mergeable_state == "clean" ? "🟢": "🔴"
        } else {
            return "🟠"
        }
    }
}

struct User: Codable {
    let id: Int32
    let login: String
}
