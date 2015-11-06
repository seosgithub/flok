@objc class FlokTimerModule : FlokModule {
    override var exports: [String] {
        return ["if_timer_init:"]
    }
    
    private static var tickHelper: TimerTickHelper!
    func if_timer_init(args: [AnyObject]) {
        let tps = args[0] as! Int
        
        let secondsPerInterval = 1 / Double(tps)
        self.dynamicType.tickHelper = TimerTickHelper(interval: secondsPerInterval) {
            self.engine.int_dispatch([0, "int_timer"])
        }
     
        self.dynamicType.tickHelper.start()
    }
}

@objc class TimerTickHelper : NSObject {
    let interval: Double
    let onTick: () -> ()
    init(interval: Double, onTick: ()->()) {
        self.interval = interval
        self.onTick = onTick
    }
    
    var timer: NSTimer!
    func start() {
        timer = NSTimer(timeInterval: interval, target: self, selector: "tick", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    func tick() {
        onTick()
    }
}
