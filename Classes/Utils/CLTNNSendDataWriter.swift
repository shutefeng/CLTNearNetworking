//
//  CLTNNSendDataWriter.swift
//  CLTNearNetworking
//
//  Created by Cc on 2017/2/5.
//  Copyright © 2017年 Cc. All rights reserved.
//

import UIKit

public enum eCLTNNSendDataWriterState: Int {
    
    /// 0 = 初始化
    case eInit = 0
    
    /// 1=开始发送开始
    case eBeginSendHead = 1
    
    /// 2=开始发送结束并且开始发送身体
    case eBeginSendBody = 2
    
    /// 3=开始发送结束
    case eBeginSendEnd = 3
    
    /// 4=发送结束完成
    case eSendEnd = 4
}

public class CLTNNSendDataWriter: NSObject {

    lazy var pSendDataIndex: Int = 0
    lazy var pData = NSMutableData.init()
    lazy var pSendState:eCLTNNSendDataWriterState = .eInit
    
    public func fWriteInt32(_ source: Int32) {
        
        var ss = source
        let len = MemoryLayout.size(ofValue: source)
        self.pData.append(&ss, length: len)
    }
    
    public func fWriteData(_ source: Data) {
        
        let count = source.count
        
        self.fWriteInt32(Int32(count))
        self.pData.append(source)
    }
    
    public func fWriteString(_ source: String) {
       
        let tmpD = source.data(using: String.Encoding.utf8)

        self.fWriteData(tmpD!)
    }
}
