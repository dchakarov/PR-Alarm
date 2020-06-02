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
    @Published var enterpriseUrl: String?
    var org: String?
    private var cancellableBag = Set<AnyCancellable>()
    
    var userLogin: String = ""
    var githubToken: String = ""
    
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
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { receive in
            }, receiveValue: { user in
                self.userLogin = user.login
                self.repos()
            })
            .store(in: &cancellableBag)
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
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: [Repository].self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { receive in
            }, receiveValue: { repos in
                self.repositories = repos
                self.reposWithPRs = []
                for repo in repos {
                    self.pulls(for: repo.full_name)
                }
            })
            .store(in: &cancellableBag)
    }
    
    func pulls(for repo: String) {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://\(baseUrl)/repos/\(repo)/pulls")!)
        urlRequest.addValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: [PullRequestId].self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { receive in
            }, receiveValue: { pulls in
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
            .store(in: &cancellableBag)
    }
    
    func pull(repo: String, number: Int) {
        guard !githubToken.isEmpty else { return }
        var urlRequest = URLRequest(url: URL(string: "https://\(baseUrl)/repos/\(repo)/pulls/\(number)")!)
        urlRequest.addValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: PullRequest.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { receive in
            }, receiveValue: { pull in
                self.pulls[repo]?.append(pull)
            })
            .store(in: &cancellableBag)
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
