// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveUI
import CoreData
import Data
import Shared
import BraveShared
import BraveCore
import SnapKit
import SwiftUI
import Combine
import DesignSystem
import Growth

/// The behavior for sizing sections when the user is in landscape orientation
enum NTPLandscapeSizingBehavior {
  /// The section is given half the available space
  ///
  /// Layout is decided by device type (iPad vs iPhone)
  case halfWidth
  /// The section is given the full available space
  ///
  /// Layout is up to the section to define
  case fullWidth
}

/// A section that will be shown in the NTP. Sections are responsible for the
/// layout and interaction of their own items
protocol NTPSectionProvider: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
  /// Register cells and supplimentary views for your section to
  /// `collectionView`
  func registerCells(to collectionView: UICollectionView)
  /// The defined behavior when the user is in landscape.
  ///
  /// Defaults to `halfWidth`, which will only give half of the available
  /// width to the section (and adjust layout automatically based on device)
  var landscapeBehavior: NTPLandscapeSizingBehavior { get }
}

extension NTPSectionProvider {
  var landscapeBehavior: NTPLandscapeSizingBehavior { .halfWidth }
  /// The bounding size for auto-sizing cells, bound to the maximum available
  /// width in the collection view, taking into account safe area insets and
  /// insets for that given section
  func fittingSizeForCollectionView(_ collectionView: UICollectionView, section: Int) -> CGSize {
    let sectionInset: UIEdgeInsets
    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
      if let flowLayoutDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
        sectionInset = flowLayoutDelegate.collectionView?(collectionView, layout: collectionView.collectionViewLayout, insetForSectionAt: section) ?? flowLayout.sectionInset
      } else {
        sectionInset = flowLayout.sectionInset
      }
    } else {
      sectionInset = .zero
    }
    return CGSize(
      width: collectionView.bounds.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right - sectionInset.left - sectionInset.right,
      height: 1000
    )
  }
}

/// A section provider that can be observed for changes to tell the
/// `NewTabPageViewController` to reload its section
protocol NTPObservableSectionProvider: NTPSectionProvider {
  var sectionDidChange: (() -> Void)? { get set }
}

protocol NewTabPageDelegate: AnyObject {
  func focusURLBar()
  func navigateToInput(_ input: String, inNewTab: Bool, switchingToPrivateMode: Bool)
  func handleFavoriteAction(favorite: Favorite, action: BookmarksAction)
  func tappedQRCodeButton(url: URL)
}

/// The new tab page. Shows users a variety of information, including stats and
/// favourites
class NewTabPageViewController: UIViewController {
  weak var delegate: NewTabPageDelegate?

