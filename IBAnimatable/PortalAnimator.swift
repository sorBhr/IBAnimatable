//
//  Created by Tom Baranes on 17/04/16.
//  Copyright © 2016 Jake Lin. All rights reserved.
//

import UIKit

public class PortalAnimator: NSObject, AnimatedTransitioning {

  // MARK: - AnimatorProtocol
  public var transitionAnimationType: TransitionAnimationType
  public var transitionDuration: Duration = defaultTransitionDuration
  public var reverseAnimationType: TransitionAnimationType?
  public var interactiveGestureType: InteractiveGestureType?
  
  // MARK: - private
  private var fromDirection: TransitionFromDirection
  private var zoomScale: CGFloat = 0.8
  
  init(fromDirection: TransitionFromDirection, params: [String], transitionDuration: Duration) {
    self.transitionDuration = transitionDuration
    self.fromDirection = fromDirection
    
    if let firstParam = params.first,
           unwrappedZoomScale = Double(firstParam) {
      zoomScale = CGFloat(unwrappedZoomScale)
    }
    
    switch fromDirection {
    case .Backward:
      self.transitionAnimationType = .Portal(direction: .Backward, params: params)
      self.reverseAnimationType = .Portal(direction: .Forward, params: params)
    default:
      self.transitionAnimationType = .Portal(direction: .Forward, params: params)
      self.reverseAnimationType = .Portal(direction: .Backward, params: params)
    }

    super.init()
  }
}

extension PortalAnimator: UIViewControllerAnimatedTransitioning {
  public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return retrieveTransitionDuration(transitionContext)
  }
  
  public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    let (tempfromView, tempToView, tempContainerView) = retrieveViews(transitionContext)
    guard let fromView = tempfromView, toView = tempToView, containerView = tempContainerView else {
      transitionContext.completeTransition(true)
      return
    }
    
    if fromDirection == .Forward {
      executeForwardAnimation(transitionContext, containerView: containerView, fromView: fromView, toView: toView)
    } else {
      executeBackwardAnimations(transitionContext, containerView: containerView, fromView: fromView, toView: toView)
    }
  }
  
}

// MARK: - Forward

private extension PortalAnimator {

  func executeForwardAnimation(transitionContext: UIViewControllerContextTransitioning, containerView containerView: UIView, fromView: UIView, toView: UIView) {
    let toViewSnapshot = toView.resizableSnapshotViewFromRect(toView.frame, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
    let scale = CATransform3DIdentity
    toViewSnapshot.layer.transform = CATransform3DScale(scale, zoomScale, zoomScale, 1)
    containerView.insertSubview(toViewSnapshot, atIndex: 0)

    let leftSnapshotRegion = CGRect(x: 0, y: 0, width: fromView.frame.width / 2, height: fromView.bounds.height)
    let leftHandView = fromView.resizableSnapshotViewFromRect(leftSnapshotRegion, afterScreenUpdates: false, withCapInsets: UIEdgeInsetsZero)
    leftHandView.frame = leftSnapshotRegion
    containerView.addSubview(leftHandView)

    let rightSnapshotRegion = CGRect(x: fromView.frame.width / 2, y: 0, width: fromView.frame.width / 2, height: fromView.frame.height)
    let rightHandView = fromView.resizableSnapshotViewFromRect(rightSnapshotRegion, afterScreenUpdates: false, withCapInsets: UIEdgeInsetsZero)
    rightHandView.frame = rightSnapshotRegion
    containerView.addSubview(rightHandView)
    
    fromView.removeFromSuperview()

    UIView.animateWithDuration(transitionDuration, delay: 0.0, options: .CurveEaseOut, animations: {
      leftHandView.frame = CGRectOffset(leftHandView.frame, -leftHandView.frame.width, 0.0)
      rightHandView.frame = CGRectOffset(rightHandView.frame, rightHandView.frame.width, 0.0)
      toViewSnapshot.center = toView.center
      toViewSnapshot.frame = containerView.frame
    }, completion: { _ in
      if transitionContext.transitionWasCancelled() {
        containerView.addSubview(fromView)
        self.removeOtherViews(fromView)
      } else {
        toView.frame = containerView.frame
        containerView.addSubview(toView)
        self.removeOtherViews(toView)
      }
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
    })
  }
  
}

// MARK: - Reverse

private extension PortalAnimator {
  
  func executeBackwardAnimations(transitionContext: UIViewControllerContextTransitioning, containerView containerView: UIView, fromView: UIView, toView: UIView) {
    containerView.addSubview(fromView)
    toView.frame = CGRectOffset(toView.frame, toView.frame.width, 0);
    containerView.addSubview(toView)

    let leftSnapshotRegion = CGRect(x: 0, y: 0, width: toView.frame.width / 2, height: toView.bounds.height)
    let leftHandView = toView.resizableSnapshotViewFromRect(leftSnapshotRegion, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
    leftHandView.frame = leftSnapshotRegion
    leftHandView.frame = CGRectOffset(leftHandView.frame, -leftHandView.frame.width, 0);
    containerView.addSubview(leftHandView)

    let rightSnapshotRegion = CGRect(x: toView.frame.width / 2, y: 0, width: toView.frame.width / 2, height: fromView.frame.height)
    let rightHandView = toView.resizableSnapshotViewFromRect(rightSnapshotRegion, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
    rightHandView.frame = rightSnapshotRegion
    rightHandView.frame = CGRectOffset(rightHandView.frame, rightHandView.frame.width, 0)
    containerView.addSubview(rightHandView)

    UIView.animateWithDuration(transitionDuration, delay: 0.0, options: .CurveEaseOut, animations: {
      leftHandView.frame = CGRectOffset(leftHandView.frame, leftHandView.frame.size.width, 0)
      rightHandView.frame = CGRectOffset(rightHandView.frame, -rightHandView.frame.size.width, 0)
      let scale = CATransform3DIdentity
      fromView.layer.transform = CATransform3DScale(scale, self.zoomScale, self.zoomScale, 1);
    }, completion: { _ in
        if transitionContext.transitionWasCancelled() {
          self.removeOtherViews(fromView)
        } else {
          self.removeOtherViews(toView)
          toView.frame = containerView.bounds
          fromView.layer.transform = CATransform3DIdentity
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
    })
  }
  
}

// MARK: - Helper

private extension PortalAnimator {
  
  func removeOtherViews(viewToKeep: UIView) {
    guard let containerView = viewToKeep.superview else {
      return
    }
    
    containerView.subviews.forEach {
      if $0 != viewToKeep {
        $0.removeFromSuperview()
      }
    }
  }
  
}