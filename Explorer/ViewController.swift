//
//  ViewController.swift
//  Explorer
//
//  Created by Jack Cook on 1/17/15.
//  Copyright (c) 2015 Jack Cook. All rights reserved.
//

import CoreMotion
import CoreLocation
import UIKit

class ViewController: UIViewController {

    let motionManager = CMMotionManager()
    
    @IBOutlet var leftPanorama: UIView!
    @IBOutlet var rightPanorama: UIView!
    
    var left: GMSPanoramaView!
    var right: GMSPanoramaView!
    
    var viewsWereLaidOut = false
    
    var h: Double = 0
    var heading: CLHeading!
    var location: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: { (motion, error) -> Void in
            let heading = 180 + (-motion.attitude.yaw * 57.295)
            let pitch = motion.gravity.z * 90
            self.h = heading
            
            let camera = GMSPanoramaCamera(orientation: GMSOrientation(heading: heading, pitch: pitch), zoom: self.left.camera.zoom, FOV: self.left.camera.FOV)
            self.left.animateToCamera(camera, animationDuration: 0.01)
            self.right.animateToCamera(camera, animationDuration: 0.01)
        })
        
        location = CLLocation(latitude: 42.29217747796312, longitude: -83.71481317402007)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIDeviceOrientationDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "myoConnected", name: TLMHubDidConnectDeviceNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceivePoseChange:", name: TLMMyoDidReceivePoseChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSyncArm:", name: TLMMyoDidReceiveArmSyncEventNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        
        if TLMHub.sharedHub().myoDevices().count == 0 {
            let settings = TLMSettingsViewController()
            self.presentViewController(settings, animated: true, completion: nil)
            TLMHub.sharedHub().attachToAdjacent()
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !viewsWereLaidOut {
            viewsWereLaidOut = true
            left = GMSPanoramaView(frame: leftPanorama.bounds)
            left.moveNearCoordinate(CLLocationCoordinate2DMake(42.29217747796312, -83.71481317402007))
            left.orientationGestures = false
            left.subviews[1].removeFromSuperview()
            left.subviews[1].removeFromSuperview()
            
            //let timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "move", userInfo: nil, repeats: true)
            //NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            
            right = GMSPanoramaView(frame: rightPanorama.bounds)
            right.moveNearCoordinate(CLLocationCoordinate2DMake(42.29217747796312, -83.71481317402007))
            right.orientationGestures = false
            right.subviews[1].removeFromSuperview()
            right.subviews[1].removeFromSuperview()
            
            leftPanorama.addSubview(left)
            rightPanorama.addSubview(right)
        }
    }
    
    func orientationChanged(notification: NSNotification) {
        if let l = left {
            left.frame = leftPanorama.bounds
            right.frame = rightPanorama.bounds
        }
    }
    
    func move(forwards: Bool) {
        location = CLLocation(latitude: left.panorama.coordinate.latitude, longitude: left.panorama.coordinate.longitude)
        
        let theta = -h
        let distance: Double = (forwards ? 1 : -1) * 0.0001
        let x1: Double = location.coordinate.latitude
        let y1: Double = location.coordinate.longitude
        
        let x2 = x1 + (distance * cos(theta))
        let y2 = y1 + (distance * sin(theta))
        
        let coordinate = CLLocationCoordinate2DMake(x2, y2)
        location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        left.moveNearCoordinate(coordinate)
        right.moveNearCoordinate(coordinate)
    }
    
    func myoConnected() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func didSyncArm(notification: NSNotification) {
        let armEvent = (notification.userInfo as Dictionary<String, AnyObject>)[kTLMKeyArmSyncEvent] as TLMArmSyncEvent
        println("connected")
    }
    
    func didReceivePoseChange(notification: NSNotification) {
        let pose = (notification.userInfo as Dictionary<String, AnyObject>)[kTLMKeyPose] as TLMPose
        
        switch pose.type {
        case .Rest:
            println("rest")
        case .Fist:
            move(true)
        case .WaveIn:
            println("wavein")
        case .WaveOut:
            println("waveout")
        case .FingersSpread:
            move(false)
        case .DoubleTap:
            println("doubletap")
        default:
            println("unknown")
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
