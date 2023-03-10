/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public struct BraveUX {
  public static let braveCommunityURL = URL(string: "https://community.asil.co")!
  public static let braveVPNFaqURL = URL(string: "https://asil.co/privacy/")!
  public static let braveVPNLinkReceiptProd =
    URL(string: "https://asil.co/privacy/")!
  public static let braveVPNLinkReceiptStaging =
    URL(string: "https://asil.co/privacy/")!
  public static let braveVPNLinkReceiptDev =
    URL(string: "https://asil.co/privacy/")!
    public static let bravePrivacyURL = URL(string: "https://asil.co/privacy/")!
  public static let braveNewsPrivacyURL = URL(string: "https://asil.co/privacy/")!
  public static let braveOffersURL = URL(string: "https://asil.co/privacy/")!
  public static let bravePlaylistOnboardingURL = URL(string: "https://asil.co/privacy/")!
  public static let braveRewardsLearnMoreURL = URL(string: "https://asil.co/privacy/")!
  public static let braveRewardsUnverifiedPublisherLearnMoreURL = URL(string: "https://asil.co/privacy/")!
  public static let braveNewsPartnersURL = URL(string: "https://asil.co/privacy/")!
    public static let braveTermsOfUseURL = URL(string: "https://asil.co/terms-of-use/")!
  public static let batTermsOfUseURL = URL(string: "https://asil.co/privacy/")!
  public static let ntpTutorialPageURL = URL(string: "https://asil.co/privacy/")
  public static let privacyReportsURL = URL(string: "https://asil.co/privacy/")!
  public static let braveWalletNetworkLearnMoreURL = URL(string: "https://asil.co/privacy/")!
  public static let braveP3ALearnMoreURL = URL(string: "https://asil.co/privacy/")!

  public static let faviconBorderColor = UIColor(white: 0, alpha: 0.2)
  public static let faviconBorderWidth = 1.0 / UIScreen.main.scale
  public static let baseDimensionValue = 450.0
  
  /// The apps URL scheme for the current build channel
  public static var appURLScheme: String {
    Bundle.main.infoDictionary?["BRAVE_URL_SCHEME"] as? String ?? "brave"
  }
}
