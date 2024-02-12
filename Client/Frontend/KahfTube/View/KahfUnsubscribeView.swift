// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct KahfUnsubscribeView: View {
    @State var haramChannels: [Channel]
    
    @Binding var isLoading: Bool
    var body: some View {
        content
    }
    
    @ViewBuilder private var content: some View {
        ZStack {
            if haramChannels.isEmpty {
                haramChannelsNotFoundView
            } else {
                haramChannelsView
            }
        }
    }
}

// MARK: - Loading Content
private extension KahfUnsubscribeView {
    var haramChannelsView: some View {
        ZStack {
            Color(.braveBackground)
            
            VStack {
                HStack {
                    Text("\(haramChannels.count) Haram Channels found")
                    
                    Spacer()
                    
                    Button {
                        KahfTubeManager.shared.finishUnsubscribeSession()
                    } label: {
                        Text("Close").foregroundColor(Color(UIColor(colorString: "#7B7B7B")))
                    }
                }.padding(.top, 26)
                
                ScrollView {
                    ForEach(haramChannels, id: \.self) { channel in
                        HStack {
                            Group {
                                if #available(iOS 15.0, *) {
                                    AsyncImage(url: URL(string: channel.thumbnail)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50.0, height: 50.0)
                                            .clipShape(Circle())
                                            .padding(.vertical, 10)
                                    } placeholder: {
                                        Circle()
                                            .foregroundColor(Color(UIColor(colorString: "#A242FF")))
                                            .frame(width: 50.0, height: 50.0)
                                            .padding(.vertical, 10)
                                    }
                                } else {
                                    Circle()
                                        .foregroundColor(Color(UIColor(colorString: "#A242FF")))
                                        .frame(width: 50.0, height: 50.0)
                                        .padding(.vertical, 10)
                                }
                            }.padding(.trailing, 18)
                            
                            Text(channel.name)
                            
                            Spacer()
                        }
                    }
                }.frame(height: 400.0)
                
                HStack {
                    
                    Button {
                        KahfTubeManager.shared.channelsFetched.toggle()
                        isLoading.toggle()
                        KahfTubeManager.shared.getHaramChannels()
                    } label: {
                        Spacer()
                        Text("Refresh again").foregroundColor(Color(UIColor(colorString: "#7B7B7B")))
                        Spacer()
                    }.frame(height: 50.0).background(Color.white).cornerRadius(10.0)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(UIColor(colorString: "#7B7B7B")), lineWidth: 1)).padding(.trailing, 10)
                    
                    Button {
                        isLoading = true
                        KahfTubeManager.shared.unsubscribe()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            isLoading = false
                            KahfTubeManager.shared.channelsFetched.toggle()
                        }
                    } label: {
                        Spacer()
                        Text("Unsubscribe Now").foregroundColor(Color.white)
                        Spacer()
                    }.frame(height: 50.0).background(Color(UIColor(colorString: "#A242FF"))).cornerRadius(10.0)
                }
                
                Spacer()
                
            }.padding(.horizontal, 16)
        }.cornerRadius(5.0).padding(.horizontal, 20).cornerRadius(5.0).frame(maxHeight: 470).onAppear {
            isLoading = false
        }
    }
    
    var haramChannelsNotFoundView: some View {
        ZStack {
            Color(.braveBackground)
            VStack {
                Image("kahf-tubemoon-clear-fill", bundle: Bundle.module).foregroundColor(Color(UIColor(colorString: "#A242FF")))
                    .frame(width: 140.0, height: 140.0)
                    .padding(.top, 62)
                    .padding(.bottom, 20)
                
                Text("No Haram Subscribed")
                Text("Channel Found").padding(.bottom, 42)
                
                Button {
                    KahfTubeManager.shared.finishUnsubscribeSession()
                } label: {
                    Text("Alright").foregroundColor(Color.white)
                }.frame(width: 175, height: 50.0).background(Color(UIColor(colorString: "#A242FF"))).cornerRadius(10.0).padding(.bottom, 42)
            }.padding(.horizontal, 16)
        }.frame(maxHeight: 372.0).cornerRadius(5.0).padding(.horizontal, 20).cornerRadius(5.0).onAppear {
            isLoading = false
        }
    }
}

#if DEBUG
struct KahfUnsubscribeView_Previews: PreviewProvider {
    static var previews: some View {
        KahfUnsubscribeView(haramChannels: [Channel](), isLoading: .constant(false))
    }
}
#endif