  var ntpStatsOnboardingFrame: CGRect? {
    guard let section = sections.firstIndex(where: { $0 is StatsSectionProvider }) else {
      return nil
    }

    if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: section)) as? NewTabCenteredCollectionViewCell<BraveShieldStatsView> {
      return cell.contentView.convert(cell.contentView.frame, to: view)
    }
    return nil
  }

  /// The modules to show on the new tab page
  private var sections: [NTPSectionProvider] = []

  private let layout = NewTabPageFlowLayout()
  private let collectionView: NewTabCollectionView
  private weak var tab: Tab?

  private var background: NewTabPageBackground
  private let backgroundView = NewTabPageBackgroundView()
  private let backgroundButtonsView = NewTabPageBackgroundButtonsView()
  /// A gradient to display over background images to ensure visibility of
  /// the NTP contents and sponsored logo
  ///
  /// Only should be displayed when the user has background images enabled
  let gradientView = GradientView(
    colors: [
      UIColor(white: 0.0, alpha: 0.5),
      UIColor(white: 0.0, alpha: 0.0),
      UIColor(white: 0.0, alpha: 0.3),
    ],
    positions: [0, 0.5, 0.8],
    startPoint: .zero,
    endPoint: CGPoint(x: 0, y: 1)
  )

  private var preventReloadOnBraveNewsEnabledChange = false

  private var cancellables: Set<AnyCancellable> = []

  init(
    tab: Tab,
    profile: Profile,
    dataSource: NTPDataSource
  ) {
    self.tab = tab
    background = NewTabPageBackground(dataSource: dataSource)
    collectionView = NewTabCollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)

    Preferences.NewTabPage.showNewTabPrivacyHub.observe(from: self)
    Preferences.NewTabPage.showNewTabFavourites.observe(from: self)
    
    sections = [
      StatsSectionProvider(openPrivacyHubPressed: { [weak self] in
        if PrivateBrowsingManager.shared.isPrivateBrowsing {
          return
        }
        
        let host = UIHostingController(rootView: PrivacyReportsManager.prepareView())
        host.rootView.onDismiss = { [weak self, weak host] in
          host?.dismiss(animated: true) {
            guard let self = self else { return }
            
            // Handle App Rating
            // User finished viewing the privacy report (tapped close)
            AppReviewManager.shared.handleAppReview(for: self)
          }
        }
        
        host.rootView.openPrivacyReportsUrl = { [weak self] in
          self?.delegate?.navigateToInput(
            BraveUX.privacyReportsURL.absoluteString,
            inNewTab: false,
            // Privacy Reports view is unavailable in private mode.
            switchingToPrivateMode: false
          )
        }
        
        self?.present(host, animated: true)
      }, hidePrivacyHubPressed: { [weak self] in
        Preferences.NewTabPage.showNewTabPrivacyHub.value = false
        self?.collectionView.reloadData()
      }),
      FavoritesSectionProvider(action: { [weak self] bookmark, action in
        self?.handleFavoriteAction(favorite: bookmark, action: action)
      }, legacyLongPressAction: { [weak self] alertController in
        self?.present(alertController, animated: true)
      }),
      FavoritesOverflowSectionProvider(action: { [weak self] in
        self?.delegate?.focusURLBar()
      }),
    ]

    collectionView.do {
      $0.delegate = self
      $0.dataSource = self
      $0.dragDelegate = self
      $0.dropDelegate = self
    }

    background.changed = { [weak self] in
      self?.setupBackgroundImage()
    }
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(backgroundView)
    view.insertSubview(gradientView, aboveSubview: backgroundView)
    view.addSubview(collectionView)

    collectionView.backgroundView = backgroundButtonsView

    backgroundButtonsView.tappedActiveButton = { [weak self] sender in
      self?.tappedActiveBackgroundButton(sender)
    }

    setupBackgroundImage()
    backgroundView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    gradientView.snp.makeConstraints {
      $0.edges.equalTo(backgroundView)
    }

    sections.enumerated().forEach { (index, provider) in
      provider.registerCells(to: collectionView)
      if let observableProvider = provider as? NTPObservableSectionProvider {
        observableProvider.sectionDidChange = { [weak self] in
          UIView.performWithoutAnimation {
            self?.collectionView.reloadSections(IndexSet(integer: index))
          }
        }
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    collectionView.reloadData()

    // Make sure that imageView has a frame calculated before we attempt
    // to use it.
    backgroundView.layoutIfNeeded()
    
    calculateBackgroundCenterPoints()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    reportSponsoredImageBackgroundEvent(.viewed)
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()

    backgroundButtonsView.collectionViewSafeAreaInsets = view.safeAreaInsets
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)

    backgroundView.imageView.image = parent == nil ? nil : background.backgroundImage
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if previousTraitCollection?.verticalSizeClass
      != traitCollection.verticalSizeClass {
      calculateBackgroundCenterPoints()
    }
  }

  // MARK: - Background

  func setupBackgroundImage() {
    collectionView.reloadData()

    if let backgroundType = background.currentBackground?.type {
      switch backgroundType {
      case .regular:
        if let name = background.currentBackground?.wallpaper.credit?.name {
          backgroundButtonsView.activeButton = .imageCredit(name)
        } else {
          backgroundButtonsView.activeButton = .none
        }
      case .withBrandLogo(let defaultLogo):
        guard let logo = background.currentBackground?.wallpaper.logo ?? defaultLogo else { break }
        backgroundButtonsView.activeButton = .brandLogo(logo)
      case .withQRCode(_):
        backgroundButtonsView.activeButton = .QRCode
      }
    } else {
      backgroundButtonsView.activeButton = .none
    }

    gradientView.isHidden = background.backgroundImage == nil
    backgroundView.imageView.image = background.backgroundImage
  }

  private func calculateBackgroundCenterPoints() {
    
    // Only iPhone portrait looking devices have their center of the image offset adjusted.
    // In other cases the image is always centered.
    guard let image = backgroundView.imageView.image,
            traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular else {
      // Reset the previously calculated offset.
      backgroundView.updateImageXOffset(by: 0)
      return
    }
    
    // If no focal point provided we do nothing. The image is centered by default.
    guard let focalX = background.currentBackground?.wallpaper.focalPoint?.x else {
      return
    }
    
    // Calculate the sizing difference between `image` and `imageView` to determine the pixel difference ratio.
    // Most image calculations have to use this property to get coordinates right.
    let sizeRatio = backgroundView.imageView.frame.size.height / image.size.height
    
    // How much the image should be offset according to the set focal point coordinate.
    // We calculate it by looking how much to move the image away from the center of the image.
    let focalXOffset = ((image.size.width / 2) - focalX) * sizeRatio
    
    // Amount of image space which is cropped on one side, not visible on the screen.
    // We use this info to prevent going of out image bounds when updating the `x` offset.
    let extraHorizontalSpaceOnOneSide = ((image.size.width * sizeRatio) - backgroundView.frame.width) / 2
        
    // The offset proposed by the focal point might be too far away from image's center
    // resulting in not having anough image space to cover entire width of the view and leaving blank space.
    // If the focal offset goes out of bounds we center it to the maximum amount we can where the entire
    // image is able to cover the view.
    let realisticXOffset = abs(focalXOffset) > extraHorizontalSpaceOnOneSide ?
      extraHorizontalSpaceOnOneSide : focalXOffset
    
    backgroundView.updateImageXOffset(by: realisticXOffset)
  }

  private func reportSponsoredImageBackgroundEvent(_ event: Ads.NewTabPageAdEventType) {
    guard let backgroundType = background.currentBackground?.type,
      case .withBrandLogo = backgroundType,
      let creativeInstanceId = background.currentBackground?.wallpaper.creativeInstanceId
    else {
      return
    }
  }

  // MARK: - Notifications

  private var notificationController: UIViewController?
  private var notificationShowing: Bool {
    notificationController?.parent != nil
  }

  private func hideNotification() {
    guard let controller = notificationController else { return }
    controller.willMove(toParent: nil)
    controller.removeFromParent()
    controller.view.removeFromSuperview()
    notificationController = nil
  }

  // MARK: - Brave News

  private var newContentAvailableDismissTimer: Timer? {
    didSet {
      oldValue?.invalidate()
    }
  }

  // MARK: - Actions

  private func tappedActiveBackgroundButton(_ sender: UIControl) {
    guard let background = background.currentBackground else { return }
    switch background.type {
    case .regular:
      presentImageCredit(sender)
    case .withBrandLogo(let defaultLogo):
      guard let logo = background.wallpaper.logo ?? defaultLogo else { break }
      tappedSponsorButton(logo)
    case .withQRCode(let code):
      tappedQRCode(code)
    }
  }

  private func tappedSponsorButton(_ logo: NTPLogo) {
    UIImpactFeedbackGenerator(style: .medium).bzzt()
    delegate?.navigateToInput(logo.destinationUrl, inNewTab: false, switchingToPrivateMode: false)

    reportSponsoredImageBackgroundEvent(.clicked)
  }

  private func tappedQRCode(_ code: String) {
    // Super referrer websites come in format https://brave.com/r/REF_CODE
    let refUrl = URL(string: "https://brave.com/")?
      .appendingPathComponent("r")
      .appendingPathComponent(code)

    guard let url = refUrl else { return }
    delegate?.tappedQRCodeButton(url: url)
  }

  private func handleFavoriteAction(favorite: Favorite, action: BookmarksAction) {
    delegate?.handleFavoriteAction(favorite: favorite, action: action)
  }

  private func presentImageCredit(_ button: UIControl) {
    guard let credit = background.currentBackground?.wallpaper.credit else { return }

    let alert = UIAlertController(title: credit.name, message: nil, preferredStyle: .actionSheet)

    if let creditWebsite = credit.url, let creditURL = URL(string: creditWebsite) {
      let websiteTitle = String(format: Strings.viewOn, creditURL.hostSLD.capitalizeFirstLetter)
      alert.addAction(
        UIAlertAction(title: websiteTitle, style: .default) { [weak self] _ in
          self?.delegate?.navigateToInput(creditWebsite, inNewTab: false, switchingToPrivateMode: false)
        })
    }

    alert.popoverPresentationController?.sourceView = button
    alert.popoverPresentationController?.permittedArrowDirections = [.down, .up]
    alert.addAction(UIAlertAction(title: Strings.close, style: .cancel, handler: nil))

    UIImpactFeedbackGenerator(style: .medium).bzzt()
    present(alert, animated: true, completion: nil)
  }
}

