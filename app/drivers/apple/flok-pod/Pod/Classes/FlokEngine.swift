import JavaScriptCore

@objc public protocol FlokEngineExports : JSExport {
    func if_dispatch(q: [AnyObject])
}

//Mostly for spec purposes
@objc public protocol FlokEnginePipeDelegate {
    optional func flokEngineDidReceiveIntDispatch(q: [AnyObject])
}

//Very-special class that adds methods from the modules
//at runtime via the objective-c runtime. Since they 
//already have the whole dynamic dispatch thing down,
//we'll use this instead of trying to roll our own.
@objc public class FlokRuntime : NSObject {
    dynamic weak var engine: FlokEngine!
    
    func addModule(module: FlokModule) {
        for e in module.exports {
            let klass = object_getClass(module)
            let method = class_getInstanceMethod(klass, Selector(e))
            
            class_addMethod(FlokRuntime.self, Selector(e), method_getImplementation(method), method_getTypeEncoding(method))
        }
    }
    
    //All runtimes should use this context to store data
    dynamic var context: [String:AnyObject] = [:]
}

@objc class FlokModule : NSObject {
    //List of method selectors that your module supports (for calling
    //via if_dispatch
    var exports: [String] {
        get {
            return [""]
        }
    }
    
    //The methods that are 'exported' are
    //added to 'FlokRuntime'.  So this dosen't actually
    //get called.  The FlokRuntime instance contains the
    //engine variable.
    dynamic var engine: FlokEngine!
    
    dynamic var context: [String:AnyObject]!
}

@objc public class FlokEngine : NSObject, FlokEngineExports {
    let context = JSContext()
    
    //Pointers to internal javascript methods & variables
    let intDispatchMethod: JSValue!
    
    var inPipeMode: Bool = false
    public weak var pipeDelegate: FlokEnginePipeDelegate?
    
    lazy var modules: [FlokModule] = [
        FlokPingModule(),
        FlokUiModule(),
        FlokNetModule(),
        FlokControllerModule(),
        FlokPersistModule(),
        FlokRtcModule(),
        FlokSockioModule(),
        FlokTimerModule(),
        FlokDlinkModule(),
        FlokEventModule(),
    ]
    lazy var runtime: FlokRuntime = FlokRuntime()
    
    public weak var rootView: UIView!
    
    public convenience init(src: String) {
        self.init(src: src, inPipeMode: false)
    }
    
    //Load with a javascript source, pipe mode intercepts
    //if_dispatch & int_dispatch
    public init(src: String, inPipeMode: Bool) {
        self.inPipeMode = inPipeMode
        
        //Add an exception handler
        context.exceptionHandler = { context, exception in
            NSException(name: "FlokEngineJavascriptRuntime", reason: exception.toString()!, userInfo: nil).raise()
            return
        }
        
        context.evaluateScript(src)
        
        //Grab the int_dispatch function
        intDispatchMethod = context.objectForKeyedSubscript("int_dispatch")
        if (intDispatchMethod.toString() == "undefined") {
            NSException(name: "FlokEngineJavascriptRuntime", reason: "Couldn't locate the int_dispatch function within the provided script", userInfo: nil).raise()
        }
        
        super.init()
        context.setObject(self, forKeyedSubscript: "swiftFlokEngine")
        context.evaluateScript("function if_dispatch(q) { if_dispatch_pending = q; }")
        
        runtime.engine = self
        for e in modules { runtime.addModule(e) }
    }
    
    public static func if_dispatch(q: [AnyObject]) {
        
    }
    
    //Call into the int_dispatch of the engine
    public func intDispatch(name: String, args: [AnyObject]?) {
        //Construct a packet
        var arr: [AnyObject] = [name]
        if let args = args { arr.appendContentsOf(args) }
        arr.insert(arr.count-1, atIndex: 0)
        
        int_dispatch(arr)
    }
    
    public func int_dispatch(q: [AnyObject]) {
        if (inPipeMode) {
            pipeDelegate?.flokEngineDidReceiveIntDispatch?(q)
        } else {
            intDispatchMethod.callWithArguments([q])
            
            let pending = context.evaluateScript("JSON.parse(JSON.stringify(if_dispatch_pending))").toArray()
            context.evaluateScript("if_dispatch_pending = []")
            if pending.count > 0 {
                if_dispatch(pending)
            }
        }
    }
    
    //Will be called by the JS engine itself or pipe to simulate the JS engine
    public func if_dispatch(q: [AnyObject]) {
        NSLog("Got q \(q)")
        //Priority array
        for qq in q {
            if let qq = qq as? String {
                if qq == "i" {
                    int_dispatch([])
                } else {
                    NSException(name: "FlokEngine", reason: "Got a string in the if_dispatch, but it wasn't 'i' for incomplete", userInfo: nil).raise()
                }
            } else if let qq = qq as? [AnyObject] {
                
                NSLog("\tDecoding q \(qq)")
                var priority = qq[0] as! Int
                var i = 1
                while (i < qq.count) {
                    var args: [AnyObject] = []
                    let argCount = qq[i++] as! Int
                    let cmd = qq[i++] as! String
                    args.appendContentsOf(qq[i..<(i+argCount)])
                    i += argCount
                    
                    NSLog("\t\tHandling \(cmd) with args: \(args)")
                    handleIfCommand(cmd, withArgs: args)
                }
            }
        }
    }
    
    func handleIfCommand(cmd: String, withArgs args: [AnyObject]) {
        NSLog("perform [\(cmd)] with args [\(args)]")
        if runtime.respondsToSelector(Selector("\(cmd):")) {
            runtime.performSelector(Selector("\(cmd):"), withObject: args)
        } else {
            NSLog("if_dispatch does not support the command '\(cmd):' with args \(args)")
        }
    }
}
