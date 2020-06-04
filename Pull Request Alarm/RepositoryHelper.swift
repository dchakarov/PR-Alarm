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
    var gitHubClient = GitHubClient(token: "")
    
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
        gitHubClient.user()
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let user):
                    self.userLogin = user.login
                    self.repos()
                }
        }
        .store(in: &cancellableBag)
    }
    
    func repos() {
        gitHubClient.repos(org: org)
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let repos):
                    self.repositories = repos
                    self.reposWithPRs = []
                    for repo in repos {
                        self.pulls(for: repo.full_name)
                    }
                }
        }
        .store(in: &cancellableBag)
    }
    
    func pulls(for repo: String) {
        gitHubClient.pulls(for: repo)
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let pulls):
                    if !pulls.isEmpty {
                        self.reposWithPRs.append(self.repositories.first(where: { r -> Bool in
                            r.full_name == repo
                        })!)
                        self.pulls[repo] = []
                        for pullId in pulls {
                            self.pull(repo: repo, number: pullId.number)
                        }
                    }
                }
        }
        .store(in: &cancellableBag)
    }
    
    func pull(repo: String, number: Int) {
        gitHubClient.pull(repo: repo, number: number)
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let pull):
                    self.pulls[repo]?.append(pull)
                }
        }
        .store(in: &cancellableBag)
    }
    
    func settingsUpdated(token: String, enterpriseEnabled: Bool, url: String?, org: String?) {
        githubToken = token
        self.org = org
        if enterpriseEnabled {
            enterpriseUrl = url
        } else {
            enterpriseUrl = nil
        }
        gitHubClient = GitHubClient(token: githubToken, baseUrl: baseUrl)
        self.poll()
    }
}
