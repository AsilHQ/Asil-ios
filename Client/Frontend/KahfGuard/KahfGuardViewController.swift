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
class KahfGuardViewController: UIViewController, PopoverContentComponent {

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

  private var statsUpdateObservable: AnyObject?

  /// Create with an initial URL and block stats (or nil if you are not on any web page)
  init(tab: Tab) {
    self.tab = tab

    super.init(nibName: nil, bundle: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }
  // MARK: - State

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

  var shieldsView: View {
    return view as! View  // swiftlint:disable:this force_cast
  }

  override func loadView() {
      let newView = View(frame: .zero, url: url, tab: tab)
      view = newView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationController?.setNavigationBarHidden(true, animated: false)

    updatePreferredContentSize()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

extension KahfGuardViewController {
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

    let simpleShieldView = KahfGuardContentView()
    var url: URL?
    var tab: Tab

    init(frame: CGRect, url: URL?, tab: Tab) {
      self.url = url
      self.tab = tab
      super.init(frame: frame)

      backgroundColor = .braveBackground

      let popupView = KahfGuardContentView.redirect()
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
