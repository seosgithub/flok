import UIKit
import SnapKit

public class FlokView: UIView, Preloadable
{
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    public var spots: [FlokSpot] = []

    //Either root or a spot
    public weak var parentView: UIView!
    
    weak var engine: FlokEngine!

    //Returns a auto-created spot if there is no spot
    func spotWithName(name: String) -> FlokSpot {
        for e in spots {
            if e.name == name { return e }
        }

        NSLog("Warning: spot named \(name) was auto-created")
        let autoSpot = FlokSpot()
        autoSpot.name = name
        self.addSubview(autoSpot)
        autoSpot.snp_makeConstraints { make in
            make.size.equalTo(self.snp_size).multipliedBy(0.2)
            make.center.equalTo(self.snp_center).multipliedBy(0.2)
            
            if self.spots.count > 0 {
                make.left.equalTo(self.spots.last!.snp_right)
            }
            return
        }
        spots.append(autoSpot)
        autoSpot.backgroundColor = UIColor.redColor()
        
        let label = UILabel()
        label.text = name
        autoSpot.addSubview(label)
        label.snp_makeConstraints { make in
            make.center.equalTo(autoSpot.snp_center)
            make.size.equalTo(autoSpot.snp_size)
            return
        }
        return autoSpot
    }
    public var bp: Int!  //View base-pointer
    
    //'controller' portion of the view, which is really just event handling & context loading code
    public var cbp: Int?                     //Controller base-pointer
    public var context: [String:AnyObject]! //Initialization context
    
    //Constructors
    //-----------------------------------------------------------------------------------------------------
    required public override init(frame: CGRect) {
        super.init(frame: frame)
//        defaultInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)!
//        defaultInit()
    }
    
    public convenience init() {
        self.init(frame: CGRectZero)
    }
    
    public func didLoad() {
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override public func updateConstraints() {
        super.updateConstraints()
    }
    
    public class func preload() {
    }
    
    public func didSwitchFromAction(from: String?, toAction to: String?) {
        
    }
    
    public func didReceiveEvent(name: String, info: [String:AnyObject]) {
        
    }
    
    public func emit(name: String, withInfo info: [String:AnyObject]) {
        engine.int_dispatch([3, "int_event", cbp!, name, info])
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Drawing helpers
    //-----------------------------------------------------------------------------------------------------
}
