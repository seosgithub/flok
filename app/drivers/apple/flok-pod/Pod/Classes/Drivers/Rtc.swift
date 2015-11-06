

@objc class FlokRtcModule : FlokModule {
    override var exports: [String] {
        return ["if_rtc_init:", "_if_rtc_tick_handler"]
    }
    
    static var tickHelper: TickHelper!
    func if_rtc_init(args: [AnyObject]) {
        self.dynamicType.tickHelper = TickHelper(interval: 1) { epoch in
            self.engine.int_dispatch([1, "int_rtc", epoch])
        }
        self.dynamicType.tickHelper.start()
    }
    
    func if_rtc() {
        
    }
}

@objc internal class TickHelper : NSObject {
    let interval: Double
    let onTick: (Int) -> ()
    init(interval: Double, onTick: (Int)->()) {
        self.interval = interval
        self.onTick = onTick
    }
    
    var timer: NSTimer!
    lazy var currentEpoch = Int(NSDate().timeIntervalSince1970)
    func start() {
        timer = NSTimer(timeInterval: interval, target: self, selector: "tick", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    func tick() {
        onTick(currentEpoch)
        ++currentEpoch
    }
}