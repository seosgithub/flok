@objc class FlokControllerModule : FlokModule {
    override var exports: [String] {
        return ["if_controller_init:", "if_spec_controller_list:", "if_spec_controller_init:"]
    }
    
    static var cbpToView: WeakValueDictionary<Int, FlokView> = WeakValueDictionary()
    
    func if_controller_init(args: [AnyObject]) {
        let cbp = args[0] as! Int      //Controller base-pointer
        let vbp = args[1] as! Int      //View base-pointer
        let cname = args[2] as! String //Controller name
        let info = args[3] as! [String:AnyObject]
        
        //Lookup up view that is part of this controller
        let view = FlokUIModule.uiTpToSelector[vbp]
        if view == nil {
            NSException(name: "FlokControllerModule", reason: "Tried to lookup view with pointer \(vbp) but it didn't exist", userInfo: nil).raise()
            return
        }
        if let view = view as? FlokView {
            view.cbp = cbp
            view.context = info
            self.dynamicType.cbpToView[cbp] = view
            view.defaultInit()
        } else {
            NSException(name: "FlokControllerModule", reason: "For view with pointer \(vbp), it existed, but was not a FlokView", userInfo: nil).raise()
        }
    }
    
    func if_spec_controller_list(any: [AnyObject]) {
        //Will report incorrectly if called before the next loop as UIView's event
        //loop will need to remove the view
        dispatch_async(dispatch_get_main_queue()) {
            self.engine.int_dispatch([1, "spec", self.dynamicType.cbpToView.keys()])
        }
    }
    
    func if_spec_controller_init(any: [AnyObject]) {
        
    }
}