extension NewTabPageViewController: PreferencesObserver {
  func preferencesDidChange(for key: String) {
    if key == Preferences.NewTabPage.showNewTabPrivacyHub.key || key == Preferences.NewTabPage.showNewTabFavourites.key {
      collectionView.reloadData()
      return
    }
    
    if !preventReloadOnBraveNewsEnabledChange {
      collectionView.reloadData()
    }
    collectionView.verticalScrollIndicatorInsets = .zero
    backgroundButtonsView.alpha = 1.0
    preventReloadOnBraveNewsEnabledChange = false
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension NewTabPageViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    sections[indexPath.section].collectionView?(collectionView, didSelectItemAt: indexPath)
  }
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    sections[indexPath.section].collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? .zero
  }
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    let sectionProvider = sections[section]
    var inset = sectionProvider.collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAt: section) ?? .zero
    if sectionProvider.landscapeBehavior == .halfWidth {
      let isIphone = UIDevice.isPhone
      let isLandscape = view.frame.width > view.frame.height
      if isLandscape {
        let availableWidth = collectionView.bounds.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right
        if isIphone {
          inset.left = availableWidth / 2.0
        } else {
          inset.right = availableWidth / 2.0
        }
      }
    }
    return inset
  }
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    sections[section].collectionView?(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt: section) ?? 0
  }
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    sections[section].collectionView?(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: section) ?? 0
  }
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    sections[section].collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section) ?? .zero
  }
}

