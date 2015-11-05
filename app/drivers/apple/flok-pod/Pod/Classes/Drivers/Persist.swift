@objc class FlokPersistModule : FlokModule {
    override var exports: [String] {
        return ["if_per_set:", "if_per_del:", "if_per_del_ns:", "if_per_get:"]
    }
    
    func if_per_set(args: [AnyObject]) {
        let ns = args[0] as! String
        let key = args[1] as! String
        let value = args[2] as! String
        
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: nsk(ns, key))
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func if_per_del(args: [AnyObject]) {
        let ns = args[0] as! String
        let key = args[1] as! String
        NSUserDefaults.standardUserDefaults().removeObjectForKey(nsk(ns, key))
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func if_per_del_ns(args: [AnyObject]) {
        let ns = args[0] as! String
        
        let keys = NSUserDefaults.standardUserDefaults().dictionaryRepresentation().keys
        for e in keys {
            if e.rangeOfString(nsk(ns, nil)) != nil {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(e)
            }
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func if_per_get(args: [AnyObject]) {
        let s = args[0] as! String
        let ns = args[1] as! String
        let key = args[2] as! String
        
       let res =  NSUserDefaults.standardUserDefaults().objectForKey(nsk(ns, key)) ?? NSNull()
       engine.int_dispatch([4, "int_per_get_res", s, ns, key, res])
    }
}

//Creates a 'namespaced' key for a namespace+non-namespaced key pair
private func nsk(namespace: String, _ key: String?) -> String {
    return "\(namespace)://____\(key ?? "")"
}