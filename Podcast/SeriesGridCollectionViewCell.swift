//
//  SeriesGridCollectionViewCell.swift
//  Podcast
//
//  Created by Natasha Armbrust on 3/7/17.
//  Copyright © 2017 Cornell App Development. All rights reserved.
//
import SnapKit
import UIKit

class SeriesGridCollectionViewCell: UICollectionViewCell {
    
    
    let imageTitlePadding: CGFloat = 8
    let titleAuthorPadding: CGFloat = 2
    let frameHeight: CGFloat = 175
    
    var imageView: ImageView!
    var titleLabel: UILabel!
    var subscribersLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = ImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.width))
        addSubview(imageView)
        titleLabel = UILabel(frame: .zero)
        addSubview(titleLabel)
        subscribersLabel = UILabel(frame: .zero)
        addSubview(subscribersLabel)
        
        titleLabel.font = .systemFont(ofSize: 12, weight: UIFont.Weight.semibold)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .podcastBlack
        subscribersLabel.font = .systemFont(ofSize: 10, weight: UIFont.Weight.regular)
        subscribersLabel.textColor = .podcastGrayDark
        subscribersLabel.lineBreakMode = .byWordWrapping
        subscribersLabel.numberOfLines = 2
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(frame.width)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(imageTitlePadding)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        subscribersLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(titleAuthorPadding)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
    }
    
    func configureForSeries(series: Series, showLastUpdatedText: Bool = false) {
        if let url = series.largeArtworkImageURL {
            imageView.setImageAsynchronously(url: url, completion: nil)
        } else {
            imageView.image = #imageLiteral(resourceName: "nullSeries")
        }
        titleLabel.text = series.title
        
        if showLastUpdatedText {
            subscribersLabel.text = "Last updated " + Date.formatDateDifferenceByLargestComponent(fromDate: series.lastUpdated, toDate: Date())
        } else {
            subscribersLabel.text = series.numberOfSubscribers.shortString() + " Subscribers"
        }
        subscribersLabel.frame.origin.y = titleLabel.frame.maxY + titleAuthorPadding
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
