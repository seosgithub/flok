@objc class FlokPingModule : FlokModule {
    override var exports: [String] {
        return ["ping:", "ping1:", "ping2:"]
    }
    
    func ping(args: [AnyObject]) {
        engine.intDispatch("pong", args: nil)
    }
    
    func ping1(args: [AnyObject]) {
        engine.intDispatch("pong1", args: args)
    }
    
    func ping2(args: [AnyObject]) {
        engine.intDispatch("pong2", args: [args[0]])
        engine.intDispatch("pong2", args: args)
    }
}
