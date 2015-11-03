import UIKit
import SnapKit

public class FlokView: UIView, Preloadable
{
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    public var context: [String:AnyObject]!
    public var spots: [FlokSpot] = []

    //Either root or a spot
    public weak var parentView: UIView!

    //Returns a auto-created spot if there is no spot
    func spotWithName(name: String) -> FlokSpot {
        for e in spots {
            if e.name == name { return e }
        }

        NSLog("Warning: spot named \(name) was auto-created")
        let autoSpot = FlokSpot()
        autoSpot.name = name
        spots.append(autoSpot)
        self.addSubview(autoSpot)
        autoSpot.snp_makeConstraints { make in
            make.size.equalTo(self.snp_size).multipliedBy(0.5)
            make.center.equalTo(self.snp_center).multipliedBy(0.5)
            return
        }
        autoSpot.backgroundColor = UIColor.redColor()
        return autoSpot
    }
    public var bp: Int!
    
    //Constructors
    //-----------------------------------------------------------------------------------------------------
    required public override init(frame: CGRect) {
        super.init(frame: frame)
        defaultInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)!
        defaultInit()
    }
    
    public convenience init() {
        self.init(frame: CGRectZero)
    }
    
    public func defaultInit() {
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override public func updateConstraints() {
        super.updateConstraints()
    }
    
    public class func preload() {
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Drawing helpers
    //-----------------------------------------------------------------------------------------------------
}
