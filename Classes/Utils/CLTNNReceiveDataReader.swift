//
//  CLTNNReceiveDataReader.swift
//  CLTNearNetworking
//
//  Created by Cc on 2017/2/5.
//  Copyright © 2017年 Cc. All rights reserved.
//

import UIKit

public class CLTNNReceiveDataReader: NSObject {

    lazy var pData = NSMutableData.init()
    private lazy var pReadDataIndex: Int = 0
    
    public func fReadInt32() -> Int32 {
        
        var range = NSRange.init()
        range.location = self.pReadDataIndex;
        range.length = MemoryLayout.size(ofValue: Int32())
        self.pReadDataIndex += range.length
        var i: Int32 = 0
        self.pData.getBytes(&i, range: range)
        return i
    }
    
    public func fReadData() -> Data {
        
        let lenght = self.fReadInt32()
        let range = NSRange.init(location: self.pReadDataIndex, length: Int(lenght))
        self.pReadDataIndex += range.length
        let chunk = Data.init(bytes: self.pData.bytes + range.location, count: range.length)
        return chunk
    }
    
    public func fReadString() -> String {
        
        let chunk = self.fReadData()
        let str = String.init(data: chunk, encoding: String.Encoding.utf8)
        return str!
    }
}
