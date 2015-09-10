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
            self.topLabel?.text = titleText
            self.setNeedsLayout()
        }
    }
    
    var subTitleText: String? {
        didSet {
            self.bottomLabel?.text = subTitleText
            self.setNeedsLayout()
        }
    }
    
    var itemsCountText: String? {
        didSet {
            self.itemsCountLabel?.text = itemsCountText
            self.setNeedsLayout()
            self.dot?.removeFromSuperview()
        }
    }
    
    var wasReadCell: Bool {
        didSet {
            if wasReadCell {
                self.dot?.removeFromSuperview()
            }
            else {
                self.contentView.addSubview(self.dot!)
            }
        }
    }
    
    private var topLabel:        UILabel?
    private var bottomLabel:     UILabel?
    private var itemsCountLabel: UILabel?
    private var dot:             UIView?
    
    // MARK: - Init
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.wasReadCell = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.topLabel                  = UILabel()
        self.topLabel?.backgroundColor = UIColor.whiteColor()
        self.topLabel?.textAlignment   = NSTextAlignment.Left
        self.contentView.addSubview(self.topLabel!)
        
        self.bottomLabel                  = UILabel()
        self.bottomLabel?.backgroundColor = self.topLabel?.backgroundColor
        self.bottomLabel?.font            = UIFont (name: "HelveticaNeue-Light", size: 13.0)
        self.bottomLabel?.textAlignment   = NSTextAlignment.Left
        self.contentView.addSubview(self.bottomLabel!)
        
        self.itemsCountLabel                  = UILabel()
        self.itemsCountLabel?.backgroundColor = self.topLabel?.backgroundColor
        self.itemsCountLabel?.font            = UIFont (name: "HelveticaNeue", size: 10.0)
        self.itemsCountLabel?.textAlignment   = NSTextAlignment.Right
        self.contentView.addSubview(self.itemsCountLabel!)
        
        self.dot                  = UIView()
        self.dot?.backgroundColor = UIColor.orangeColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView override
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        var screenW: CGFloat = UIScreen.mainScreen().bounds.size.width
        
        self.topLabel?.sizeToFit()
        self.topLabel?.frame = CGRectIntegral(CGRectMake(15.0,
                                                         self.bounds.size.height / 2 - self.topLabel!.frame.size.height + 3.0,
                                                         screenW - 70.0,
                                                         self.topLabel!.frame.size.height))
        
        self.bottomLabel?.sizeToFit()
        self.bottomLabel?.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.topLabel!.frame),
                                                                          CGRectGetMaxY(self.topLabel!.frame),
                                                                          self.topLabel!.frame.size.width,
                                                                          self.bottomLabel!.frame.size.height))
        
        self.itemsCountLabel?.sizeToFit()
        self.itemsCountLabel?.frame = CGRectIntegral(CGRectMake(screenW - self.itemsCountLabel!.frame.size.width - 30.0,
                                        self.bounds.size.height / 2 - self.itemsCountLabel!.frame.size.height / 2,
                                        self.itemsCountLabel!.frame.size.width,
                                        self.itemsCountLabel!.frame.size.height))

        let dotSide: CGFloat = 5.0
        
        self.dot?.frame = CGRectMake(screenW - 40.0, self.bounds.size.height / 2 - dotSide / 2, dotSide, dotSide)
        
        self.dot?.layer.cornerRadius  = dotSide / 2
        self.dot?.layer.masksToBounds = true
    }
}
