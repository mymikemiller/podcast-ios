//
//  NullProfileCollectionViewCell.swift
//  Podcast
//
//  Created by Jack Thompson on 2/28/18.
//  Copyright © 2018 Cornell App Development. All rights reserved.
//

import UIKit
import SnapKit

class NullProfileCollectionViewCell: UICollectionViewCell {
    let addIconSize: CGFloat = 16
    
    //current user null profile
    var addIcon: UIImageView!
    
    //other user null profile
    var nullLabel: UILabel!
    let labelHeight: CGFloat = 21
    
    static var heightForCurrentUser: CGFloat = 100
    static var heightForUser: CGFloat = 24

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func setUp(user: User) {
        if System.currentUser == user {
            backgroundColor = .lightGrey
            
            addIcon = UIImageView()
            addIcon.image = #imageLiteral(resourceName: "add_icon")
            addSubview(addIcon)
            
            addIcon.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalTo(addIconSize)
            }
        }
        else {
            backgroundColor = .clear
            
            nullLabel = UILabel()
            nullLabel.text = "\(user.firstName) has not subscribed to any series yet."
            nullLabel.font = ._14RegularFont()
            nullLabel.textColor = .slateGrey
            nullLabel.textAlignment = .left
            addSubview(nullLabel)
            
            nullLabel.snp.makeConstraints { (make) in
                make.top.leading.equalToSuperview()
                make.height.equalTo(labelHeight)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
