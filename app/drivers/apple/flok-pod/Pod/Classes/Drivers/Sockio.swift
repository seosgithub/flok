@objc class FlokSockioModule : FlokModule {
    override var exports: [String] {
        return ["if_sockio_init:", "if_sockio_fwd:", "if_sockio_send:"]
    }
    
    func if_sockio_init(args: [AnyObject]) {
        let url = args[0] as! String
        let sp = args[1] as! Int
    }

    func if_sockio_fwd(args: [AnyObject]) {
        let sp = args[0] as! Int
        let eventName = args[1] as! String
        let bp = args[2] as! Int
    }

    func if_sockio_send(args: [AnyObject]) {
        let sp = args[0] as! Int
        let eventName = args[1] as! String
        let info = args[2] as! [String:AnyObject]
    }
}

