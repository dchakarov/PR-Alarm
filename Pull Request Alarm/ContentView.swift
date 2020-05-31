//
//  ContentView.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 29/05/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var helper = RepositoryHelper()
    @State var token: String = ""
    @State var mineOnly: Bool = false
    @State var enterpriseGitHub: Bool = false
    @State var enterpriseGitHubUrl: String = ""
    @State var enterpriseGitHubOrg: String = ""

    var body: some View {
        VStack {
            Section {
                HStack {
                    SecureField("GitHub Token", text: $token)
                    Spacer()
                }.padding([.horizontal, .top])
                HStack {
                    Toggle(isOn: $enterpriseGitHub) {
                        Text("Use Enterprise GitHub?")
                    }
                    if enterpriseGitHub {
                        TextField("GitHub URL, e.g. github.company.com", text: $enterpriseGitHubUrl)
                        TextField("GitHub Org, e.g. my-team", text: $enterpriseGitHubOrg)
                    }
                    Spacer()
                }.padding([.horizontal])
                Button("Update") {
                    self.helper.settingsUpdated(token: self.token, enterpriseEnabled: self.enterpriseGitHub, baseUrl: self.enterpriseGitHubUrl, org: self.enterpriseGitHubOrg)
                }.disabled(token.isEmpty)
                if !token.isEmpty {
                    Divider()
                    HStack {
                        Toggle(isOn: $mineOnly) {
                            Text("Show only my PRs")
                        }
                        Spacer()
                    }.padding([.horizontal])
                }
            }
            Section {
                List {
                    ForEach(helper.reposWithPRs) { repo in
                        Section(header: Text("\(repo.name)")) {
                            ForEach(self.helper.pulls[repo.full_name]!, id: \.id) { pull in
                                Group {
                                    if pull.isMine || !self.mineOnly {
                                        HStack {
                                            Text("\(pull.mergeableDisplayValue)")
                                            Text("\(pull.title)")
                                        }.padding([.horizontal])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            self.helper.poll()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
