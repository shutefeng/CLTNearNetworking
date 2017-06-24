//
//  CLTNNBluetoothServerService.swift
//  CLTNearNetworking
//
//  Created by Cc on 2017/2/5.
//  Copyright © 2017年 Cc. All rights reserved.
//

import UIKit
import CoreBluetooth

public class CLTNNBluetoothServerService: CLTNNServerNetworkNode {

    fileprivate let pServiceUUID: CBUUID
    fileprivate let pCharacteristicUUID: CBUUID
    fileprivate let pCharacteristicWriteUUID: CBUUID
    fileprivate let pMaxConnections: Int
    
    fileprivate var pCentralManager: CBCentralManager? = nil
    fileprivate var pPeripheral: CBPeripheral? = nil
    fileprivate var pCharacteristic: CBCharacteristic? = nil
    fileprivate var pCharacteristicRR: CBCharacteristic? = nil

    /// 这个是正在发送的对象，当有值时就开始发送它，如果它为nil表示已经完成
    fileprivate var pSendDataWriter: CLTNNSendDataWriter? = nil
    /// 收到的消息
    fileprivate var pReceiveDataReader: CLTNNReceiveDataReader? = nil
    
    let kLenSize = 64
    
    public init(serviceUUID: CBUUID, characteristicUUID: CBUUID, charachteristicWriteUUID: CBUUID, maxConnections:Int) {
        
        self.pServiceUUID = serviceUUID
        self.pCharacteristicUUID = characteristicUUID
        self.pCharacteristicWriteUUID = charachteristicWriteUUID
        self.pMaxConnections = maxConnections
        
        super.init()
    }
    
    deinit {
        
        self.fReleaseCentralManager()
    }
    
    func fInitCentralManager() {
        
        if self.pCentralManager == nil {
            
            self.pCentralManager = CBCentralManager.init(delegate: self, queue: nil)
        }
    }
    
    func fReleaseCentralManager() {
        
        if self.pCentralManager != nil {
            
            if let pP = self.pPeripheral {
            
                self.pCentralManager?.cancelPeripheralConnection(pP)
            }
            
            self.pCentralManager?.stopScan()
            self.pCentralManager?.delegate = nil
            self.pCentralManager = nil
        }
        
        self.fReleasePeripheral()
        
        if self.pCharacteristic != nil {
            
            self.pCharacteristic = nil
        }
    }
    
    fileprivate func fReleasePeripheral() {
        
        if self.pPeripheral != nil {
            
            self.pPeripheral?.delegate = nil
            self.pPeripheral = nil
        }
    }
    
    override public func fStartListening() {
        
        self.fInitCentralManager()
    }
    
    override public func fStopListening() {
        
        self.fReleaseCentralManager()
    }
    
    override func fOnSendMsgToOther(writer: CLTNNSendDataWriter) {
       
        self.pSendDataWriter = writer
        self.fSendData()
//        writer.pSendState = .eSendEnd
        
//        print("\(self.pCharacteristicRR?.properties)  \(CBCharacteristicProperties.writeWithoutResponse)")
//        if self.pCharacteristicRR?.properties == .writeWithoutResponse {
        
        
//        let dd = "ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss".data(using: String.Encoding.utf8)
//        self.pPeripheral?.writeValue(dd!, for: self.pCharacteristicRR!, type: CBCharacteristicWriteType.withResponse)
//        print("[Server] 发送 \(dd)")
//        
//        let ddd = "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww".data(using: String.Encoding.utf8)
//        self.pPeripheral?.writeValue(ddd!, for: self.pCharacteristicRR!, type: CBCharacteristicWriteType.withResponse)
//        print("[Server] 发送 \(ddd)")
//        }
        
        
    }
    
    func fSendStartDataMsg() {
        
        if self.pSendDataWriter?.pSendState == .eBeginSendHead {
            
            let sData = "S|".data(using: String.Encoding.utf8)!
            self.pPeripheral?.writeValue(sData, for: self.pCharacteristicRR!, type: CBCharacteristicWriteType.withResponse)
            
            self.pSendDataWriter?.pSendState = .eBeginSendBody
        }
    }
    
