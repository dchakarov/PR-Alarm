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
    @State var isEditing: Bool = true
    @State var mineOnly: Bool = false
    
    var body: some View {
        VStack {
            Section {
                HStack {
                    SecureField("GitHub Token", text: $token).disabled(!isEditing)
                    if helper.githubToken.isEmpty || isEditing {
                        Button("Save") {
                            self.helper.save(self.token)
                            self.isEditing = false
                        }.disabled(!isEditing)
                    } else {
                        Button("Edit") {
                            self.isEditing = true
                        }
                    }
                }
                HStack {
                    Toggle(isOn: $mineOnly) {
                        Text("Show only my PRs")
                    }
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
