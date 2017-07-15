//
//  CustomTabBarController.swift
//  CustomTabBarController
//
//  Created by Brian Endo on 7/14/17.
//  Copyright © 2017 Brian Endo. All rights reserved.
//

import Foundation
import UIKit

protocol CustomScrollable: class {
    func scrollViewScrolled(scrollView: UIScrollView)
}

class ScrollableViewController: UIViewController, UIScrollViewDelegate {
    var inset: CGFloat = 0
    var offset: CGFloat = 0
    weak var delegate: CustomScrollable?
}

class CustomTabBarController: UITabBarController, CustomScrollable, UITabBarControllerDelegate {
    
    var headerView = UIView()
    let inset: CGFloat = 100
    lazy var panTransition = PanTransition()
    lazy var interactionController = HorizontalSwipeInteractionController()
    var lastOffset: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let firstVC = storyBoard.instantiateViewController(withIdentifier: "firstVC")
        let secondVC = storyBoard.instantiateViewController(withIdentifier: "secondVC")
        let viewControllers = [firstVC, secondVC]
        
        headerView = UIView(frame: CGRect(x: 0, y: 20, width: view.frame.width, height: inset))
        headerView.backgroundColor = .red
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(switchViewController))
        headerView.addGestureRecognizer(gestureRecognizer)
        view.addSubview(headerView)
        
        setViewControllers(viewControllers, animated: true, inset: inset)
        
        tabBar.isHidden = true
        delegate = self
    }
    
    func switchViewController() {
        var index = selectedIndex
        
        if index == 0 {
            index = 1
        } else {
            index = 0
        }
        
        selectedIndex = index
    }
    
    func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool, inset: CGFloat) {
        for viewController in viewControllers! {
            if let vc = viewController as? ScrollableViewController {
                vc.inset = inset
                vc.delegate = self
            }
            interactionController.wireToViewController(viewController)
        }
        setViewControllers(viewControllers, animated: animated)
    }
    
    func scrollViewScrolled(scrollView: UIScrollView) {
        var offset = scrollView.contentOffset.y
        
        if offset <= 0 {
            offset = inset - abs(offset)
        } else {
            offset += inset
        }
        
        lastOffset = offset
        
        print("Content offset \(offset)")
        headerView.frame = CGRect(x: 0, y: 20 - offset, width: view.frame.width, height: inset)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let fromIndex = viewControllers?.index(of: fromVC)
        let toIndex = viewControllers?.index(of: toVC)
        
        if let fromIndex = fromIndex, let toIndex = toIndex {
            panTransition.isForward = toIndex > fromIndex
        }
        
        return panTransition
    }
    
    func tabBarController(_ tabBarController: UITabBarController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
    
    
}

class PanTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var isForward = true
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromView: UIView = transitionContext.view(forKey: .from)!
        let toView: UIView = transitionContext.view(forKey: .to)!
        
        transitionContext.containerView.addSubview(fromView)
        transitionContext.containerView.addSubview(toView)
        
        var fromNewFrame = CGRect.zero
        
        if isForward {
            toView.frame = CGRect(x: toView.frame.width, y: 0, width: toView.frame.width, height: toView.frame.height)
            fromNewFrame = CGRect(x: -1 * fromView.frame.width, y: 0, width: fromView.frame.width, height: fromView.frame.height)
        } else {
            toView.frame = CGRect(x: -toView.frame.width, y: 0, width: toView.frame.width, height: toView.frame.height)
            fromNewFrame = CGRect(x: fromView.frame.width, y: 0, width: fromView.frame.width, height: fromView.frame.height)
        }
        
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, animations: {
            toView.frame = fromView.frame
            fromView.frame = fromNewFrame
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.7
    }
    
}

class HorizontalSwipeInteractionController: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    
    func wireToViewController(_ viewController: UIViewController) {
        self.viewController = viewController
        prepareGestureRecognizerInView(viewController.view)
    }
    
    private func prepareGestureRecognizerInView(_ view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_ :)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: gesture.view?.superview)
        let velocity = gesture.velocity(in: gesture.view)
        
        let rightToLeftSwipe = velocity.x < 0
        
        var progress = abs(translation.x / viewController.view.frame.width)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        
        switch (gesture.state) {
        case .began:
            interactionInProgress = true
            viewController.tabBarController?.selectedIndex += rightToLeftSwipe ? 1 : -1
        case .changed:
            shouldCompleteTransition = progress > 0.5
            print("Direction rightToLeft \(rightToLeftSwipe)")
            print("Progress \(progress)")
            update(progress)
        case .cancelled:
            interactionInProgress = false
            cancel()
        case .ended:
            interactionInProgress = false
            if shouldCompleteTransition {
                finish()
            } else {
                cancel()
            }
        default:
            print("Unhandled state")
        }
    }
}
