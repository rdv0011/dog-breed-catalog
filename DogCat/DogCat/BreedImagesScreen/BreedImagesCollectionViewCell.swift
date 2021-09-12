//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import UIKit
import Combine

/// Represents a collection view cell
///
/// Contains one image view and an icon to represent a like
/// Also contains an activity indicator to show a long running task(downloading an image)
final class BreedImagesCollectionViewCell: UICollectionViewCell {
    let iconMargin = CGFloat(8.0)
    lazy var imageView = ImageViewShadowed().then {
        // Kepp aspect ratio
        $0.contentMode = .scaleAspectFill
        $0.imageShadowOpacity = 0.8
        $0.imageShadowColor = .label
        $0.imageShadowRadius = 3
        $0.isAutoLayout = true
    }
    @UsesAutoLayout var activityIndicator = UIActivityIndicatorView().then {
        $0.hidesWhenStopped = true
        $0.style = .medium
        $0.color = .systemGray
        $0.startAnimating()
    }
    @UsesAutoLayout var favoriteView = FavoriteIconView()
    var imageDownloadingSubscription: AnyCancellable?
    var favoriteIconSubscription: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Setup subviews
        setupSubviews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log.verbose(.breedImages, "Deinit \(BreedImagesCollectionViewCell.self)")
    }

    private func setupSubviews() {
        // Image view
        addSubview(imageView)
        // Activity view
        addSubview(activityIndicator)
        // Favorite icon
        addSubview(favoriteView)
    }

    private func setupLayout() {
        // Image view
        imageView.fillSuperview()
        NSLayoutConstraint.activate([
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            // Favorite icon
            favoriteView.topAnchor.constraint(equalTo: self.topAnchor, constant: iconMargin),
            favoriteView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -iconMargin)
        ])
    }
}

extension BreedImagesCollectionViewCell: ReuseIdentifiable {
    static let reuseIdentifier = String(describing: self)
}
