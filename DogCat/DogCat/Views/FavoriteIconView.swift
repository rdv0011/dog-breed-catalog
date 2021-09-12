//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import UIKit

/// Implements two ```UIViewImage``` that represents a like state
class FavoriteIconView: UIView {
    @UsesAutoLayout private var heartIconView = Asset.heart.imageView
    @UsesAutoLayout private var heartFillIconView = Asset.heartFill.imageView.then {
        $0.isHidden = true
    }
    var isOn: Bool = false {
        didSet {
            heartIconView.isHidden = !isOn
            heartFillIconView.isHidden = isOn
        }
    }

    init() {
        super.init(frame: .zero)
        configureViews()
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        addSubview(heartIconView)
        addSubview(heartFillIconView)
    }

    private func configureLayout() {
        heartIconView.fillSuperview()
        heartFillIconView.fillSuperview()
    }
}
