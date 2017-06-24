//
//  CLTNNBluetoothClientService.swift
//  CLTNearNetworking
//
//  Created by Cc on 2017/2/5.
//  Copyright © 2017年 Cc. All rights reserved.
//

import UIKit
import CoreBluetooth

public class CLTNNBluetoothClientService: CLTNNClientNetworkNode {

    fileprivate let pServiceUUID: CBUUID
    fileprivate let pCharacteristicUUID: CBUUID
    fileprivate let pCharacteristicWriteUUID: CBUUID
    
    fileprivate var pPeripheralManager: CBPeripheralManager? = nil
    fileprivate var pMutableCharacteristic:CBMutableCharacteristic? = nil
    fileprivate var pMutableCharacteristicRR:CBMutableCharacteristic? = nil
    
    /// 这个是正在发送的对象，当有值时就开始发送它，如果它为nil表示已经完成
    fileprivate var pSendDataWriter: CLTNNSendDataWriter? = nil
    /// 收到的消息
    fileprivate var pReceiveDataReader: CLTNNReceiveDataReader? = nil
    
    let kLenSize = 64
    
    public init(serviceUUID: CBUUID, characteristicUUID: CBUUID, characteristicWriteUUID: CBUUID) {
        
        self.pServiceUUID = serviceUUID
        self.pCharacteristicUUID = characteristicUUID
        self.pCharacteristicWriteUUID = characteristicWriteUUID
        
        super.init()
    }
    
    deinit {
        
        self.fReleaseBluetoothClient()
    }
    
    func fInitBluetoothClient() {
        
        if self.pPeripheralManager == nil {
            
            self.pPeripheralManager = CBPeripheralManager.init(delegate: self, queue: nil)
        }
    }
    
    func fReleaseBluetoothClient() {
        
        if self.pPeripheralManager != nil {
            
            self.pPeripheralManager?.stopAdvertising()
            self.pPeripheralManager?.delegate = nil
            self.pPeripheralManager = nil
            
            self.pMutableCharacteristic = nil
        }
    }
    
    func fInitMutableCharacteristic() {
        
        if self.pMutableCharacteristic == nil {
            
            self.pMutableCharacteristic = CBMutableCharacteristic.init(type: self.pCharacteristicUUID, properties: CBCharacteristicProperties.notify, value: nil, permissions: CBAttributePermissions.writeEncryptionRequired)
            
            
            self.pMutableCharacteristicRR = CBMutableCharacteristic.init(type: self.pCharacteristicWriteUUID, properties: CBCharacteristicProperties.write, value: nil, permissions:  CBAttributePermissions.writeable)
            
            
            let customService = CBMutableService.init(type: self.pServiceUUID, primary: true)
            customService.characteristics = [self.pMutableCharacteristic!, self.pMutableCharacteristicRR!]
            
            self.pPeripheralManager?.add(customService)
        }
    }
    
    override public func fStartConnecting() {
        
        self.fInitBluetoothClient()
    }
    
    override public func fStopConnecting() {
        
        self.fReleaseBluetoothClient()
    }
    
    func fSendStartDataMsg() {
       
        if self.pSendDataWriter?.pSendState == .eBeginSendHead {
           
            let sData = "S|".data(using: String.Encoding.utf8)!
            let didSend = self.pPeripheralManager?.updateValue(sData, for: self.pMutableCharacteristic!, onSubscribedCentrals: nil)
            if didSend == true {
                
                self.pSendDataWriter?.pSendState = .eBeginSendBody
            }
        }
    }
    
    func fSendEndDataMsg() {
        
        if self.pSendDataWriter?.pSendState == .eBeginSendEnd {
            
            let sData = "|E".data(using: String.Encoding.utf8)!
            let didSend = self.pPeripheralManager?.updateValue(sData, for: self.pMutableCharacteristic!, onSubscribedCentrals: nil)
            if didSend == true {
                
                self.pSendDataWriter?.pSendState = .eSendEnd
                self.pDelegate?.dgClient_EndSendMsgToServer(writer: self.pSendDataWriter!)
                self.pSendDataWriter = nil
            }
        }
    }
    
