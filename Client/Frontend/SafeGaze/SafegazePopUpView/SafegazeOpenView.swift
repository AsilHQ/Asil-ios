// Copyright 2024 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct SafegazeOpenView: View {
    @Binding var value: Float
    @Binding var isOn: Bool
    @State var url: URL?
    @State var domainAvoidedContentCount: Int
    @State var lifetimeAvoidedContentCount: Int
    @State private var selection: Int = 0
    @State private var isShareSheetPresented: Bool = false
    let sharedText: String = "https://apps.apple.com/us/app/asil-browser/id1669467773"

    var body: some View {
        VStack {
            openHeaderView
            
            openHostView.padding(.top, 20)
            
            openContentStack.padding(.top, 10)
            
            genderModeView.padding(.top, 10)
            
            ImageBlurIntensityView(value: $value).padding(.top, 10)
            
            supportVStack.padding(.top, 20)
        }.onChange(of: selection) { newValue in
            if newValue == 1 {
                isOn.toggle()
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(activityItems: [sharedText])
        }
    }
    
    private var openHeaderView: some View {
        HStack {
            HStack {
                
                ResizableImageView(image: Image(braveSystemName: "sg.logo.on"), width: 44, height: 40).padding(.leading, 18)
                
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Text(Strings.safegazePopupSafegazeUpTitle)
                    .font(FontHelper.quicksand(size: 12, weight: .bold))
                    .frame(width: 74)
                    .padding(.leading, 14)
                    .padding(.trailing, 18)
                    .foregroundColor(.black)
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: Color(uiColor: UIColor(red: 0.06, green: 0.7, blue: 0.79, alpha: 1))))
                    .frame(width: 28, height: 16)
                    .scaleEffect(0.6)
                    .padding(.trailing, 14)
                    
                Spacer()
            }
            .frame(width: 148, height: 40)
            .background(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .inset(by: 0.5)
                    .stroke(Color(red: 0.91, green: 0.91, blue: 0.91), lineWidth: 1)
                
            ).padding(.trailing, 17)
            
            // TODO: Implement settings later
            /*ResizableImageView(image: Image(braveSystemName: "sg.settings.icon"), width: 20, height: 20)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.91, green: 0.91, blue: 0.91), lineWidth: 1)
                )
                .padding(.trailing, 17)*/
        }
        .frame(height: 80)
        .background(Color.white)
        .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
    }
    
    private var openHostView: some View {
        HStack {
            SafegazeHostView(url: url).padding(.leading, 18)
            
            Spacer()
            
            HStack {
                Menu {
                    Picker("", selection: $selection) {
                        Text(Strings.safegazePopupAlwaysPurifyTitle)
                            .tag(0)
                        Text(Strings.safegazePopupNeverPurifyTitle)
                            .tag(1)
                    }
                } label: {
                    Text(selection == 0 ? Strings.safegazePopupAlwaysPurifyTitle : Strings.safegazePopupNeverPurifyTitle)
                        .font(FontHelper.quicksand(size: 12, weight: .medium))
                        .foregroundColor(.black)
                    
                    ResizableImageView(image: Image(braveSystemName: "sg.arrow.down"), width: 10, height: 10)
                }.id(selection)
            }.frame(width: 110, height: 28)
                .background(.white)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.96, green: 0.96, blue: 0.96), lineWidth: 1)
                ).padding(.trailing, 10)
        }
        .frame(height: 48)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
        .padding(.horizontal, 18)
    }
    
    private var openContentStack: some View {
        VStack {
            
            HStack {
                Text(Strings.safegazePopupSinfulActsTitle)
                    .font(FontHelper.quicksand(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 14)
                
                Spacer()
                /*HStack {
                    
                    ResizableImageView(image: Image(braveSystemName: "sg.hide.icon"), width: 12, height: 12)
                    
                    Text("Hide")
                        .font(FontHelper.quicksand(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                }.padding(.trailing, 14)*/
            }
            
            HStack {
                
                HStack {
                    SafegazeCircleCountView(count: domainAvoidedContentCount)
                    
                    Spacer()
                    
                    Text(Strings.safegazePopupThisPageTitle)
                        .font(FontHelper.quicksand(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.43, green: 0.43, blue: 0.43))
                    
                }.frame(width: 108).padding(.leading, 14)
                
                HStack {
                    SafegazeCircleCountView(count: lifetimeAvoidedContentCount)
                    
                    Spacer()
                    
                    Text(Strings.safegazePopupLifeTimeTitle)
                        .font(FontHelper.quicksand(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.43, green: 0.43, blue: 0.43))
                    
                }.frame(width: 108).padding(.leading, 30)
                
                Spacer()
                
            }
        }
        .frame(height: 82)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
        .padding(.horizontal, 18)
    }
    
    private var genderModeView: some View {
        VStack {
            HStack {
                
                HStack {
                    Text(Strings.safegazePopupGenderModeTitle)
                        .font(FontHelper.quicksand(size: 13, weight: .bold))
                        .foregroundColor(.black)
                    
                    ResizableImageView(image: Image(braveSystemName: "sg.lock.icon"), width: 13, height: 13).padding(.leading, 2)
                    
                    Spacer()
                }
                
                Spacer()
                
                HStack(alignment: .center, spacing: 10) {
                    Text(Strings.safegazePopupComingSoonTitle)
                        .font(FontHelper.quicksand(size: 10, weight: .bold))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(red: 0.62, green: 0.48, blue: 0.92))
                }
                .padding(5)
                .background(Color(red: 0.62, green: 0.48, blue: 0.92).opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
                
            }.padding(.horizontal, 13)
            
            HStack {
                
                Spacer()
                
                HStack {
                    ResizableImageView(image: Image(braveSystemName: "sg.man"), width: 20, height: 20)
                        .foregroundColor(Color(red: 0.06, green: 0.7, blue: 0.79))
                    
                    Text(Strings.safegazePopupManTitle)
                        .font(FontHelper.quicksand(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.7, blue: 0.79))
                    
                }
                .frame(width: 142, height: 32)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .white, location: 0.00),
                            Gradient.Stop(color: .white.opacity(0.47), location: 0.49),
                            Gradient.Stop(color: .white.opacity(0), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.4, y: 0),
                        endPoint: UnitPoint(x: 0.4, y: 1)
                    )
                )
                .cornerRadius(20)
                
                HStack {
                    ResizableImageView(image: Image(braveSystemName: "sg.woman"), width: 20, height: 20)
                    
                    Text(Strings.safegazePopupWomanTitle)
                        .font(FontHelper.quicksand(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.23, green: 0.23, blue: 0.23))
                }
                .frame(width: 142, height: 32)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .white, location: 0.00),
                            Gradient.Stop(color: .white.opacity(0.47), location: 0.49),
                            Gradient.Stop(color: .white.opacity(0), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.4, y: 0),
                        endPoint: UnitPoint(x: 0.4, y: 1)
                    )
                )
                .cornerRadius(20)
                
                Spacer()
            }
            .frame(height: 45)
            .background(Color(red: 0.97, green: 0.96, blue: 0.96))
            .cornerRadius(61)
            .padding(.horizontal, 13)
            
        }.frame(height: 94)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
            .padding(.horizontal, 18)
    }
    
    private var supportVStack: some View {
        VStack(spacing: 20) {
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 375, height: 1)
                .background(Color(red: 0.91, green: 0.91, blue: 0.91))
            
            HStack {
                
                Button {
                    isShareSheetPresented.toggle()
                } label: {
                    ResizableImageView(image: Image(braveSystemName: "sg.share.icon"), width: 16, height: 16)
                        .frame(width: 44, height: 40)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
                }
                
                Spacer()
                
                Button {
                    guard let url = URL(string: "https://safegaze.com/support-safegaze/") else { return }
                    UIApplication.shared.open(url)
                } label: {
                    ZStack {
                        Text(Strings.safegazePopupSupportTitle)
                            .font(FontHelper.quicksand(size: 14, weight: .bold))
                            .foregroundColor(Color.white)
                    }
                    .frame(width: 232, height: 40)
                    .background(
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: Color(red: 0.01, green: 0.75, blue: 0.85), location: 0.00),
                                Gradient.Stop(color: Color(red: 0.01, green: 0.6, blue: 0.72), location: 1.00),
                                Gradient.Stop(color: Color(red: 0.01, green: 0.6, blue: 0.72), location: 1.00),
                            ],
                            startPoint: UnitPoint(x: 0.5, y: 0),
                            endPoint: UnitPoint(x: 0.5, y: 1)
                        )
                    )
                    .cornerRadius(10)
                }
                
                Spacer()
                
               Button {
                    
                } label: {
                    ResizableImageView(image: Image(braveSystemName: "sg.night.icon"), width: 16, height: 16)
                        .frame(width: 44, height: 40)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
                }.disabled(true)
            }
        }.padding(.horizontal, 18)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#if DEBUG
struct SafegazeOpenView_Previews: PreviewProvider {
    static var previews: some View {
        SafegazeOpenView(value: .constant(0.3), isOn: .constant(true), domainAvoidedContentCount: 1000, lifetimeAvoidedContentCount: 1000)
    }
}
#endif
