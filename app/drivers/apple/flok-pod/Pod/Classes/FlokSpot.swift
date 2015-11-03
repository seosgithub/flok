import UIKit

//Spots go inside views
public class FlokSpot: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    var bp: Int!
    var name: String!
    
    var views: [FlokView] = []
    
    //Constructors
    //-----------------------------------------------------------------------------------------------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)!
        defaultInit()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    func defaultInit() {
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    public override func updateConstraints() {
        super.updateConstraints()
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Drawing helpers
    //-----------------------------------------------------------------------------------------------------
}
