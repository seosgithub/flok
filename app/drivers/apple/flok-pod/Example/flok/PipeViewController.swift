//Provides the remote pipe used in testing that talks directly to the JS environment

import Foundation
import CocoaAsyncSocket
import flok

class PipeViewController : UIViewController, GCDAsyncSocketDelegate, FlokEnginePipeDelegate {
    var socketQueue: dispatch_queue_t! = nil
    var listenSocket: GCDAsyncSocket! = nil
    var connectedSockets: NSMutableArray! = nil
    var flok: FlokEngine! = nil
    
    override func viewDidLoad() {
        socketQueue = dispatch_queue_create("socketQueue", nil)
        listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)
        
        do {
            try listenSocket!.acceptOnPort(6969)
        } catch {
            NSException.raise("PipeViewControllerSocketListenError", format: "Could not listen on port 6969", arguments: getVaList([]))
        }
        
        connectedSockets = NSMutableArray(capacity: 9999)
        
        let srcPath = NSBundle.mainBundle().pathForResource("app", ofType: "js")
        let srcData = NSData(contentsOfFile: srcPath!)
        let src = NSString(data: srcData!, encoding: NSUTF8StringEncoding) as! String
        flok = FlokEngine(src: src, inPipeMode: true)
        flok.rootView = self.view
        flok.pipeDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Override point for customization after application launch.
        FlokViewConceierge.registeredViews = [
            "spec_blank":SpecBlank.self,
            "spec_one_spot":SpecOneSpot.self,
            "spec_two_spot":SpecTwoSpot.self,
        ]
        FlokViewConceierge.preload()
    }
    
    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
            if (self == nil) { return }
            
            NSLog("Accepted host, id: \(self!.connectedSockets!.count-1)")
            self!.connectedSockets.addObject(newSocket)
            
            let helloPayload = NSString(string: "HELLO\r\n").dataUsingEncoding(NSUTF8StringEncoding)
            newSocket.writeData(helloPayload, withTimeout: -1, tag: 0)
            newSocket.readDataWithTimeout(-1, tag: 0)
        }
    }
    
    var stream: NSString = ""
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        stream = stream.stringByAppendingString(str)
        
        let process = { (e: String) in
            do {
                var out: AnyObject
                try out = NSJSONSerialization.JSONObjectWithData(e.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), options: NSJSONReadingOptions.AllowFragments) as AnyObject
                dispatch_async(dispatch_get_main_queue(), {
                    if let out = out as? [AnyObject] {
                        self.flok.if_dispatch(out)
                    } else {
                        NSLog("Couldn't parse out: \(out)")
                    }
                })
            } catch let error {
                NSLog("failed to parse JSON...: \(str), \(error)")
            }
        }
        
        let components = stream.componentsSeparatedByString("\r\n")
        for (i, e) in components.enumerate() {
            if i == components.count-1 {
                stream = NSString(string: e)
            } else {
                process(e)
            }
        }
        
        sock.readDataWithTimeout(-1, tag: 0)
    }
    
    //The engine, which is just stubbed atm, received a request (which is just forwarded externally for now)
    func flokEngineDidReceiveIntDispatch(q: [AnyObject]) {
        //Send out to 'stdout' of network pipe
        let lastSocket = connectedSockets.lastObject
        if let lastSocket = lastSocket {
            do {
                var payload: NSData?
                try payload = NSJSONSerialization.dataWithJSONObject(q, options: NSJSONWritingOptions(rawValue: 0))
                if let payload = payload {
                    lastSocket.writeData(payload, withTimeout: -1, tag: 0)
                    lastSocket.writeData(("\r\n" as NSString).dataUsingEncoding(NSUTF8StringEncoding), withTimeout: -1, tag: 0)
                } else {
                    puts("couldn't convert object \(q) into JSON")
                }
            } catch {
                puts("Couldn't create payload for int_dispatch to send to pipe")
            }
        }
    }
}
