// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveShared

struct YoutubeFiltrationProfileView: View {
    let genders = ["Male", "Female", "Non-Binary"]
    let religionStatus = ["Practicing Muslim", "B", "C"]
    @State private var genderSelection: Int = Preferences.YoutubeFiltration.gender.value ?? 0
    @State private var religionSelection: Int = Preferences.YoutubeFiltration.religionStatus.value ?? 0
    @State private var profilePicture: UIImage?
    var dismissAction: (() -> Void)?
    
    var body: some View {
        VStack {
            Circle()
            .frame(width: 100.0, height: 100.0)
            .overlay(RoundedRectangle(cornerRadius: 50.0)
            .strokeBorder(Color.black, style: StrokeStyle(lineWidth: 0.5)))
            .padding(.vertical, 30)
            
            Form {
                Section(header: Text("Name")) {
                    Text(Preferences.YoutubeFiltration.username.value ?? "")
                }
                
                Section(header: Text("Connected Account")) {
                    HStack {
                        Text(Preferences.YoutubeFiltration.email.value ?? "")
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Text("Change")
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
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
        .toolbar {
            Button {
                Preferences.YoutubeFiltration.gender.value = genderSelection
                Preferences.YoutubeFiltration.religionStatus.value = religionSelection
                dismissAction?()
            } label: {
                Text("Save")
            }
        }
    }
}

#if DEBUG
struct YoutubeFiltrationProfileView_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeFiltrationProfileView()
    }
}
#endif
