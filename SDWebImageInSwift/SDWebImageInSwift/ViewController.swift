//
//  ViewController.swift
//  SDWebImageInSwift
//
//  Created by 11111 on 2017/7/11.
//  Copyright © 2017年 ZheJiang WanHang Mdt InfoTech CO.,Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    let cellKey = "webImageCellKey"
    
    lazy var tableView: UITableView = {
        let inner = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight), style: UITableViewStyle.grouped)
        inner.delegate = self
        inner.dataSource = self
        inner.separatorStyle = UITableViewCellSeparatorStyle.none
        inner.backgroundColor = ColorMethodho(hexValue: 0x333333).withAlphaComponent(0.2)
        
        return inner
    }()
    
    func initUI() {
        self.view.backgroundColor = ColorMethodho(hexValue: 0xffffff)
        
        let leftBt = UIBarButtonItem.init(title: "ClearCache",
                                          style: UIBarButtonItemStyle.plain,
                                          target: self,
                                          action: #selector(clearCache))
        self.navigationItem.leftBarButtonItem = leftBt
        
        let rightBt = UIBarButtonItem.init(title: "Reload",
                                           style: UIBarButtonItemStyle.plain,
                                           target: self,
                                           action: #selector(reloadList))
        self.navigationItem.rightBarButtonItem = rightBt
        
        tableView.register(TableViewCell.self, forCellReuseIdentifier: cellKey)
        self.view.addSubview(tableView)
    }
    
    func clearCache() {
        imageCacheInSwift.shareInstance.removeMemory()
        imageCacheInSwift.shareInstance.removeDisk()
    }
    
    func reloadList() {
        tableView.reloadData()
    }

}

extension ViewController : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let url = URL.init(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-1.jpg")!
        
        let cellHeight = cell.contentView.bounds.height
        let imageX : CGFloat = (ScreenWidth - cellHeight) / (20 - 1) * CGFloat.init(indexPath.row)
        (cell as! TableViewCell).cellImage.frame = CGRect.init(x: imageX, y: 0, width: cellHeight, height: cellHeight)
        
        (cell as! TableViewCell).cellImage.setImageWith(imageUrl: url,
                                                        placeholderImage: nil,
                                                        progressBlock: { (receivedSize, totalSize) in
                                                            print("\(indexPath.row + 1): \(receivedSize)/\(totalSize)")
        }) { (image, error, finish) in
            print("\(indexPath.row + 1): Finished")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey) as! TableViewCell
        cell.cellImage.indicatorType = .progress
        return cell

    }
}
