// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveShared

struct KahfTubeProfileView: View {
    @ObservedObject private var kahfTubeManager = KahfTubeManager.shared
    let genders = [KahftubeGender.male, KahftubeGender.female, KahftubeGender.child]
    let religionStatus = [KahftubeMode.practicingMuslim, KahftubeMode.liberalMuslim, KahftubeMode.moderateMuslim]
    @State private var genderSelection: Int = Preferences.KahfTube.gender.value
    @State private var religionSelection: Int = Preferences.KahfTube.mode.value
    @State private var profileImageUrl: String = Preferences.KahfTube.imageURL.value ?? ""
    @State private var isLoading: Bool = false
    @Binding var isOpened: Bool
    var reloadWebView: (() -> Void)?
    
    var body: some View {
        ZStack {
            VStack {
                if #available(iOS 15.0, *) {
                    AsyncImage(url: URL(string: profileImageUrl))
                        .clipShape(Circle())
                        .frame(width: 100.0, height: 100.0)
                        .padding(.vertical, 10)
                } else {
                    Circle()
                    .frame(width: 100.0, height: 100.0)
                    .overlay(RoundedRectangle(cornerRadius: 50.0)
                    .strokeBorder(Color.black, style: StrokeStyle(lineWidth: 0.5)))
                    .padding(.vertical, 10)
                }
                
                KahfTubeMenuButton(kafhTubeIsOn: $isOpened).padding(.bottom, 10)
                
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
                                Text(genders[index].localizedString).tag(genders[index].rawValue)
                            }
                        }
                        
                        Picker(selection: $religionSelection, label: Text("Religion Status")) {
                            ForEach(religionStatus.indices, id: \.self) { index in
                                Text(religionStatus[index].localizedString).tag(religionStatus[index].rawValue)
                            }
                        }
                    }
                    
                    Section() {
                        Button {
                            isLoading.toggle()
                            KahfTubeManager.shared.getHaramChannels()
                        } label: {
                            Text("Unsubscribe Haram Channels")
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle(Strings.KahfTube.kahfTubeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: genderSelection, perform: { newValue in
                Preferences.KahfTube.gender.value = newValue
                reloadWebView?()
            })
            .onChange(of: religionSelection, perform: { newValue in
                Preferences.KahfTube.mode.value = religionSelection
                reloadWebView?()
            })
            .overlay(KahfTubeManager.shared.channelsFetched ? Color.black.opacity(0.3) : .clear)
            .edgesIgnoringSafeArea(.bottom)
            
            if KahfTubeManager.shared.channelsFetched {
                KahfUnsubscribeView(haramChannels: kahfTubeManager.haramChannels, isLoading: $isLoading)
            }
    
            if isLoading {
                loadingView()
            }
        }.onAppear() {
            KahfTubeManager.shared.channelsFetched = false
            isLoading = false
        }
    }
}

// MARK: - KahfTubeProfileView Content
private extension KahfTubeProfileView {
    func loadingView() -> some View { return AnyView(ProgressView().progressViewStyle(CircularProgressViewStyle()))}
}

#if DEBUG
struct YoutubeFiltrationProfileView_Previews: PreviewProvider {
    static var previews: some View {
        KahfTubeProfileView(isOpened: .constant(true))
    }
}
#endif
