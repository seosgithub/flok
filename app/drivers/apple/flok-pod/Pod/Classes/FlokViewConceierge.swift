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
//    public var registeredViews: [String:AnyClass?] = [:]
    
    //Views that have already been preloaded
    var hasPreloaded: [String:Bool] = [:]
    
    //All changes must be synchronized on the main-thread
    var isPreloading: [String:Bool] = [:]
    
    var preloadOperationInProgress: [String:NSOperation] = [:]
    
    //Retrieves a view (class) for a specified name
    public func viewWithName(name: String) -> FlokView.Type? {
        let klass = NSClassFromString(name.snakeToClassCase) as? FlokView.Type
        if let klass = klass {
            return klass
        } else {
            NSLog("FittrConceierge: Warning, couldn't find flok-view named \(name)")
            return FlokView.self
        }
        
    }
}

//Default singleton
public var FlokViewConceierge = _FlokViewConceierge()
