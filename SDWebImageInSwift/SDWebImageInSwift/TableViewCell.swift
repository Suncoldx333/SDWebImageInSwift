//
//  TableViewCell.swift
//  SDWebImageInSwift
//
//  Created by 11111 on 2017/7/11.
//  Copyright © 2017年 ZheJiang WanHang Mdt InfoTech CO.,Ltd. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    lazy var cellImage: UIImageView = {
        let inner  = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.contentView.bounds.height, height: self.contentView.bounds.height))
        inner.backgroundColor = ColorMethodho(hexValue: 0x333333)
        inner.contentMode = UIViewContentMode.scaleToFill
        return inner
    }()
    
    func initUI() {
        self.contentView.backgroundColor = ColorMethodho(hexValue: 0x00c18b).withAlphaComponent(0.2)
        self.contentView.addSubview(cellImage)
    }

}
