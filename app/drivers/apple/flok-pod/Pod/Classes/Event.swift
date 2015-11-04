@objc class FlokEventModule : FlokModule {
    override var exports: [String] {
        return ["if_event:"]
    }
    
    func if_event(args: [AnyObject]) {
        let ep = args[0] as! Int
        let name = args[1] as! String
        let info = args[2] as! [String:AnyObject]
        
        //Retrieve the view
        if let view = FlokControllerModule.cbpToView[ep] {
            if name == "action" {
                view.didSwitchFromAction(info["from"] as? String!, toAction: info["to"] as? String!)
            } else {
                view.didReceiveEvent(name, info: info)
            }
        } else {
            NSLog("Warning: event sent to view (controller) with controller base pointer \(ep) was dropped because the view no longer exists")
        }
    }
}
