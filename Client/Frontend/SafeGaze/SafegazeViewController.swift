// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Storage
import SnapKit
import Shared
import BraveShared
import Data
import BraveUI
import UIKit
import Growth
import BraveCore

/// Displays shield settings and shield stats for a given URL
class SafegazeViewController: UIViewController, PopoverContentComponent {

  let tab: Tab
  lazy var url: URL? = {
    guard let _url = tab.url else { return nil }

    if InternalURL.isValid(url: _url),
      let internalURL = InternalURL(_url),
      internalURL.isErrorPage {
      return internalURL.originalURLFromErrorPage
    }

    return _url
  }()

  var safegazeSettingsChanged: ((SafegazeViewController, BraveShield) -> Void)?
  var showGlobalShieldsSettings: ((SafegazeViewController) -> Void)?

  private var statsUpdateObservable: AnyObject?

  /// Create with an initial URL and block stats (or nil if you are not on any web page)
  init(tab: Tab) {
    self.tab = tab

    super.init(nibName: nil, bundle: nil)

    tab.contentBlocker.statsDidChange = { [weak self] _ in
      self?.updateShieldBlockStats()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  private var shieldsUpSwitch: ShieldsSwitch {
    return shieldsView.simpleShieldView.shieldsSwitch
  }

  // MARK: - State

  private func updateShieldBlockStats() {
     shieldsView.simpleShieldView.blockCountView.countLabel.attributedText = {
          let string = NSMutableAttributedString(
            string: String(tab.contentBlocker.stats.safegazeCount.noneFormattedString ?? "")
          )
          return string
    }()
    shieldsView.simpleShieldView.totalCountView.descriptionLabel.attributedText = {
        let string = NSMutableAttributedString(
            string: String(format: Strings.Shields.safegazeTotalCountLabel, BraveGlobalShieldStats.shared.safegazeCount.noneFormattedString ?? ""),
            attributes: [.font: UIFont.systemFont(ofSize: 13.0), .foregroundColor: UIColor.braveLabel ]
        )
        return string
    }()
  }

  private func updateContentView(to view: UIView, animated: Bool) {
    if animated {
      UIView.animate(
        withDuration: shieldsView.contentView == nil ? 0 : 0.1,
        animations: {
          self.shieldsView.contentView?.alpha = 0.0
        },
        completion: { _ in
          self.shieldsView.contentView = view
          view.alpha = 0
          self.updatePreferredContentSize()
          UIView.animate(withDuration: 0.1) {
            view.alpha = 1.0
          }
        })
    } else {
      shieldsView.contentView = view
    }
  }

  private func updatePreferredContentSize() {
    guard let visibleView = shieldsView.contentView else { return }
    let width = min(360, UIScreen.main.bounds.width - 20)
    // Ensure the a static width is given to the main view so we can calculate the height
    // correctly when we force a layout
    let height = visibleView.systemLayoutSizeFitting(
        CGSize(width: width, height: 0),
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
    ).height
    
    preferredContentSize = CGSize(
        width: width,
        height: height
    )
  }

  // MARK: -

  /// Groups the shield types with their control and global preference
  private lazy var shieldControlMapping: [(BraveShield, AdvancedShieldsView.ToggleView, Preferences.Option<Bool>?)] = [
    (.AdblockAndTp, shieldsView.advancedShieldView.adsTrackersControl, Preferences.Shields.blockAdsAndTracking),
    (.SafeBrowsing, shieldsView.advancedShieldView.blockMalwareControl, Preferences.Shields.blockPhishingAndMalware),
    (.NoScript, shieldsView.advancedShieldView.blockScriptsControl, Preferences.Shields.blockScripts),
    (.FpProtection, shieldsView.advancedShieldView.fingerprintingControl, Preferences.Shields.fingerprintingProtection),
  ]

  var shieldsView: View {
    return view as! View  // swiftlint:disable:this force_cast
  }

  override func loadView() {
      let newView = View(frame: .zero, url: url, tab: tab)
      newView.updateBgView = {  updatedView, animated in
          self.updateContentView(to: updatedView, animated: animated)
      }
      newView.updateBlurIntensity = {
          let jsString =
            """
                window.blurIntensity = \(Preferences.Safegaze.blurIntensity.value);
                updateBluredImageOpacity();
            """
          self.tab.webView?.evaluateSafeJavaScript(functionName: jsString, contentWorld: .page, asFunction: false) { object, error in
              if let error = error {
                  print("SafegazeContentScriptHandler coreML script\(error)")
              } else {
                  print("blurChanged")
              }
          }
      }
      newView.shieldsSettingsChanged = {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.safegazeSettingsChanged?(self, .AllOff)
          }
      }
      view = newView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if let url = url {
      shieldsView.simpleShieldView.faviconImageView.loadFavicon(for: url)
    } else {
      shieldsView.simpleShieldView.faviconImageView.isHidden = true
    }
    
    // Follows the logic in `updateTextWithURL` for formatting
    let normalizedDisplayHost = URLFormatter.formatURL(url?.withoutWWW.absoluteString ?? "", formatTypes: .omitDefaults, unescapeOptions: []).removeSchemeFromURLString(url?.scheme)
    
    shieldsView.simpleShieldView.hostLabel.text = normalizedDisplayHost
    shieldsView.reportBrokenSiteView.urlLabel.text = url?.domainURL.absoluteString
    shieldsView.simpleShieldView.shieldsSwitch.addTarget(self, action: #selector(shieldsOverrideSwitchValueChanged), for: .valueChanged)
    shieldsView.advancedShieldView.siteTitle.titleLabel.text = normalizedDisplayHost.uppercased()
    shieldsView.advancedShieldView.globalControlsButton.addTarget(self, action: #selector(tappedGlobalShieldsButton), for: .touchUpInside)

    shieldsView.advancedControlsBar.addTarget(self, action: #selector(tappedAdvancedControlsBar), for: .touchUpInside)

    shieldsView.simpleShieldView.reportSiteButton.addTarget(self, action: #selector(tappedReportSiteButton), for: .touchUpInside)
    shieldsView.reportBrokenSiteView.cancelButton.addTarget(self, action: #selector(tappedCancelReportingButton), for: .touchUpInside)
    shieldsView.reportBrokenSiteView.submitButton.addTarget(self, action: #selector(tappedSubmitReportingButton), for: .touchUpInside)

    updateShieldBlockStats()

    navigationController?.setNavigationBarHidden(true, animated: false)

    updatePreferredContentSize()
    
    if advancedControlsShowing && shieldsUpSwitch.isOn {
      shieldsView.advancedShieldView.isHidden = false
      shieldsView.advancedControlsBar.isShowingAdvancedControls = true
      updatePreferredContentSize()
    }

    shieldControlMapping.forEach { shield, toggle, option in
      toggle.valueToggled = { [weak self] on in
        guard let self = self else { return }
        // Localized / per domain toggles triggered here
        self.updateSafegazeState(on: on, option: option)
        // Wait a fraction of a second to allow DB write to complete otherwise it will not use the
        // updated shield settings when reloading the page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          self.safegazeSettingsChanged?(self, shield)
        }
      }
    }
  }
    
   private func updateSafegazeState(on: Bool, option: Preferences.Option<Bool>?) {
      guard let url = url else { return }
      // `.AllOff` uses inverse logic. Technically we set "all off" when the switch is OFF, unlike all the others
      // If the new state is the same as the global preference, reset it to nil so future shield state queries
      // respect the global preference rather than the overridden value. (Prevents toggling domain state from
      // affecting future changes to the global pref)
      Domain.setSafegaze(
        forUrl: url, isOn: on,
        isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
  }

  @objc private func shieldsOverrideSwitchValueChanged() {
    let isOn = shieldsUpSwitch.isOn
    self.updateSafegazeState(on: isOn, option: nil)
    // Wait a fraction of a second to allow DB write to complete otherwise it will not use the updated
    // shield settings when reloading the page
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      self.safegazeSettingsChanged?(self, .AllOff)
    }
  }

  private var advancedControlsShowing: Bool {
    Preferences.Shields.advancedControlsVisible.value
  }

  @objc private func tappedAdvancedControlsBar() {
    Preferences.Shields.advancedControlsVisible.value.toggle()
    UIView.animate(withDuration: 0.25) {
      self.shieldsView.advancedShieldView.isHidden.toggle()
    }
    updatePreferredContentSize()
  }

  @objc private func tappedAboutShieldsButton() {
    /*let aboutShields = AboutSafegazeViewController()
    aboutShields.preferredContentSize = preferredContentSize
    navigationController?.pushViewController(aboutShields, animated: true)*/
  }

  @objc private func tappedShareShieldsButton() {
    let globalShieldsActivityController =
      ShieldsActivityItemSourceProvider.shared.setupGlobalShieldsActivityController()
    globalShieldsActivityController.popoverPresentationController?.sourceView = view

    present(globalShieldsActivityController, animated: true, completion: nil)
  }

  @objc private func tappedReportSiteButton() {
    updateContentView(to: shieldsView.reportBrokenSiteView, animated: true)
  }

  @objc private func tappedCancelReportingButton() {
    updateContentView(to: shieldsView.stackView, animated: true)
  }

  @objc private func tappedSubmitReportingButton() {
    if let url = url {
      Task { @MainActor in
        await WebcompatReporter.reportIssue(on: url)
        try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
        guard !self.isBeingDismissed else { return }
        self.dismiss(animated: true)
      }
    }
    updateContentView(to: shieldsView.siteReportedView, animated: true)
  }

  @objc private func tappedGlobalShieldsButton() {
    showGlobalShieldsSettings?(self)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

extension SafegazeViewController {
  class View: UIView {

    private let scrollView = UIScrollView().then {
      $0.delaysContentTouches = false
    }

    var contentView: UIView? {
      didSet {
        oldValue?.removeFromSuperview()
        if let view = contentView {
          scrollView.addSubview(view)
          view.snp.makeConstraints {
            $0.edges.equalToSuperview()
          }
        }
      }
    }

    let stackView = UIStackView().then {
      $0.axis = .vertical
      $0.isLayoutMarginsRelativeArrangement = true
      $0.translatesAutoresizingMaskIntoConstraints = false
    }

    let simpleShieldView = SimpleSafegazeView()
    let advancedControlsBar = AdvancedControlsBarView()
    let advancedShieldView = AdvancedShieldsView().then {
      $0.isHidden = true
    }

    let reportBrokenSiteView = ReportBrokenSiteView()
    let siteReportedView = SiteReportedView()
    public var updateBgView: ((UIView, Bool) -> Void)?
    public var updateBlurIntensity: (() -> Void)?
    public var shieldsSettingsChanged: (() -> Void)?
    var url: URL?
    var tab: Tab
      
    init(frame: CGRect, url: URL?, tab: Tab) {
      self.url = url
      self.tab = tab
      super.init(frame: frame)

      backgroundColor = .braveBackground

      let popupView = SafegazePopUpView.redirect(url: url, updateView: { [self] in
          setNeedsUpdateConstraints()
          layoutIfNeeded()
          updateBgView?(stackView, true)
      }, updateBlurIntensity: {
          self.updateBlurIntensity?()
      }, shieldsSettingsChanged: {
          self.shieldsSettingsChanged?()
      }, tab: tab)
      stackView.addArrangedSubview(popupView)

      addSubview(scrollView)
      scrollView.addSubview(stackView)

      scrollView.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }

      scrollView.contentLayoutGuide.snp.makeConstraints {
        $0.left.right.equalTo(self)
      }

      stackView.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }

      contentView = stackView
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError()
    }
  }
}

extension SafegazeViewController {

  var closeActionAccessibilityLabel: String {
    return Strings.Popover.closeShieldsMenu
  }
}

