@objc class FlokRtcModule : FlokModule {
    override var exports: [String] {
        return ["if_rtc_init:"]
    }
    
    func if_rtc_init(args: [AnyObject]) {
    }
}
