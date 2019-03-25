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
    
    fileprivate var topLabel:        UILabel?
    fileprivate var bottomLabel:     UILabel?
    fileprivate var itemsCountLabel: UILabel?
    fileprivate var dot:             UIView?
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        wasReadCell = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        topLabel                       = UILabel()
        self.topLabel?.backgroundColor = UIColor.white
        self.topLabel?.font            = UIFont (name: "HelveticaNeue", size: topFontForDevice())
        self.topLabel?.textAlignment   = NSTextAlignment.left
        self.contentView.addSubview(self.topLabel!)
        
        bottomLabel                       = UILabel()
        self.bottomLabel?.backgroundColor = self.topLabel?.backgroundColor
        self.bottomLabel?.font            = UIFont (name: "HelveticaNeue-Light", size: bottomFontForDevice())
        self.bottomLabel?.textAlignment   = NSTextAlignment.left
        self.contentView.addSubview(self.bottomLabel!)
        
        itemsCountLabel                       = UILabel()
        self.itemsCountLabel?.backgroundColor = self.topLabel?.backgroundColor
        self.itemsCountLabel?.font            = UIFont (name: "HelveticaNeue", size: 10.0)
        self.itemsCountLabel?.textAlignment   = NSTextAlignment.right
        self.contentView.addSubview(self.itemsCountLabel!)
        
        dot                       = UIView()
        self.dot?.backgroundColor = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let screenW: CGFloat = UIScreen.main.bounds.size.width
        
        self.topLabel?.sizeToFit()
        self.topLabel?.frame = CGRect(x: 15.0,
                                                         y: self.bounds.size.height / 2 - self.topLabel!.frame.size.height + 1.0,
                                                         width: screenW - 70.0,
                                                         height: self.topLabel!.frame.size.height).integral
        
        self.bottomLabel?.sizeToFit()
        self.bottomLabel?.frame = CGRect(x: self.topLabel!.frame.minX,
                                                                          y: self.topLabel!.frame.maxY + 1.0,
                                                                          width: self.topLabel!.frame.size.width,
                                                                          height: self.bottomLabel!.frame.size.height).integral
        
        self.itemsCountLabel?.sizeToFit()
        self.itemsCountLabel?.frame = CGRect(x: screenW - self.itemsCountLabel!.frame.size.width - 40.0,
                                        y: self.bounds.size.height / 2 - self.itemsCountLabel!.frame.size.height / 2,
                                        width: self.itemsCountLabel!.frame.size.width,
                                        height: self.itemsCountLabel!.frame.size.height).integral

        let dotSide: CGFloat = 4.0
        
        self.dot?.frame               = CGRect(x: screenW - 40.0, y: self.bounds.size.height / 2 - dotSide / 2, width: dotSide, height: dotSide)
        self.dot?.layer.cornerRadius  = dotSide / 2
        self.dot?.layer.masksToBounds = true
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