    func fSendEndDataMsg() {
        
        if self.pSendDataWriter?.pSendState == .eBeginSendEnd {
            
            let sData = "|E".data(using: String.Encoding.utf8)!
            self.pPeripheral?.writeValue(sData, for: self.pCharacteristicRR!, type: CBCharacteristicWriteType.withResponse)
            
            self.pSendDataWriter?.pSendState = .eSendEnd
            self.pDelegate?.dgClient_EndSendMsgToServer(writer: self.pSendDataWriter!)
            self.pSendDataWriter = nil
        }
    }
    
    func fSendData() {
        
        if let sendDataWriter = self.pSendDataWriter {
        
            self.fSendStartDataMsg()
            
            // send body
            if sendDataWriter.pSendState == .eBeginSendBody {
                
                while true {
                    
                    var amountToSend = sendDataWriter.pData.length - sendDataWriter.pSendDataIndex
                    
                    if amountToSend > kLenSize {
                        
                        amountToSend = kLenSize
                    }
                    
                    let chunk = Data.init(bytes: sendDataWriter.pData.bytes + sendDataWriter.pSendDataIndex, count: amountToSend)
                    
                    self.pPeripheral?.writeValue(chunk, for: self.pCharacteristicRR!, type: CBCharacteristicWriteType.withResponse)
                    
                    sendDataWriter.pSendDataIndex += amountToSend
                    
                    if sendDataWriter.pSendDataIndex >= sendDataWriter.pData.length {
                        
                        sendDataWriter.pSendState = .eBeginSendEnd
                        break
                    }
                }
            }
            
            self.fSendEndDataMsg()
        }
    }
}

// MARK: -
extension CLTNNBluetoothServerService: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            print("[Server] 启动搜索")
            self.pCentralManager?.scanForPeripherals(withServices: [self.pServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        default:
            print("[Server] 此设备不支持 BLE 4.0")
            break
        }
    }
    
    // 成功连接
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 发现服务
        print("[Server] 成功连接到 peripheral   开始搜索服务")
        self.pPeripheral = peripheral
        self.pPeripheral?.delegate = self
        self.pPeripheral?.discoverServices([self.pServiceUUID])
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("[Server] 连接丢失")
        self.fReleasePeripheral()
        
        self.centralManagerDidUpdateState(central)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        central.stopScan()
        if peripheral.state == .connected {
            
            central.retrieveConnectedPeripherals(withServices: [self.pServiceUUID])
        }
        else {
            
            self.pPeripheral = peripheral
            print("[Server] 找到 peripheral  开始连接")
            central.connect(peripheral, options: nil)
        }
    }
   
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        print("连接失败")
        self.fReleasePeripheral()
        
        self.centralManagerDidUpdateState(central)
    }
}

// MARK: -
extension CLTNNBluetoothServerService: CBPeripheralDelegate {
    
     public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            
            assert(false)
        }
        else {
            
            if peripheral.services == nil{
                
                assert(false)
                return
            }
            
            for service in peripheral.services! {
                
                if service.uuid == self.pServiceUUID && peripheral == self.pPeripheral {
                    
                    print("[Server] 一个一个响应 peripheral 的服务")
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
 
            assert(false)
        }
        else {
            
            if service.uuid == self.pServiceUUID && peripheral == self.pPeripheral {
                
                if service.characteristics == nil {
                    
                    assert(false)
                    return
                }
                
                for characteristic in service.characteristics! {
                
                    if characteristic.uuid == self.pCharacteristicUUID {
                        
                        print("[Server] 服务已经加载上   \(characteristic)")
                        self.pCharacteristic = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    if characteristic.uuid == self.pCharacteristicWriteUUID {
                        
                        print("[Server] 服务已经加载上   \(characteristic)")
                        self.pCharacteristicRR = characteristic
                    }
                }
                
                self.pDelegate?.dgNode_Connected()
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            
            assert(false)
        }
        else {
            
            if characteristic.uuid == self.pCharacteristicUUID && peripheral == self.pPeripheral {
                
                peripheral.readValue(for: characteristic)
                print("[Server] 开始读取数据")
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let datas = characteristic.value {
        
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
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        print("[Server] didModifyServices")
        self.fStartListening()
    }
}
