import Socket_IO_Client_Swift
import Foundation

@objc class FlokSockioModule : FlokModule {
    override var exports: [String] {
        return ["if_sockio_init:", "if_sockio_fwd:", "if_sockio_send:"]
    }
    
    //Stores all the initialized sockets
    static var spToSockio: [Int:SocketIOClient] = [:]

    static var spToSockioOperationQueue: [Int:NSOperationQueue] = [:]

    func if_sockio_init(args: [AnyObject]) {
        let url = args[0] as! String
        let sp = args[1] as! Int

        //Create a new socket
        let socket = SocketIOClient(socketURL: url)
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        self.dynamicType.spToSockio[sp] = socket
        self.dynamicType.spToSockioOperationQueue[sp] = queue
        socket.connect()
        
        let semaphore = dispatch_semaphore_create(0)
        queue.addOperationWithBlock() {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
        socket.on("connect") { data, ack in
            dispatch_semaphore_signal(semaphore)
        }
    }

    func if_sockio_fwd(args: [AnyObject]) {
        let sp = args[0] as! Int
        let eventName = args[1] as! String
        let bp = args[2] as! Int

        //Grab socket
        let socket = self.dynamicType.spToSockio[sp];

        if let socket = socket {
          //Forward events
          socket.on(eventName) { info, ack in
            self.engine.int_dispatch([3, "int_event", bp, eventName, info[0]])
          }
        } else {
          NSLog("FlokSockioModule Warning: Couldnt fwd sockio with sp: \(sp) (It does not exist)");
        }
    }

    func if_sockio_send(args: [AnyObject]) {
        let sp = args[0] as! Int
        let eventName = args[1] as! String
        let info = args[2] as! [String:AnyObject]
        
        //Grab the priority queue
        let queue = self.dynamicType.spToSockioOperationQueue[sp];
        let op = NSBlockOperation() {
            //Grab socket
            let socket = self.dynamicType.spToSockio[sp];
            
            if let socket = socket {
                socket.emit(eventName, info)
            } else {
                NSLog("FlokSockioModule Warning: Couldnt send sockio with sp: \(sp) (It does not exist)");
            }
        }
        
        if let queue = queue {
            queue.addOperation(op)
        } else {
            NSLog("FlokSockioModule Warning: Couldnt send sockio with sp: \(sp) (The priority queue does not exist)");
        }
    }
}

