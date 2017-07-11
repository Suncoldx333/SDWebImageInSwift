//
//  GloBalDefine.swift
//  SDWebImageInSwift
//
//  Created by 11111 on 2017/7/11.
//  Copyright © 2017年 ZheJiang WanHang Mdt InfoTech CO.,Ltd. All rights reserved.
//

import UIKit

let ScreenWidth : CGFloat = UIScreen .main .bounds .size .width
let ScreenHeight : CGFloat = UIScreen .main .bounds .size .height
let ScreenHeightUnit :CGFloat = UIScreen .main .bounds .size .height * 1.000 / 667.000
let ScreenWidthUnit :CGFloat = UIScreen .main .bounds .size .width * 1.000 / 375.000

typealias swiftNoPatameterBlock = () -> Void

//颜色，Eg:ColorMethodho(0x00c18b)
func ColorMethodho(hexValue : Int) -> UIColor {
    let red   = ((hexValue & 0xFF0000) >> 16)
    let green = ((hexValue & 0xFF00) >> 8)
    let blue  = (hexValue & 0xFF)
    
    return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: CGFloat(1))
}

//获取View的frame相关信息
func ViewX(v : UIView) -> CGFloat{
    let x : CGFloat = v.frame.origin.x
    return x
}

func ViewY(v : UIView) -> CGFloat{
    let y : CGFloat = v.frame.origin.y
    return y
}

func ViewWidh(v : UIView) -> CGFloat{
    let width : CGFloat = v.frame.size.width
    return width
}

func ViewHeight(v : UIView) -> CGFloat{
    let height : CGFloat = v.frame.size.height
    return height
}

func ViewCenter(v : UIView) -> CGPoint{
    let center : CGPoint = CGPoint.init(x: v.frame.width / 2, y: v.frame.height / 2)
    return center
}

//富文本参数
let font_13_global = [NSFontAttributeName : UIFont.systemFont(ofSize: 13)]
let font_10_global = [NSFontAttributeName : UIFont.systemFont(ofSize: 10)]
let font_09_global = [NSFontAttributeName : UIFont.systemFont(ofSize: 9)]
let font_12_global = [NSFontAttributeName : UIFont.systemFont(ofSize: 12)]
let font_17_global = [NSFontAttributeName : UIFont.systemFont(ofSize: 17)]
let font_12_bold_global = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12)]
let font_13_bold_global = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 13)]
let font_18_bold_global = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 18)]
let font_10_bold_global = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 10)]
let font_25_bold_global = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 25)]

let color_66_global = [NSForegroundColorAttributeName : ColorMethodho(hexValue: 0x666666)]
let color_33_global = [NSForegroundColorAttributeName : ColorMethodho(hexValue: 0x333333)]
let color_b2_global = [NSForegroundColorAttributeName : ColorMethodho(hexValue: 0xb2b2b2)]
let color_e6_global = [NSForegroundColorAttributeName : ColorMethodho(hexValue: 0xe6e6e6)]
let color_8b_global = [NSForegroundColorAttributeName : ColorMethodho(hexValue: 0x00c18b)]
let color_80_global = [NSForegroundColorAttributeName : ColorMethodho(hexValue: 0x808080)]
let color_ff_global = [NSForegroundColorAttributeName : ColorMethodho(hexValue: 0xffffff)]

extension NSObject{
    /// 互斥锁方法,swift内没有类似@Synchronized的直接调用的方法
    /// 由于是对NSObject的扩展，使用时可能要注意命名重复
    ///
    /// - Parameters:
    ///   - lock: 互斥锁的对象
    ///   - f: 需要执行的方法
    func webImageCustomSynchronized(lock : AnyObject,f:() ->()) {
        objc_sync_enter(lock)
        f()
        objc_sync_exit(lock)
    }
}

extension String{
    func md5() -> String! {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int.init(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deinitialize()
        return String.init(format: "%@", hash as String)
        
    }
}

class GloBalDefine: NSObject {

}
