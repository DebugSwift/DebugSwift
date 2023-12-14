### Key words
Transition animation, gesture monitoring, core animation

### Result
![Operation effect](https://github.com/zhouXiaoR/FloatWeChatView/raw/master/浮窗运行效果.gif)

### Introduction
```swift
// [] stores the classes that need to be suspended, vcname refers to the class name
FloatViewManager.manager.addFloatVcsClass(vcs: [vcname])
```
### Mainly used categories and functions
As a whole, it involves the following main categories, and indicate their function points
-`FloatViewManager` singleton, used to manage the floating window information and the view on the window.
-`TransitionPush / TransitionPop` custom navigation transition animation
-`FloatBallView` round buoy on the screen, draggable
-Draw a black or red view at the bottom of `BottomFloatView`

### Ideas
- 1. When the project is first initialized, in order to monitor the gesture movement changes, customize the transition, the gesture proxy is managed by FloatViewManager.
```swift
currentNavtigationController()?.interactivePopGestureRecognizer?.delegate = self
        currentNavtigationController()?.delegate = self
```
- 2. When entering a controller that supports hovering, you need to calculate the movement of the black translucent frame at the bottom according to the offset of the gesture. Here we use the following to do monitoring. Note that safety judgments must be made here.

```swift
func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
// Whether there is a sub-collection in the current navigation controller
        guard let vcs = currentNavtigationController()?.viewControllers else{
            return false
        }
        
// If it is the root controller, no processing
        guard vcs.count> 1 else {
            return false
        }
        
// Determine whether the current controller is consistent with the controller that supports floating in the starting array. Only if they are consistent, perform the next step and turn on monitoring
        if let currentVisiableVC = currentViewController() {
             let currentVCClassName = "\(currentVisiableVC.self)"
             if currentVCClassName.contains(floatVcClass.first!){
                startDisplayLink()
                edgeGesture = (gestureRecognizer as? UIScreenEdgePanGestureRecognizer) ?? nil
                tempCurrentFloatVC = currentVisiableVC
            }
        }
        return true
    }
}
```

- 3. Update the semi-transparent view at the bottom according to the monitoring results. Please refer to the source code for the detailed code here.
- 4. After the gesture is finished, judge whether to hover or not. If the final end gesture is in the black transparent bottom, hover and display the round buoy, otherwise hide it.

```swift
@objc func displayLinkLoop() {
        if edgeGesture?.state == UIGestureRecognizerState.changed{
            guard let startP = edgeGesture?.location(in:kWindow) else {
                return
            }
    
            let orx: CGFloat = max(screenWidth-startP.x, kBvfMinX)
            let ory: CGFloat = max(screenHeight-startP.x, kBvMinY)
            bFloatView.frame = CGRect(x: orx, y: ory, width: kBottomViewFloatWidth, height: kBottomViewFloatHeight)

            // Convert the point to the bottom view and calculate whether it is within the black circle
            guard let transfomBottomP = kWindow?.convert(startP, to: bFloatView) else{
                return
            }
            
         // print(transfomBottomP)
            if transfomBottomP.x> 0 && transfomBottomP.y> 0{
                let arcCenter = CGPoint(x: kBottomViewFloatWidth, y: kBottomViewFloatHeight)
                let distance = pow((transfomBottomP.x-arcCenter.x),2) + pow((transfomBottomP.y-arcCenter.y),2)
                let onArc = pow(arcCenter.x,2)
                if distance <= onArc{
                    if(!bFloatView.insideBottomSeleted){
                        bFloatView.insideBottomSeleted = true
                    }
                }else{
                    if(bFloatView.insideBottomSeleted){
                        bFloatView.insideBottomSeleted = false
                    }
                }
            }else{
                if(bFloatView.insideBottomSeleted){
                    bFloatView.insideBottomSeleted = false
                }
            }
        }else if(edgeGesture?.state == UIGestureRecognizerState.possible){
            
//At the end, judge whether the final finger position, that is, the black transparent view is selected. If selected, save the current controller and pause the timer (must be paused here, otherwise resources will be wasted)
            if(bFloatView.insideBottomSeleted){
                currentFloatVC = tempCurrentFloatVC
                tempCurrentFloatVC = nil
                ballView.show = true
                
                if let newDetailVC = currentFloatVC as? NewDetailController{
                    ballView.backgroundColor = newDetailVC.themeColor
                }
            }
            // hide the black transparent view at the bottom
            UIView.animate(withDuration: animationConst().animationDuration, animations: {
                  self.bFloatView.frame = CGRect(x: screenWidth, y: screenHeight, width: kBottomViewFloatWidth, height:kBottomViewFloatHeight)
            }) {(_) in
                
            }
            stopDisplayLink()
        }
    }
```
- 5. The circular buoy supports dragging, and provides click and drag gesture proxy methods for FloatViewManager to use to update related views, see the source code
- 6. When the user returns to other interfaces, he can open the floating window controller again as long as he can find the top navigation. Here is mainly a custom transition animation push/pop.
- 7. When the user's finger manually cancels the floating window, all the data saved in the singleton will be cleared to ensure that it can be used normally again.

### Source code
[Git source code](https://github.com/zhouXiaoR/FloatWeChatView)

### Brief Book Contact
[Comments and Suggestions](https://www.jianshu.com/p/60494fd3935d)


### Thanks to the author and the following blogs, if you have any questions, please private message to criticize and correct

[Customizing the Transition Animations](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html)

[Transition animation in UINavigationController](https://www.jianshu.com/p/75216054469c)

[iOS floating window](https://mp.weixin.qq.com/s/2jpkQVT9hE6QcADQYcHeKA)
