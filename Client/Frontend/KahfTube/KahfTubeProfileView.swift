// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveShared

struct KahfTubeProfileView: View {
    let genders = ["Male", "Female", "Child"]
    let religionStatus = ["Practicing Muslim", "Liberal Muslim", "Moderate Muslim"]
    @State private var genderSelection: Int = Preferences.KahfTube.gender.value ?? 0
    @State private var religionSelection: Int = Preferences.KahfTube.mode.value ?? 0
    @State private var profileImageUrl: String = Preferences.KahfTube.imageURL.value ?? ""
    var dismissAction: (() -> Void)?
    
    var body: some View {
        VStack {
            if #available(iOS 15.0, *) {
                AsyncImage(url: URL(string: profileImageUrl))
                    .clipShape(Circle())
                    .padding(.vertical, 30)
            } else {
                Circle()
                .frame(width: 100.0, height: 100.0)
                .overlay(RoundedRectangle(cornerRadius: 50.0)
                .strokeBorder(Color.black, style: StrokeStyle(lineWidth: 0.5)))
                .padding(.vertical, 30)
            }
            
            Form {
                Section(header: Text("Name")) {
                    Text(Preferences.KahfTube.username.value ?? "")
                }
                
                Section(header: Text("Connected Account")) {
                    HStack {
                        Text(Preferences.KahfTube.email.value ?? "")
                        
                        Spacer()
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
                
                Section() {
                    Button {
                        
                    } label: {
                        Text("Unsubscribe Haram Channels")
                    }
                }
            }
        }
        .navigationTitle(Strings.KahfTube.kahfTubeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                Preferences.KahfTube.gender.value = genderSelection
                Preferences.KahfTube.mode.value = religionSelection
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
        KahfTubeProfileView()
    }
}
#endif
