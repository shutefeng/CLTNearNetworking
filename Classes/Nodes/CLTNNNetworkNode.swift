//
//  CLTNNNetworkNode.swift
//  CLTNearNetworking
//
//  Created by Cc on 2017/2/5.
//  Copyright © 2017年 Cc. All rights reserved.
//

import UIKit

public protocol CLTNNNetworkNodeDelegate: NSObjectProtocol {
    
    func dgClient_EndSendMsgToServer(writer: CLTNNSendDataWriter)
    
    func dgServer_ReceiveMsgFromClient(identifier: Int32, reader: CLTNNReceiveDataReader)
    
    func dgNode_Connected()
}

public class CLTNNNetworkNode: NSObject {

    public weak var  pDelegate: CLTNNNetworkNodeDelegate?
    
    private lazy var pArrDataPackages = NSMutableArray.init()
   
    private let mLock = NSConditionLock.init()
    
    public func fBeginMsg(identifier: Int32, block: (_ writer: CLTNNSendDataWriter)->Void) {
        
        let wri = CLTNNSendDataWriter.init()
        wri.fWriteInt32(identifier)
        block(wri)
        self.pArrDataPackages.add(wri)
        self.fSendAllMsg()
    }
    
    func fSendAllMsg() {
        
        if self.pArrDataPackages.count > 0 {
            
            let tmpW = self.pArrDataPackages.firstObject as? CLTNNSendDataWriter
            if let writer = tmpW {
                
                if writer.pSendState == .eInit {
                    
                    writer.pSendState = .eBeginSendHead
                    self.fOnSendMsgToOther(writer: writer)
                }
                
                if (writer.pSendState == .eSendEnd) {
                    
                    self.pArrDataPackages.remove(writer)
                    self.fSendAllMsg()
                }
            }
        }
    }
    
    func fOnSendMsgToOther(writer: CLTNNSendDataWriter) {
        
        // 子类实现
        assert(false)
        writer.pSendState = .eSendEnd
    }
}

