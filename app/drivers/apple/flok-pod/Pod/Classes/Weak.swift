import Foundation

//Stores a weak object
class Weak<T: AnyObject> {
    weak var value: T?
    init(value: T) {
        self.value = value
    }
}

//If the value gets reclaimed, then the entry is removed
class WeakValueDictionary<T: Hashable, Y: AnyObject> {
    //Contains values
    var entries: [T:Weak<Y>] = [:]
    
    //Contains only entries into weak array
    
    
    subscript(index: T) -> Y? {
        get {
            let v = entries[index]
            
            //No entry
            if v == nil { return nil }
            
            //Contained entry
            if let value = v!.value { return value }
            
            //Contained freed entry
            entries.removeValueForKey(index)
            return nil
        }
        
        set {
//            let v = entries[index]
//            if v != nil {
//                NSException(name: "WeakValueDictionary", reason: "Tried to set a key value pair to <\(index), \(newValue)> but the pair <\(index), \(v)> already existed", userInfo: nil).raise()
//            }
            
            entries[index] = Weak<Y>(value: newValue!)
        }
    }
    
    func keys() -> [T] {
        var out: [T] = []
        for (_, e) in entries.enumerate() {
            
            //Ensure the value is still in memory
            //before returning the key
            if e.1.value != nil {
                out.append(e.0)
            }
        }
        
        return out
    }
}