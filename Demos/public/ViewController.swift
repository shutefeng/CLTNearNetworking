//
//  ViewController.swift
//  DemoNN
//
//  Created by Cc on 2017/2/5.
//  Copyright © 2017年 Cc. All rights reserved.
//

import UIKit
//import CLTNearNetworking
import CoreBluetooth

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        print("\(UUID.init().uuidString)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

let kServiceUUID = CBUUID.init(string: "54CC24BA-4445-4F12-A7D7-9EE7F25C573E")
let kCharacteristicUUID = CBUUID.init(string: "9B34BC05-E819-49DE-84B9-DC8B17DE0692")
let kCharacteristicRRUUID = CBUUID.init(string: "668F9736-4619-4EA4-9F14-4C18EB520EC5")

class ServerVC: UIViewController, CLTNNNetworkNodeDelegate {
    
    var server: CLTNNBluetoothServerService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let btn = UIButton.init()
        btn.frame = CGRect.init(x: 0, y: 100, width: self.view.bounds.width, height: 100)
        btn.setTitle("send", for: UIControlState.normal)
        btn.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.view.addSubview(btn)
        btn.addTarget(self, action: #selector(self.onClick(_:)), for: UIControlEvents.touchUpInside)
        
        self.server = CLTNNBluetoothServerService.init(serviceUUID: kServiceUUID, characteristicUUID: kCharacteristicUUID, charachteristicWriteUUID: kCharacteristicRRUUID,  maxConnections: 1)
        self.server?.pDelegate = self
        self.server?.fStartListening()
    }
    
    func dgClient_EndSendMsgToServer(writer: CLTNNSendDataWriter) {
        
    }
    func dgServer_ReceiveMsgFromClient(reader: CLTNNReceiveDataReader) {
       
        print("str0 = \(reader.fReadString())")
        print("str1 = \(reader.fReadString())")
        print("str2 = \(reader.fReadString())")
        print("str3 = \(reader.fReadString())")
        print("str4 = \(reader.fReadString())")
        print("str5 = \(reader.fReadString())")
        print("str6 = \(reader.fReadString())")
        print("str7 = \(reader.fReadString())")
        print("str8 = \(reader.fReadString())")
        print("str9 = \(reader.fReadString())")
    }
    func dgNode_Connected() {
        
        print("Server 连接成功")
    }
    

    func onClick(_ sender: Any) {
        
        self.server?.fBeginMsg(identifier: 1, block: { (writer: CLTNNSendDataWriter) in
            writer.fWriteString("111111")
            writer.fWriteString("222222")
            writer.fWriteString("333333")
            writer.fWriteString("444444")
            writer.fWriteString("555555")
            writer.fWriteString("666666")
            writer.fWriteString("777777")
            writer.fWriteString("888888")
            writer.fWriteString("999999")
            writer.fWriteString("000000")
        })
    }
}

class ClientVC: UIViewController, CLTNNNetworkNodeDelegate {
    
    var client: CLTNNBluetoothClientService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let btn = UIButton.init()
        btn.frame = CGRect.init(x: 0, y: 100, width: self.view.bounds.width, height: 100)
        btn.setTitle("send", for: UIControlState.normal)
        btn.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.view.addSubview(btn)
        btn.addTarget(self, action: #selector(self.onClick(_:)), for: UIControlEvents.touchUpInside)
        
        
        
        self.client = CLTNNBluetoothClientService.init(serviceUUID: kServiceUUID, characteristicUUID: kCharacteristicUUID, characteristicWriteUUID: kCharacteristicRRUUID)
        self.client?.pDelegate = self
        self.client?.fStartConnecting()
    }
    
    func dgClient_EndSendMsgToServer(writer: CLTNNSendDataWriter) {
        
    }
    func dgServer_ReceiveMsgFromClient(reader: CLTNNReceiveDataReader) {
        
        print("str0 = \(reader.fReadString())")
        print("str1 = \(reader.fReadString())")
        print("str2 = \(reader.fReadString())")
        print("str3 = \(reader.fReadString())")
        print("str4 = \(reader.fReadString())")
        print("str5 = \(reader.fReadString())")
        print("str6 = \(reader.fReadString())")
        print("str7 = \(reader.fReadString())")
        print("str8 = \(reader.fReadString())")
        print("str9 = \(reader.fReadString())")
    }
    func dgNode_Connected() {
        
        print("-- Client 连接成功")
    }
    
    func onClick(_ sender: Any) {
        
        self.client?.fBeginMsg(identifier: 2, block: { (writer: CLTNNSendDataWriter) in
            writer.fWriteString("000000")
            writer.fWriteString("999999")
            writer.fWriteString("888888")
            writer.fWriteString("777777")
            writer.fWriteString("666666")
            writer.fWriteString("555555")
            writer.fWriteString("444444")
            writer.fWriteString("333333")
            writer.fWriteString("222222")
            writer.fWriteString("111111")
        })
        
    }
}
