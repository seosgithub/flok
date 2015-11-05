import UIKit

public protocol Preloadable {
    static func preload()
}

//A view concierge that ensures that a FlokView is ready to be displayed
//and will not block.  Contains a asynchronous loading queue that can
//prioritize views to prep-load based on demands.  Additionally, you
//register views with the Conceierge to have them available for loading
//by setting the registeredViews hash lookup
public class _FlokViewConceierge {
    //The preload-queue for all registered FlokViews
    var pq = NSOperationQueue()
    
    //Should be updated with the list of available views
    public var registeredViews: [String:AnyClass?] = [:]
    
    //Views that have already been preloaded
    var hasPreloaded: [String:Bool] = [:]
    
    //All changes must be synchronized on the main-thread
    var isPreloading: [String:Bool] = [:]
    
    var preloadOperationInProgress: [String:NSOperation] = [:]
    
    //Retrieves a view (class) for a specified name
    public func viewWithName(name: String) -> FlokView.Type? {
        if (self.registeredViews[name] == nil) {
//            NSException(name: "FlokViewConceierge", reason: "A view named \(name) was requested but that view is not registered", userInfo: nil).raise()
            self.registeredViews[name] = FlokView.self
        }
        
        let proc = {
            //If the view has not been preloaded yet
            if self.hasPreloaded[name] == nil {
                //If the view is being loaded or is not being loaded (atm, 
                //it should be scheduled to at some point)
                if self.isPreloading[name] == true {
                    //Wait till preload is finished, hijack preload completion, else
                    //it will deadlock because it needs the main queue
                    let sem = dispatch_semaphore_create(0)
                    self.preloadOperationInProgress[name]!.completionBlock = {
                        self.isPreloading[name] = false
                        self.hasPreloaded[name] = true
                        dispatch_semaphore_signal(sem)
                    }
                    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
                } else {
                    //Pre-empted load, this happens at start-up for the first views that come in
                    //Don't allow it to preload asynchronously, do it ourselves now on the main thread because
                    //we need it **now** as the UI will stall
                    if self.preloadOperationInProgress[name] != nil { NSException(name: "FlokViewConceierge", reason:"Fatal Error: the preloadOperationInProgress[name] should have contained an operation", userInfo: nil).raise() }
                    self.preloadOperationInProgress.removeValueForKey(name)
                    self.hasPreloaded[name] = true
                    let preloadable = self.registeredViews[name] as! Preloadable.Type
                    preloadable.preload()
                    
                }
                
                if (self.hasPreloaded[name] != true) {
                    NSException(name: "FlokViewConceierge", reason:"Fatal Error: The view named \(name) was in the middle of preloading when we stalled for it, but it wasn't preloaded when it signaled", userInfo:nil).raise()
                }
            }
        }
        
        //Only call this function from the main-thread as we may have race conditions
        //with the pre-loaders
        if !NSThread.isMainThread() {
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                proc()
            })
        } else {
            proc()
        }
        
        //At this point, the view's class is pre-loaded, probably XIBs, etc)
        let view = registeredViews[name] as? FlokView.Type
        return view
    }
    
    //Initiates the asynchronous view pre-loading sequence
    public func preload() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            for e in self.registeredViews {
                let op = NSBlockOperation(block: { () -> Void in
                    //Make sure we should preload, if it is not currently preloading
                    //by way of pre-empted load
                    var shouldPreload = false
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        if (self.isPreloading[e.0] == nil) {
                            self.isPreloading[e.0] = true
                            shouldPreload = true
                        } else {
                            shouldPreload = false
                        }
                    })
                    
                    if shouldPreload {
                        let preloadable = self.registeredViews[e.0]! as! Preloadable.Type
                        preloadable.preload()
                    } else {
                        puts("View named \(e.0) was pre-empted")
                    }
                })
                
                op.completionBlock = {
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        self.isPreloading[e.0] = false
                        self.hasPreloaded[e.0] = true
                    })
                }
                
                dispatch_sync(dispatch_get_main_queue()) {
                    //Race condition with a pre-empted loading
                    if self.hasPreloaded[e.0] != true {
                        self.preloadOperationInProgress[e.0] = op
                        self.pq.addOperation(op)
                    }
                }
            }
        }
    }
}

//Default singleton
public var FlokViewConceierge = _FlokViewConceierge()
