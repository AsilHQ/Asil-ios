// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct YoutubeFiltrationProfileView: View {
    let genders = ["Male", "Female", "Non-Binary"]
    let religionStatus = ["Practicing Muslim", "B", "C"]
    @State private var name = "Max Watson"
    @State private var genderSelection = 0
    @State private var religionSelection = 0
    @State private var preferredLanguage = ""
    @State private var profilePicture: UIImage?
    
    var body: some View {
        VStack {
            Circle()
            .frame(width: 100.0, height: 100.0)
            .overlay(RoundedRectangle(cornerRadius: 50.0)
            .strokeBorder(Color.black, style: StrokeStyle(lineWidth: 0.5)))
            .padding(.vertical, 30)
            
            Form {
                Section(header: Text("Name")) {
                    TextEditor(text: $name)
                }
                
                Section(header: Text("Connected Account")) {
                    HStack {
                        Text("cem@gmail.com")
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Text("Change")
                        }
                    }
                }
                
                Section(header: Text("Preference")) {
                    Picker(selection: $genderSelection, label: Text("Gender")) {
                        ForEach(genders.indices, id: \.self) { index in
                            Text(genders[index]).tag(index)
                        }
                    }
                    
                    Picker(selection: $genderSelection, label: Text("Religion Status")) {
                        ForEach(religionStatus.indices, id: \.self) { index in
                            Text(religionStatus[index]).tag(index)
                        }
                    }
                }
            }
        }
        .navigationTitle(Strings.YoutubeFiltration.youtubeFiltrationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct YoutubeFiltrationProfileView_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeFiltrationProfileView()
    }
}
#endif
