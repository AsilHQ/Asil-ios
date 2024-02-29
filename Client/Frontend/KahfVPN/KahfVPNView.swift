// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveUI

class KahfVPNView: UIView {

  let shieldsSwitch = ShieldsSwitch().then {
      $0.offBackgroundColor = .secondaryBraveBackground
  }

  private let braveShieldsLabel = UILabel().then {
    $0.text = "KahfDNS"
    $0.font = .systemFont(ofSize: 16, weight: .medium)
    $0.textColor = .braveLabel
  }

  let statusLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 16, weight: .bold)
    $0.text = Strings.Shields.statusValueUp.uppercased()
    $0.textColor = .braveLabel
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    let stackView = UIStackView().then {
      $0.axis = .vertical
      $0.spacing = 16
      $0.alignment = .center
      $0.layoutMargins = UIEdgeInsets(top: 24, left: 12, bottom: 24, right: 12)
      $0.isLayoutMarginsRelativeArrangement = true
    }

    addSubview(stackView)
    stackView.snp.makeConstraints {
      $0.edges.equalTo(self)
    }

    stackView.addStackViewItems(
      .view(shieldsSwitch),
      .view(
        UIStackView(arrangedSubviews: [braveShieldsLabel, statusLabel]).then {
          $0.spacing = 4
          $0.alignment = .center
        }),
      .customSpace(32)
    )
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}

// MARK: - BlockCountView

extension KahfVPNView {
  
  class BlockCountView: UIView {
    
    private struct UX {
      static let descriptionEdgeInset = UIEdgeInsets(top: 13, left: 16, bottom: 13, right: 16)
      static let iconEdgeInset = UIEdgeInsets(top: 22, left: 14, bottom: 22, right: 14)
      static let hitBoxEdgeInsets = UIEdgeInsets(equalInset: -10)
      static let buttonEdgeInsets = UIEdgeInsets(top: -3, left: 4, bottom: -3, right: 4)
    }

    let contentStackView = UIStackView().then {
      $0.spacing = 2
    }

    let descriptionStackView = ShieldsStackView(edgeInsets: UX.descriptionEdgeInset).then {
      $0.spacing = 16
    }

    override init(frame: CGRect) {
      super.init(frame: frame)

      isAccessibilityElement = true
      accessibilityTraits.insert(.button)
      accessibilityHint = Strings.Shields.blockedInfoButtonAccessibilityLabel
      addSubview(contentStackView)

      contentStackView.addStackViewItems(
        .view(descriptionStackView)
      )

      contentStackView.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError()
    }
  }
}

// MARK: - KahfVPNView

extension KahfVPNView {

  class ShieldsStackView: UIStackView {

    init(edgeInsets: UIEdgeInsets) {
      super.init(frame: .zero)

      alignment = .center
      layoutMargins = edgeInsets
      isLayoutMarginsRelativeArrangement = true
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError()
    }

    /// Adds Background to StackView with Color and Corner Radius
    public func addBackground(color: UIColor, cornerRadius: CGFloat? = nil) {
      let backgroundView = UIView(frame: bounds).then {
        $0.backgroundColor = color
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      }

      if let radius = cornerRadius {
        backgroundView.layer.cornerRadius = radius
        backgroundView.layer.cornerCurve = .continuous
      }

      insertSubview(backgroundView, at: 0)
    }
  }
}
