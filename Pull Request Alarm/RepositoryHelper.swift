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
    @Published private var settings: Settings = Settings()
    var org: String? {
        settings.org
    }
    var customUrl: String? {
        settings.customUrl
    }
    private var cancellableBag = Set<AnyCancellable>()
    var gitHubClient = GitHubClient(token: "")
    
    var userLogin: String = ""
    var githubToken: String = ""
    
    let publicUrl = "api.github.com"
    
    var baseUrl: String {
        if let url = self.customUrl {
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
                        self.pulls(for: repo)
                    }
                }
        }
        .store(in: &cancellableBag)
    }
    
    func pulls(for repo: Repository) {
        let repoName = repo.full_name
        gitHubClient.pulls(for: repoName)
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let pulls):
                    if !pulls.isEmpty {
                        self.reposWithPRs.append(repo)
                        self.pulls[repoName] = []
                        for pullId in pulls {
                            self.pull(repo: repoName, number: pullId.number)
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
    
    func merge(repo: String, number: Int) {
        gitHubClient.merge(repo: repo, number: number)
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let res):
                    print(res)
                }
        }
        .store(in: &cancellableBag)
    }
    
    func settingsUpdated(token: String, enterpriseEnabled: Bool, url: String?, org: String?) {
        githubToken = token
        if let org = org {
            settings.org = org
        }
        if enterpriseEnabled {
            settings.customUrl = url
        } else {
            settings.customUrl = nil
        }
        gitHubClient = GitHubClient(token: githubToken, baseUrl: baseUrl)
    }
}
