@objc class FlokTimerModule : FlokModule {
    override var exports: [String] {
        return ["if_timer_init:"]
    }
    
    func if_timer_init(args: [AnyObject]) {
        let tps = args[0] as! Int
    }
}
