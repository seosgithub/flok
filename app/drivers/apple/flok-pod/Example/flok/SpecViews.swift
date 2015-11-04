import UIKit
import flok

@objc class SpecBlank: FlokView {
    
    override func didSwitchFromAction(from: String?, toAction to: String?) {
        let to = to ?? NSNull()
        let from = from ?? NSNull()
        
        send("action_rcv", withInfo: [
            "from": from,
            "to": to
        ])
    }
    
    override func didReceiveEvent(name: String, info: [String : AnyObject]) {
        send("custom_rcv", withInfo: [
            "name": name,
            "info": info
        ])
    }
}

class SpecOneSpot: FlokView {
}

class SpecTwoSpot: FlokView {
}