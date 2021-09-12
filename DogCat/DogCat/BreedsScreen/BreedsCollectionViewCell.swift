//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import UIKit
import Combine

/// Represents a collection view cell
///
/// Contains one label view
/// - NOTE: This view tends to be as dummy as possible without any business logic at all
final class BreedsCollectionViewCell: UICollectionViewCell {
    @UsesAutoLayout var imageView = ImageViewShadowed().then {
        // Kepp aspect ratio
        $0.contentMode = .scaleAspectFill
        $0.imageShadowOpacity = 0.8
        $0.imageShadowColor = .label
        $0.imageShadowRadius = 3
    }
    @UsesAutoLayout var breedNameLabel = UILabel().then {
        $0.textAlignment = .center
        $0.backgroundColor = .systemBackground
    }
    @UsesAutoLayout var activityIndicator = UIActivityIndicatorView().then {
        $0.hidesWhenStopped = true
        $0.style = .medium
        $0.color = .systemGray
        $0.startAnimating()
    }
    var imageDownloadingSubscription: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Setup subviews
        setupSubviews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        // Image view
        addSubview(imageView)
        // Label
        addSubview(breedNameLabel)
        // Activity view
        addSubview(activityIndicator)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            // Image view
            imageView.leftAnchor.constraint(equalTo: self.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: self.rightAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            // Breed name
            breedNameLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
            breedNameLabel.rightAnchor.constraint(equalTo: self.rightAnchor),
            breedNameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

    }
}

extension BreedsCollectionViewCell: ReuseIdentifiable {
    static let reuseIdentifier = String(describing: self)
}
