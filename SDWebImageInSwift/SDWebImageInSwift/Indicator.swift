//
//  Indicator.swift
//  SDWebImageInSwift
//
//  Created by 11111 on 2017/7/11.
//  Copyright © 2017年 ZheJiang WanHang Mdt InfoTech CO.,Ltd. All rights reserved.
//

import UIKit

typealias indicatorView = UIView

enum IndicatorType {
    
    case none
    case activity
    case progress
}

protocol Indicator {
    func startAnimation()
    func stopAniamtion()
    func dealWithProgress(received : Float)
    
    var viewCenter : CGPoint {
        get set
    }
    var view : indicatorView {
        get
    }
}

extension Indicator{
    var viewCenter :CGPoint{
        get{
            return view.center
        }
        set{
            view.center = newValue
        }
    }
}

class SystemIndicator: Indicator {
    
    private let systemIndicatorView : UIActivityIndicatorView
    
    var view: indicatorView{
        return systemIndicatorView
    }
    
    func startAnimation() {
        systemIndicatorView.startAnimating()
        systemIndicatorView.isHidden = false
    }
    
    func stopAniamtion() {
        systemIndicatorView.stopAnimating()
        systemIndicatorView.isHidden = true
    }
    
    func dealWithProgress(received: Float) {
        
    }
    
    init() {
        systemIndicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        systemIndicatorView.autoresizingMask = [UIViewAutoresizing.flexibleLeftMargin,.flexibleRightMargin,.flexibleBottomMargin,.flexibleTopMargin]
    }
    
}

class ProgressIndicator: Indicator {
    
    private let progressIndicatorView : UIProgressView
    
    var view: indicatorView{
        return progressIndicatorView
    }
    
    func startAnimation() {
        progressIndicatorView.isHidden = false
    }
    
    func stopAniamtion() {
        progressIndicatorView.isHidden = true
    }
    
    func dealWithProgress(received: Float) {
        progressIndicatorView.setProgress(received, animated: true)
    }
    
    init() {
        progressIndicatorView = UIProgressView.init()
        progressIndicatorView.backgroundColor = ColorMethodho(hexValue: 0xffffff)
        progressIndicatorView.progressTintColor = ColorMethodho(hexValue: 0x404040)
        progressIndicatorView.trackTintColor = ColorMethodho(hexValue: 0xb2b2b2)
        progressIndicatorView.progress = 0
        progressIndicatorView.autoresizingMask = [UIViewAutoresizing.flexibleLeftMargin,.flexibleRightMargin,.flexibleBottomMargin,.flexibleTopMargin]
    }
    
}

class sectorLayer: CAShapeLayer {
    
    
}
