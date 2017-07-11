//
//  ImageManager.swift
//  SDWebImageInSwift
//
//  Created by 11111 on 2017/7/11.
//  Copyright © 2017年 ZheJiang WanHang Mdt InfoTech CO.,Ltd. All rights reserved.
//

import UIKit

typealias webImageCompletionWithFinishedBlock = (_ image : UIImage?, _ error : Error?, _ finished : Bool) ->Void
typealias webImageDownLoadCompletionBlock = (_ image : UIImage?, _ error : Error?,_ date : Data?, _ finished : Bool) ->Void
typealias webImageQueryCompletionBlock = (_ image : UIImage?) ->Void
typealias webImageNoParamsBlock = () ->Void
typealias webImageLoadProgressBlock = (_ receiveSize : Int64, _ totalSize : Int64) ->Void

struct webImageKey {
    static var imageUrlKey : String = "imageUrlKey"
    static var loadOperationKey : String = "loadOperationKey"
    static var indicatorKey : String = "indicator"
    static var indicatorTypeKey : String = "indicatorTypeKey"
}

extension UIImageView{
    
    var indicator : Indicator?{
        get{
            return (objc_getAssociatedObject(self, &webImageKey.indicatorKey) as? Box<Indicator?>)?.outValue
        }
        set{
            if let preIndicator = indicator {
                preIndicator.view.removeFromSuperview()
            }
            
            if var newIndicator = newValue {
                newIndicator.view.frame = self.frame
                newIndicator.viewCenter = ViewInnerCenter(v: self)
                newIndicator.view.isHidden = true
                self.addSubview(newIndicator.view)
            }
            
            objc_setAssociatedObject(self,
                                     &webImageKey.indicatorKey,
                                     Box.init(value: newValue),
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var indicatorType : IndicatorType{
        get{
            let inditype = (objc_getAssociatedObject(self, &webImageKey.indicatorTypeKey) as? Box<IndicatorType?>)?.outValue
            return inditype ?? .none
        }
        set{
            switch newValue {
            case .none:
                indicator = nil
            case .activity:
                indicator = SystemIndicator.init()
            case .progress:
                indicator = ProgressIndicator.init()
            }
            
            objc_setAssociatedObject(self,
                                     &webImageKey.indicatorTypeKey,
                                     Box.init(value: newValue),
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    /// 图片设置方法
    ///
    /// - Parameters:
    ///   - imageUrl: 图片地址
    ///   - placeholderImage: 置位图片
    ///   - progressBlock: 图片下载进度
    func setImageWith(imageUrl : URL!,
                      placeholderImage : UIImage? = nil,
                      progressBlock : webImageLoadProgressBlock? = nil,
                      completeBlock : webImageCompletionWithFinishedBlock? = nil) {
        self.cancelImageGainOperationWith(key: "UIImageViewImageLoad")
        
        objc_setAssociatedObject(self, &webImageKey.imageUrlKey, imageUrl, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        
        OperationQueue.main.addOperation {
            [weak self]() in
            self?.image = placeholderImage
        }
        let innerIndi = indicator
        innerIndi?.startAnimation()
        
        let operation : webImageGainOperation =
            ImageManager.shareInstance.gainImage(with: imageUrl,
                                                      progress: {
                                                        (receivedSize, totalSize) in
                                                        if let progress = progressBlock,let aindi = innerIndi as? ProgressIndicator{
                                                            let percent = Double.init(receivedSize) * 1.000 / (Double.init(totalSize) * 1.000)
                                                            aindi.makeProgress(received: Float.init(percent))
                                                            progress(receivedSize,totalSize)
                                                        }
            },
                                                      complete: { (image, error, finish) in
                                                        
                                                        innerIndi?.stopAniamtion()
                                                        
                                                        if let innerCom = completeBlock{
                                                            innerCom(image,error,finish)
                                                        }
                                                        
                                                        OperationQueue.main.addOperation {
                                                            [weak self]() in
                                                            if let innerImage = image{
                                                                self?.image = innerImage
                                                            }
                                                        }
                                                        
            })
        
        
        self.setGainImage(operation: operation, key: "UIImageViewImageLoad")
    }
    
    //以下两个方法及一个变量，其实并不是ImageView的扩展，仅仅是setImageWith的工具方法，需要考虑一个方案使这两个方法存在于更适合的地方
    private func cancelImageGainOperationWith(key : String) {
        var operationDicInner : Dictionary<String,Array<webImageGainOperation>> = self.operationDic
        if let operationArr = operationDicInner[key] {
            let _ = operationArr.map({ (Operation) -> Void in
                Operation.cancel()
            })
            operationDicInner.removeValue(forKey: key)
        }
    }
    
    private func setGainImage(operation : webImageGainOperation,key : String) {
        cancelImageGainOperationWith(key: key)
        
        var operationDicInner : Dictionary<String,Array<webImageGainOperation>> = self.operationDic
        var operationArr = operationDicInner[key]
        if operationArr == nil {
            operationArr = [webImageGainOperation]()
        }
        operationArr?.append(operation)
        operationDicInner.updateValue(operationArr!, forKey: key)
        self.operationDic = operationDicInner
    }
    
    private var operationDic : Dictionary<String,Array<webImageGainOperation>>! {
        get{
            var opDic = (objc_getAssociatedObject(self, &webImageKey.loadOperationKey) as? Box<Dictionary<String,Array<webImageGainOperation>>>)?.outValue
            if opDic == nil {
                opDic = [String : Array<webImageGainOperation>]()
                objc_setAssociatedObject(self, &webImageKey.loadOperationKey, Box.init(value: opDic), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return opDic
            }
            return opDic!
        }
        set{
            objc_setAssociatedObject(self, &webImageKey.loadOperationKey, Box.init(value: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

//MARK:---图片管理类
class ImageManager: NSObject {
    
    static let shareInstance = ImageManager()
    private override init() {
        
    }
    
    var failedURLs : Set = Set<URL>.init()  //下载失败的URL集合
    var runningoperatins : NSMutableArray = NSMutableArray.init()  //正在执行的任务的集合,array的remove方法没有NSArray的直接
    var imageCache : imageCacheInSwift = imageCacheInSwift.shareInstance  //图片缓存对象
    var imageLoder : imageLoadInSwift = imageLoadInSwift.init()  //图片下载对象
    
    func gainImage(with url : URL,
                   progress : webImageLoadProgressBlock?,
                   complete : webImageCompletionWithFinishedBlock?) -> webImageGainOperation {
        
        let operation : webImageGainOperation? = webImageGainOperation.init()
        
        var isFailedUrl : Bool = false
        webImageCustomSynchronized(lock: failedURLs as AnyObject) {
            isFailedUrl = failedURLs.contains(url)
        }
        
        if url.absoluteString.characters.count == 0 || isFailedUrl {
            return operation!
        }
        
        webImageCustomSynchronized(lock: runningoperatins as AnyObject) {
            runningoperatins.add(operation!)
        }
        
        let key = url.absoluteString
        operation?.cacheOperation = imageCache.queryDiskCacheFor(key: key, done: { [weak self](cachedImage) in
            
            if (operation?.isCancelled)! {
                self?.webImageCustomSynchronized(lock: self?.runningoperatins as AnyObject, f: {
                    self?.runningoperatins.remove(operation!)
                })
                return
            }
            
            if let innerImage = cachedImage,let innerComplete = complete{
                innerComplete(innerImage, nil, true)
                return
            }
            
            let imageLoadOperation : webImageDownLoaderOperation =
                (self?.imageLoder.downLoadImage(with: url,
                                                progress: { (receivedSize, totalSize) in
                                                    if let innerPro = progress{
                                                        innerPro(receivedSize,totalSize)
                                                    }
                },
                                                complete: { [weak self](image, error, data, finished) in
                                                    if let innerCom = complete{
                                                        guard let innerOp = operation else {
                                                            print("image gain operation is nil")
                                                            return
                                                        }
                                                        if finished == true{
                                                            self?.webImageCustomSynchronized(lock: (self?.runningoperatins)!, f: {
                                                                self?.runningoperatins.remove(innerOp)
                                                            })
                                                        }
                                                        
                                                        guard let innerError = error else{
                                                            if let innerImage = image,let innerData = data{
                                                                self?.imageCache.store(downLoadImage: innerImage, and: innerData, forGiven: key)
                                                                OperationQueue.main.addOperation {
                                                                    innerCom(innerImage,nil,finished)
                                                                }
                                                            }
                                                            return
                                                        }
                                                        self?.webImageCustomSynchronized(lock: self?.failedURLs as AnyObject, f: {
                                                            self?.failedURLs.insert(url)
                                                        })
                                                        OperationQueue.main.addOperation {
                                                            innerCom(nil,innerError,finished)
                                                        }
                                                    }
                }))!
            
            
            
            
            
            operation?.cancelBlock = {
                () in
                imageLoadOperation.cancel()
                self?.webImageCustomSynchronized(lock: operation!, f: {
                    self?.runningoperatins.remove(operation!)
                })
            }
        })
        
        return operation!
    }
}

//MARK:---图片查找缓存类
class imageCacheInSwift : NSObject{
    static let shareInstance = imageCacheInSwift()
    
    var memCache : autoPurgeCache!
    var webImageSerialQueue : OperationQueue!
    var diskCachePath : String!
    var fileManager : FileManager!
    
    private override init() {
        memCache = autoPurgeCache.init()
        memCache.name = "helloWebImage"
        
        webImageSerialQueue = OperationQueue.init()
        webImageSerialQueue.maxConcurrentOperationCount = 1
        
        fileManager = FileManager.init()
        
        let diskPath : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        diskCachePath = URL.init(string: diskPath)?.appendingPathComponent("default").absoluteString
    }
    
    func queryDiskCacheFor(key : String?,done : @escaping webImageQueryCompletionBlock) -> Operation? {
        
        guard let innerKey = key else {
            done(nil)
            return nil
        }
        
        if let cachedImage = memCache.object(forKey: innerKey as AnyObject) as? UIImage{
            print("catch Image in memCache")
            done(cachedImage)
            return nil
        }
        
        let operation : Operation = BlockOperation.init {
            print("hello,diskImage")
        }
        webImageSerialQueue.addOperation {
            () in
            if operation.isCancelled == true {
                return
            }
            
            autoreleasepool(invoking: { () -> Void in
                //查找存放在sandbox中的图片
                if let diskImage = self.diskImageFor(key: key!) {
                    let cost = diskImage.size.width * diskImage.size.height * diskImage.scale * diskImage.scale
                    self.memCache.setObject(diskImage, forKey: key as AnyObject, cost: Int.init(cost))
                    OperationQueue.main.addOperation {
                        done(diskImage)
                    }
                }else{
                    OperationQueue.main.addOperation {
                        done(nil)
                    }
                }
            })
            
        }
        return operation
    }
    
    func store(downLoadImage : UIImage!,and imageData : Data!,forGiven key : String!) {
        
        //存储于Cache
        let imageCost : Int = Int.init(downLoadImage.size.width * downLoadImage.size.height * downLoadImage.scale * downLoadImage.scale)
        memCache.setObject(downLoadImage, forKey: key as AnyObject, cost: imageCost)
        
        //存储于Disk
        webImageSerialQueue.addOperation {
            [weak self]() in
            self?.storeImageInDisk(downLoadImage: downLoadImage, and: imageData, forGiven: key)
        }
    }
    
    func storeImageInDisk(downLoadImage : UIImage!,and imageData : Data!,forGiven key : String!) {
        //UIImage -> DATA 区分PNG,JPG
        //两者区别在于PNG支持透明度，而JPG不支持
        //PNG格式往往以137 80 78 71 13 10 26 10开头(十进制)
        var changedData : Data = imageData
        let PNGSignatureBytes : Array<UInt8> = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let PNGSignatureData : Data = Data.init(bytes: PNGSignatureBytes)
        
        let alphaInfo : CGImageAlphaInfo = (downLoadImage.cgImage?.alphaInfo)!
        var imageIsPNG : Bool = !(alphaInfo == CGImageAlphaInfo.none ||
            alphaInfo == CGImageAlphaInfo.noneSkipFirst ||
            alphaInfo == CGImageAlphaInfo.noneSkipLast)
        
        if imageData.count > PNGSignatureData.count {
            
            let signatureRang : Range<Data.Index> = PNGSignatureData.startIndex ..< PNGSignatureData.endIndex
            imageIsPNG = imageData.subdata(in: signatureRang) == PNGSignatureData ? true : false
        }
        
        if imageIsPNG == true {
            changedData = UIImagePNGRepresentation(downLoadImage)!
        }else{
            changedData = UIImageJPEGRepresentation(downLoadImage, 1.0)!
        }
        
        //存储至Disk
        if fileManager.fileExists(atPath: diskCachePath) == false {
            do{
                try fileManager.createDirectory(atPath: diskCachePath, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("create fail")
            }
        }
        
        let imageKeyInMD5 = key.md5() + "." + (URL.init(string: key)?.pathExtension)!
        let defaultPath : URL = (URL.init(string: diskCachePath)?.appendingPathComponent(imageKeyInMD5))!
        let fileCreate : Bool = fileManager.createFile(atPath: defaultPath.absoluteString, contents: changedData, attributes: nil)
        if fileCreate == false {
            print("image file create fail")
        }
    }
    
    func diskImageFor(key : String) -> UIImage? {
        
        let imageKeyInMD5 = key.md5() + "." + (URL.init(string: key)?.pathExtension)!
        let defaultPath : URL = (URL.init(string: diskCachePath)?.appendingPathComponent(imageKeyInMD5))!
        
        if let dataInNS = NSData.init(contentsOfFile: defaultPath.absoluteString) {
            print("catch Image In \(defaultPath)")
            let diskCahcedImage = UIImage.init(data: dataInNS as Data)
            
            let imageCost : Int = Int.init(diskCahcedImage!.size.width * diskCahcedImage!.size.height * diskCahcedImage!.scale * diskCahcedImage!.scale)
            memCache.setObject(diskCahcedImage!, forKey: key as AnyObject, cost: imageCost)
            
            return diskCahcedImage
        }
        
        return nil
    }
    
    func removeMemory() {
        self.memCache.removeAllObjects()
        print("helloMemRemove")
    }
    
    func removeDisk() {
        webImageSerialQueue.addOperation {
            [weak self] in
            do{
                try self?.fileManager.removeItem(atPath: (self?.diskCachePath)!)
                try self?.fileManager.createDirectory(atPath: (self?.diskCachePath)!,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
            }
            catch _ { }
        }
    }
    
}

//MARK:---图片下载类
struct imageLoadInSwift {
//    static let shareInstance = imageLoadInSwift()
//    private override init() {
//        
//    }
    
    let header = ["Accept" : "image/*;q=0.8"];
    let operationQueue : OperationQueue = OperationQueue.init()
    
    func downLoadImage(with url : URL,
                       progress : webImageLoadProgressBlock?,
                       complete : webImageDownLoadCompletionBlock?) -> webImageDownLoaderOperation {
        var operation : webImageDownLoaderOperation!
        
        func addProgressCallBack(complete : webImageDownLoadCompletionBlock,
                                 progress : webImageLoadProgressBlock,
                                 url : URL,
                                 callBack : webImageNoParamsBlock) {
            callBack()
        }
        
        if let innerCom = complete,let innerPro = progress {
            addProgressCallBack(complete: innerCom,
                                progress: innerPro,
                                url: url) {
                                    () in
                                    var request : URLRequest = URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10.0)
                                    request.httpShouldUsePipelining = true
                                    request.allHTTPHeaderFields = self.header
                                    operation = webImageDownLoaderOperation.init(request: request,
                                                                                 progress: { (receivedSie, totalSize) in
                                                                                    innerPro(receivedSie,totalSize)
                                    },
                                                                                 completed: { (image, error, data, finished) in
                                                                                    innerCom(image,error,data,finished)
                                    })
                                    
                                    self.operationQueue.addOperation(operation)
            }
        }
        
        
        return operation
    }
    
    
}

//MARK:---图片下载任务
class webImageDownLoaderOperation: Operation {
    
    var requestCopyed : URLRequest!
    var progressBlock : webImageLoadProgressBlock!
    var completeBlock : webImageDownLoadCompletionBlock!
    var session : URLSession!
    var dataTask_request : URLSessionDataTask!
    
    var receiveData = Data()
    
    init(request : URLRequest,
         progress : @escaping webImageLoadProgressBlock,
         completed : @escaping webImageDownLoadCompletionBlock) {
        
        self.requestCopyed = request
        self.progressBlock = progress
        self.completeBlock = completed
    }
    
    override func start() {
        webImageCustomSynchronized(lock: self) {
            () in
            
            let configuration : URLSessionConfiguration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 10
            self.session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            dataTask_request = self.session.dataTask(with: self.requestCopyed)
            
            dataTask_request.resume()
            
        }
        
        
    }
    override func cancel() {
        print("loadCancel")
        dataTask_request.cancel()
    }
}

//MARK:---URLSession(URLSessionDataDelegate)
extension webImageDownLoaderOperation : URLSessionDataDelegate{
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard let innerError = error else {
            if let innerImage = UIImage.init(data: receiveData) {
                
                self.completeBlock(innerImage,nil,receiveData,true)
            }else{
                self.completeBlock(nil,nil,receiveData,false)
            }
            return
        }
        
        self.completeBlock(nil,innerError,receiveData,false)
        
        receiveData = Data.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        receiveData.append(data)
        self.progressBlock(Int64(receiveData.count),dataTask.response?.expectedContentLength ?? 0)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let newRes : HTTPURLResponse = response as! HTTPURLResponse
        print("responesCode = \(newRes.statusCode)")
        
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
}

/// 接到内存警告会清除所有缓存的一个缓存类
class autoPurgeCache : NSCache<AnyObject, AnyObject> {
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(removeAllObjects), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
}

/// 图片获取任务
/// 设计出来是用以实现取消获取任务，同时取消图片下载的任务
class webImageGainOperation : NSObject{
    var isCancelled : Bool = false
    var cancelBlock : webImageNoParamsBlock?
    var cacheOperation : Operation?
    
    func cancel() {
        self.isCancelled = true
        
        //从Disk获取图片存在于一个串行队列中，cacheOperation用于前置判断是否取消图片获取
        if self.cacheOperation != nil {
            self.cacheOperation?.cancel()
            self.cacheOperation = nil
        }
        
        if self.cancelBlock != nil {
            self.cancelBlock!()
            self.cancelBlock = nil
        }
        
        
    }
}

