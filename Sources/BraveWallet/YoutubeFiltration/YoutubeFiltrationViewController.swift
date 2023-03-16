// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveCore
import Combine

public class YoutubeFiltrationViewController: UIHostingController<YoutubeFiltrationView> {
    
    public init() {
        super.init(rootView: YoutubeFiltrationView())
        rootView.dismissAction = { [unowned self] in
          self.dismiss(animated: true)
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIDevice.current.forcePortraitIfIphone(for: UIApplication.shared)
    }
    
    // MARK: -
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait, .portraitUpsideDown]
    }
    
    public override var shouldAutorotate: Bool {
        true
    }
}