    override func fOnSendMsgToOther(writer: CLTNNSendDataWriter) {
        
        self.pSendDataWriter = writer
        self.fSendData()
    }
    
    func fSendData() {
        
        if self.pSendDataWriter == nil {
            
            return
        }
        
        self.fSendStartDataMsg()
        
        // send body
        if self.pSendDataWriter!.pSendState == .eBeginSendBody {
            // There's data left, so send until the callback fails, or we're done.
            var didSend = true
            while didSend {
                // Work out how big it should be
                var amountToSend = self.pSendDataWriter!.pData.length - self.pSendDataWriter!.pSendDataIndex
                // Can't be longer than 32 bytes
                if amountToSend > kLenSize {
                    
                    amountToSend = kLenSize
                }
                // Copy out the data we want
                let chunk = Data.init(bytes: self.pSendDataWriter!.pData.bytes + self.pSendDataWriter!.pSendDataIndex, count: amountToSend)
                
                didSend = self.pPeripheralManager!.updateValue(chunk, for: self.pMutableCharacteristic!, onSubscribedCentrals: nil)
                // If it didn't work, drop out and wait for the callback
                if !didSend {
                    
                    break
                }
                // It did send, so update our index
                self.pSendDataWriter!.pSendDataIndex += amountToSend
                
                // We're sending data
                // Is there any left to send?
                if self.pSendDataWriter!.pSendDataIndex >= self.pSendDataWriter!.pData.length {
                    // No data left.  Do nothing
                    self.pSendDataWriter!.pSendState = .eBeginSendEnd
                    break
                }
            }
        }
        
        // 结束
        self.fSendEndDataMsg()
    }
}


// MARK: - 连接回调
extension CLTNNBluetoothClientService: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    
        switch peripheral.state {
        case .poweredOn:
            self.fInitMutableCharacteristic()
        default:
            print("[Client] 此设备不支持 BLE 4.0")
            break
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        
        if error != nil {
            
            print("[Client] peripheralManager:didAddService:error :\(String(describing: error))")
        }
        else {
            
            self.pPeripheralManager?.startAdvertising([
                CBAdvertisementDataLocalNameKey:"ICServer"
                , CBAdvertisementDataServiceUUIDsKey: [self.pServiceUUID]
                ])
        }
    }
    
    // 有设备连接
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        print("[Client] didSubscribeToCharacteristic 发现设备连接")
        self.pDelegate?.dgNode_Connected()
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
        print("[Client] 意外退出连接 didUnsubscribeFromCharacteristic")
        self.fStartConnecting()
    }
    
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        
        self.fSendData()
        print("[Client] 以前没有完全发送完毕 peripheralManagerIsReady")
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        
        print("[Client] 开始 advertising")
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
        print("[Client] 开始 读取数据")
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
       
        if let requ = requests.first {
        
            if requ.characteristic.uuid == self.pCharacteristicWriteUUID {
                
                print("[Client] 收到 \(String(describing: requ.value))")
                
                if let datas = requ.value {
                    
                    let str = String.init(data: datas, encoding: .utf8)
                    
                    if str == "S|" {
                        
                        self.pReceiveDataReader = CLTNNReceiveDataReader.init()
                    }
                    else if str == "|E" {
                        
                        self.pDelegate?.dgServer_ReceiveMsgFromClient(identifier: self.pReceiveDataReader!.fReadInt32(), reader: self.pReceiveDataReader!)
                    }
                    else if datas.count > 0 {
                        
                        self.pReceiveDataReader?.pData.append(datas)
                    }
                }
            }
            self.pPeripheralManager?.respond(to: requ, withResult: CBATTError.Code.success)
        }
    }
}
