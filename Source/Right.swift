//
//  Right.swift
//  PullToRefreshKit
//
//  Created by huangwenchen on 16/7/12.
//  Copyright © 2016年 Leo. All rights reserved.
//
import Foundation
import UIKit

class DefaultRefreshRight:UIView,RefreshableLeftRight{
    let imageView:UIImageView = UIImageView().SetUp {
        $0.image = UIImage(named: "arrow_left")
    }
    let textLabel:UILabel  = UILabel().SetUp {
        $0.font = UIFont.systemFontOfSize(14)
        $0.text = "滑动浏览更多"
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(textLabel)
        textLabel.frame = CGRectMake(30,0,20,frame.size.height)
        textLabel.autoresizingMask = .FlexibleHeight
        textLabel.numberOfLines = 0
        imageView.frame = CGRectMake(0, 0,20, 20)
        imageView.center = CGPointMake(10,frame.size.height/2)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - RefreshableLeftRight Protocol  -
    func distanceToRefresh() -> CGFloat {
        return defaultLeftWidth
    }
    func percentageChangedDuringDragging(percent:CGFloat){
        if percent > 1.0{
            guard CGAffineTransformEqualToTransform(self.imageView.transform, CGAffineTransformIdentity)  else{
                return
            }
            UIView.animateWithDuration(0.4, animations: {
                self.imageView.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI+0.000001))
            })
            textLabel.text = "松开浏览更多"
        }
        if percent <= 1.0{
            guard CGAffineTransformEqualToTransform(self.imageView.transform, CGAffineTransformMakeRotation(CGFloat(-M_PI+0.000001)))  else{
                return
            }
            textLabel.text = "滑动浏览更多"
            UIView.animateWithDuration(0.4, animations: {
                self.imageView.transform = CGAffineTransformIdentity
            })
        }
    }
    func didEndRefreshing() {
        imageView.transform = CGAffineTransformIdentity
        textLabel.text = "滑动浏览更多"
    }
    func didBeginRefreshing() {
        
    }
}

class RefreshRightContainer:UIView{
    // MARK: - Propertys -
    enum RefreshHeaderState {
        case Idle
        case Pulling
        case Refreshing
        case WillRefresh
    }
    var refreshAction:(()->())?
    var attachedScrollView:UIScrollView!
    weak var delegate:RefreshableLeftRight?
    private var _state:RefreshHeaderState = .Idle
    var state:RefreshHeaderState{
        get{
            return _state
        }
        set{
            guard newValue != _state else{
                return
            }
            _state =  newValue
            switch newValue {
            case .Refreshing:
                dispatch_async(dispatch_get_main_queue(), {
                    self.delegate?.didBeginRefreshing()
                    self.refreshAction?()
                    self.endRefreshing()
                    self.delegate?.didEndRefreshing()
                })
            default:
                break
            }
        }
    }
    // MARK: - Init -
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    func commonInit(){
        self.userInteractionEnabled = true
        self.backgroundColor = UIColor.clearColor()
        self.autoresizingMask = .FlexibleWidth
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Life circle -
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        if self.state == .WillRefresh {
            self.state = .Refreshing
        }
    }
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        guard newSuperview is UIScrollView else{
            return;
        }
        attachedScrollView = newSuperview as? UIScrollView
        addObservers()
        self.frame = CGRectMake(attachedScrollView.contentSize.width,0,CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))
    }
    deinit{
        removeObservers()
    }
    // MARK: - Private -
    private func addObservers(){
        attachedScrollView?.addObserver(self, forKeyPath:KPathOffSet, options: [.Old,.New], context: nil)
        attachedScrollView?.addObserver(self, forKeyPath:KPathContentSize, options:[.Old,.New] , context: nil)
    }
    private func removeObservers(){
        attachedScrollView?.removeObserver(self, forKeyPath: KPathOffSet,context: nil)
        attachedScrollView?.removeObserver(self, forKeyPath: KPathOffSet,context: nil)
    }

    func handleScrollOffSetChange(change: [String : AnyObject]?){
        if state == .Refreshing {
            return;
        }
        let offSetX = attachedScrollView.contentOffset.x
        let contentWidth = attachedScrollView.contentSize.width
        let contentInset = attachedScrollView.contentInset
        let scrollViewWidth = CGRectGetWidth(attachedScrollView.bounds)
        if attachedScrollView.dragging {
            let percent = (offSetX + scrollViewWidth - contentInset.left - contentWidth)/CGRectGetWidth(self.frame)
            self.delegate?.percentageChangedDuringDragging(percent)
            if state == .Idle && percent > 1.0 {
                self.state = .Pulling
            }else if state == .Pulling && percent <= 1.0{
                state = .Idle
            }
        }else if state == .Pulling{
            beginRefreshing()
        }
    }
    func handleContentSizeChange(change: [String : AnyObject]?){
        self.frame = CGRectMake(self.attachedScrollView.contentSize.width,0,self.frame.size.width,self.frame.size.height)
    }
    
    // MARK: - KVO -
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard self.userInteractionEnabled else{
            return;
        }
        if keyPath == KPathOffSet {
            handleScrollOffSetChange(change)
        }
        guard !self.hidden else{
            return;
        }
        if keyPath == KPathContentSize {
            handleContentSizeChange(change)
        }
    }
    // MARK: - API -
    func beginRefreshing(){
        if self.window != nil {
            self.state = .Refreshing
        }else{
            if state != .Refreshing{
                self.state = .WillRefresh
            }
        }
    }
    func endRefreshing(){
        self.state = .Idle
    }
    
    
}