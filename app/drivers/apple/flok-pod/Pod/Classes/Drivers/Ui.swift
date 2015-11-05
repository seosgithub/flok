@objc class FlokUiModule : FlokModule {
    override var exports: [String] {
        return ["if_ui_spec_init:", "if_init_view:", "if_attach_view:", "if_ui_spec_views_at_spot:", "if_ui_spec_view_exists:", "if_free_view:", "if_ui_spec_view_is_visible:"]
    }
    
    func if_ui_spec_init(args: [AnyObject]) {
        NSLog("spec init")
    }
    
    //Both spots and views
    static var uiTpToSelector: [Int: UIView] = [:]
    
    func if_init_view(args: [AnyObject]) {
        //NSException(name: "fail", reason: "if_ui_spec_init-afil-spec_views_at_spot222", userInfo: nil).raise()
        let name = args[0] as! String
        let context = args[1] as! [String:AnyObject]
        let tpBase = args[2] as! Int
        let tpTargets = args[3] as! [String]
        
        //Get the prototype that mateches
        let proto = FlokViewConceierge.viewWithName(name)
        if proto == nil {
            NSException(name: "unhandled view", reason: "unhanded view named \(name)", userInfo: nil).raise()
        }

        let view = proto!.init(frame: CGRectMake(0, 0, 400, 400))
        view.bp = tpBase
        view.engine = self.engine

        //Put the base view inside
        var tpIdx = tpBase  //Start with the base pointer
        for target in tpTargets {
            if target == "main" {
                self.dynamicType.uiTpToSelector[tpIdx] = view
            } else {
                let spot = view.spotWithName(target)
                spot.bp = tpIdx
                self.dynamicType.uiTpToSelector[tpIdx] = spot
            }

            tpIdx += 1
        }
    }
    
    func if_attach_view(args: [AnyObject]) {
        //NSException(name: "fail", reason: "if_attach-afil-spec_views_at_spot", userInfo: nil).raise()
        let vp = args[0] as! Int
        let p = args[1] as! Int

        //Root node
        var target: UIView?
        if p == 0 {
          target = engine.rootView
        } else {
          //Lookup view
          target = self.dynamicType.uiTpToSelector[p]
        }
        
        if target == nil {
            NSException(name: "FlokUIModule", reason: "Tried to if_attach_view with \(args), but the target couldn't be located", userInfo: nil).raise()
            return
        }

        let view = self.dynamicType.uiTpToSelector[vp]
        if let view = view as? FlokView {
            if let spot = target as? FlokSpot {
                spot.views.append(view as! FlokView)
            }
            
            view.parentView = target
            target!.addSubview(view)
        } else {
            NSException(name: "FlokUIModule", reason: "Tried to if_attach_view with \(args), but the view couldn't be located or was not a FlokView", userInfo: nil).raise()
        }
    }
    
    func if_ui_spec_views_at_spot(args: [AnyObject]) {
        let vp = args[0] as! Int
        NSLog("Spec / %d", vp)
        //NSException(name: "fail", reason: "if_ui-spec_views_at_spot", userInfo: nil).raise()
        
        //Root node
        if vp == 0 {
            var subVps: [Int] = []
            for e in engine.rootView.subviews {
               if let fv = e as? FlokView {
                   subVps.append(fv.bp)
               }
            }
            
            engine.intDispatch("spec", args: subVps)
        } else {
            let spot = self.dynamicType.uiTpToSelector[vp] as! FlokSpot
            let viewPointersInSpot = spot.views.map{$0.bp}
            engine.intDispatch("spec", args: viewPointersInSpot)
        }
    }

    func if_ui_spec_view_exists(args: [AnyObject]) {
      let p = args[0] as! Int
      var res = (self.dynamicType.uiTpToSelector[p] != nil)
      self.engine.int_dispatch([1, "spec", res])
    }

    func if_free_view(args: [AnyObject]) {
      let vp = args[0] as! Int

      let view = self.dynamicType.uiTpToSelector[vp]
      if view == nil { NSException(name: "FlokUIModule", reason: "Tried to free view with pointer \(args) but it didn't exist in uiTpToSelector", userInfo: nil).raise() }
      if let view = view as? FlokView {
        //Find all child views and spots
        var found = [view.bp]
        var unexploredViews = [view]
        while unexploredViews.count > 0 {
          let unexploredView = unexploredViews.removeLast()
          found.append(unexploredView.bp)
          for s in unexploredView.spots {
            found.append(s.bp)
            unexploredViews.appendContentsOf(s.views)
          }
        }

        //Pointers for both spots and views
        for p in found {
          self.dynamicType.uiTpToSelector.removeValueForKey(p)
        }

        if let parentSpot = view.parentView as? FlokSpot {
          let index = parentSpot.views.indexOf(view)
          if let index = index {
            parentSpot.views.removeAtIndex(index)
          } else {
            NSException(name: "FlokUIModule", reason: "The parent spot didn't contain our base pointer when tyring to remove view", userInfo: nil).raise()
          }
        }
        view.removeFromSuperview()

      } else {
        NSException(name: "FlokUIModule", reason: "Tried to free view with pointer \(args) but it wasn't a FlokView: \(view)", userInfo: nil).raise()
      }
    }

    func if_ui_spec_view_is_visible(args: [AnyObject]) {
      let p = args[0] as! Int

      let view = self.dynamicType.uiTpToSelector[p]

      if let view = view as UIView! {
        let isVisible = view.isDescendantOfView(engine.rootView)
        engine.int_dispatch([1, "spec", isVisible])
      } else {
        NSException(name: "FlokUIModule", reason: "Tried to check if view with pointer \(p) was visible, but that pointer was not in the selectors table or it wasn't a UIView", userInfo: nil).raise()
        return
      }
    }
}