// MARK: - UICollectionViewDelegate
extension NewTabPageViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    sections[indexPath.section].collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
  }
  func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    sections[indexPath.section].collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
  }
}

// MARK: - UICollectionViewDataSource
extension NewTabPageViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    sections.count
  }
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    sections[section].collectionView(collectionView, numberOfItemsInSection: section)
  }
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    sections[indexPath.section].collectionView(collectionView, cellForItemAt: indexPath)
  }
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    sections[indexPath.section].collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) ?? UICollectionReusableView()
  }
  func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    sections[indexPath.section].collectionView?(collectionView, contextMenuConfigurationForItemAt: indexPath, point: point)
  }
  func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
    guard let indexPath = configuration.identifier as? IndexPath else {
      return nil
    }
    return sections[indexPath.section].collectionView?(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
  }
  func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
    guard let indexPath = configuration.identifier as? IndexPath else {
      return nil
    }
    return sections[indexPath.section].collectionView?(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
  }
  func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
    guard let indexPath = configuration.identifier as? IndexPath else {
      return
    }
    sections[indexPath.section].collectionView?(collectionView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
  }
}

// MARK: - UICollectionViewDragDelegate & UICollectionViewDropDelegate

extension NewTabPageViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {

  func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    // Check If the item that is dragged is a favourite item
    guard sections[indexPath.section] is FavoritesSectionProvider else {
      return []
    }

    let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
    let dragItem = UIDragItem(itemProvider: itemProvider).then {
      $0.previewProvider = { () -> UIDragPreview? in
        guard let cell = collectionView.cellForItem(at: indexPath) as? FavoriteCell else {
          return nil
        }
        return UIDragPreview(view: cell.imageView)
      }
    }

    return [dragItem]
  }

  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    guard let sourceIndexPath = coordinator.items.first?.sourceIndexPath else { return }
    let destinationIndexPath: IndexPath

    if let indexPath = coordinator.destinationIndexPath {
      destinationIndexPath = indexPath
    } else {
      let section = max(collectionView.numberOfSections - 1, 0)
      let row = collectionView.numberOfItems(inSection: section)
      destinationIndexPath = IndexPath(row: max(row - 1, 0), section: section)
    }

    guard sourceIndexPath.section == destinationIndexPath.section else { return }

    if coordinator.proposal.operation == .move {
      guard let item = coordinator.items.first else { return }

      Favorite.reorder(
        sourceIndexPath: sourceIndexPath,
        destinationIndexPath: destinationIndexPath,
        isInteractiveDragReorder: true
      )
      _ = coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)

    }
  }

  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    guard let destinationIndexSection = destinationIndexPath?.section,
      let favouriteSection = sections[destinationIndexSection] as? FavoritesSectionProvider,
      favouriteSection.hasMoreThanOneFavouriteItems
    else {
      return .init(operation: .cancel)
    }

    return .init(operation: .move, intent: .insertAtDestinationIndexPath)
  }

  func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
    fetchInteractionPreviewParameters(at: indexPath)
  }

  func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
    fetchInteractionPreviewParameters(at: indexPath)
  }

  func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
    return true
  }

  private func fetchInteractionPreviewParameters(at indexPath: IndexPath) -> UIDragPreviewParameters {
    let previewParameters = UIDragPreviewParameters().then {
      $0.backgroundColor = .clear

      if let cell = collectionView.cellForItem(at: indexPath) as? FavoriteCell {
        $0.visiblePath = UIBezierPath(roundedRect: cell.imageView.frame, cornerRadius: 8)
      }
    }

    return previewParameters
  }
}

extension NewTabPageViewController {
  private class NewTabCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
      super.init(frame: frame, collectionViewLayout: layout)

      backgroundColor = .clear
      delaysContentTouches = false
      alwaysBounceVertical = true
      showsHorizontalScrollIndicator = false
      // Needed for some reason, as its not setting safe area insets while in landscape
      contentInsetAdjustmentBehavior = .always
      showsVerticalScrollIndicator = false
      // Even on light mode we use a darker background now
      indicatorStyle = .white

      // Drag should be enabled to rearrange favourite
      dragInteractionEnabled = true
    }
    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError()
    }
    override func touchesShouldCancel(in view: UIView) -> Bool {
      return true
    }
  }
}
