//
//  EVKFeedCell.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/9/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedCell: UITableViewCell {

    // MARK: - Properties
    var titleText: String? {
        didSet {
            topLabel.text = titleText
            setNeedsLayout()
        }
    }
    
    var subTitleText: String? {
        didSet {
            bottomLabel.text = subTitleText
            setNeedsLayout()
        }
    }
    
    var itemsCountText: String? {
        didSet {
            itemsCountLabel.text = itemsCountText
            setNeedsLayout()
            dot.removeFromSuperview()
        }
    }
    
    var wasReadCell: Bool = false {
        didSet {
            if wasReadCell {
                dot.removeFromSuperview()
            }
            else {
                contentView.addSubview(dot)
            }
        }
    }
    
    fileprivate var topLabel: UILabel = UILabel()
    fileprivate var bottomLabel: UILabel = UILabel()
    fileprivate var itemsCountLabel: UILabel = UILabel()
    fileprivate var dot: UIView = UIView()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        topLabel.backgroundColor = .white
        topLabel.font            = UIFont(name: "HelveticaNeue", size: topFontForDevice())
        topLabel.textAlignment   = .left
        contentView.addSubview(topLabel)
        
        bottomLabel.backgroundColor = topLabel.backgroundColor
        bottomLabel.font            = UIFont(name: "HelveticaNeue-Light", size: bottomFontForDevice())
        bottomLabel.textAlignment   = .left
        contentView.addSubview(bottomLabel)
        
        itemsCountLabel.backgroundColor = topLabel.backgroundColor
        itemsCountLabel.font            = UIFont(name: "HelveticaNeue", size: 10.0)
        itemsCountLabel.textAlignment   = .right
        contentView.addSubview(itemsCountLabel)
        
        dot.backgroundColor = UIColor(named: "Tangerine")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let screenW: CGFloat = UIScreen.main.bounds.width
        
        topLabel.sizeToFit()
        topLabel.frame = CGRect(x: 15.0,
                                y: bounds.height / 2 - topLabel.frame.height + 1.0,
                                width: screenW - 70.0,
                                height: topLabel.frame.height).integral
        
        bottomLabel.sizeToFit()
        bottomLabel.frame = CGRect(x: topLabel.frame.minX,
                                   y: topLabel.frame.maxY + 1.0,
                                   width: topLabel.frame.width,
                                   height: bottomLabel.frame.height).integral
        
        itemsCountLabel.sizeToFit()
        itemsCountLabel.frame = CGRect(x: screenW - itemsCountLabel.frame.width - 40.0,
                                       y: bounds.height / 2 - itemsCountLabel.frame.height / 2,
                                       width: itemsCountLabel.frame.width,
                                       height: itemsCountLabel.frame.height).integral

        let dotSide: CGFloat = 4.0
        
        dot.frame = CGRect(x: screenW - 40.0, y: bounds.height / 2 - dotSide / 2, width: dotSide, height: dotSide)
        dot.layer.cornerRadius  = dotSide / 2
        dot.layer.masksToBounds = true
        
    }
    
    //MARK: - Helpers
    func topFontForDevice () -> CGFloat {
        let width = UIScreen.main.bounds.size.width
        
        var returnValue: CGFloat
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            returnValue = 20.0
        }
        else {
            returnValue = (width > 320) ? 16.0 : 14.0
        }
        
        return returnValue
    }
    
    func bottomFontForDevice () -> CGFloat {
        let width = UIScreen.main.bounds.size.width
        
        var returnValue: CGFloat
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            returnValue = 16.0
        }
        else {
            returnValue = (width > 320.0) ? 12.0 : 10.0
        }
        
        return returnValue
    }
}
