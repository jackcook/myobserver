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
    
    let startLat = 40.7577
    let startLon = -73.9857
    
    var h: Double = 0
    var heading: CLHeading!
    var location: CLLocation!
    
    var currentPose = TLMPoseType.Unknown
    
    var basesSet = false
    var baseY: Float = 5
    var baseZ: Float = 5
    
    var canForwards = true
    var canBackwards = true
    
    var quaternionY: Float = 0
    var quaternionZ: Float = 0
    
    var hud: MBProgressHUD!
    
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
        
        location = CLLocation(latitude: startLat, longitude: startLon)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIDeviceOrientationDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "myoConnected", name: TLMHubDidConnectDeviceNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceivePoseChange:", name: TLMMyoDidReceivePoseChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveOrientationEvent:", name: TLMMyoDidReceiveOrientationEventNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        
        if TLMHub.sharedHub().myoDevices().count == 0 {
            let settings = TLMSettingsViewController()
            self.presentViewController(settings, animated: true, completion: nil)
            TLMHub.sharedHub().attachToAdjacent()
        } else {
            if !basesSet {
                basesSet = true
                
                hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                hud.mode = MBProgressHUDModeIndeterminate
                hud.labelText = "Calibrating..."
                
                let timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "setBase", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !viewsWereLaidOut {
            viewsWereLaidOut = true
            left = GMSPanoramaView(frame: leftPanorama.bounds)
            left.moveNearCoordinate(CLLocationCoordinate2DMake(startLat, startLon))
            left.orientationGestures = false
            left.subviews[1].removeFromSuperview()
            left.subviews[1].removeFromSuperview()
            
            right = GMSPanoramaView(frame: rightPanorama.bounds)
            right.moveNearCoordinate(CLLocationCoordinate2DMake(startLat, startLon))
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
        /*location = CLLocation(latitude: left.panorama.coordinate.latitude, longitude: left.panorama.coordinate.longitude)
        
        let theta = -h
        let distance: Double = (forwards ? 1 : -1) * 0.0001
        let x1: Double = location.coordinate.latitude
        let y1: Double = location.coordinate.longitude
        
        let x2 = x1 + (distance * cos(theta))
        let y2 = y1 + (distance * sin(theta))
        
        let coordinate = CLLocationCoordinate2DMake(x2, y2)
        location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        left.moveNearCoordinate(coordinate)
        right.moveNearCoordinate(coordinate)*/
    }
    
    func myoConnected() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func didReceiveOrientationEvent(notification: NSNotification) {
        let orientationEvent = (notification.userInfo as Dictionary<String, AnyObject>)[kTLMKeyOrientationEvent] as TLMOrientationEvent
        let x: Float = orientationEvent.quaternion.x
        let y: Float = orientationEvent.quaternion.y
        let z: Float = orientationEvent.quaternion.z
        
        quaternionY = y
        quaternionZ = z
        
        if currentPose == .Fist {
            let camera = GMSPanoramaCamera(heading: left.camera.orientation.heading, pitch: left.camera.orientation.pitch, zoom: 3 + ((baseY + (baseY + -y)) * 8))
            left.animateToCamera(camera, animationDuration: 0.05)
            
            if -y <= baseY - 0.3 {
                println("stopped fisting, \(baseY), \(y)")
                currentPose = .Unknown
            }
        }
        
        if !basesSet {
            return
        }
        
        println("\(baseZ), \(z)")
        if z + 0.3 >= baseZ {
            if canForwards {
                move(true)
                canForwards = false
                
                let timer = NSTimer.scheduledTimerWithTimeInterval(1.25, target: self, selector: "allowForwards", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            }
        } else if z - 0.3 <= baseZ {
            if canBackwards {
                move(true)
                canBackwards = false
                
                let timer = NSTimer.scheduledTimerWithTimeInterval(1.25, target: self, selector: "allowBackwards", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            }
        }
    }
    
    func allowForwards() {
        canForwards = true
    }
    
    func allowBackwards() {
        canBackwards = true
    }
    
    func setBase() {
        println("set base values")
        baseY = baseY == 5 ? quaternionY : baseY
        baseZ = baseZ == 5 ? quaternionZ : baseZ
        
        hud.mode = MBProgressHUDModeCustomView
        hud.labelText = "Calibrated!"
        hud.customView = UIImageView(image: UIImage(named: "check.png"))
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "hideHUD", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    func hideHUD() {
        hud.hide(true)
    }
    
    func didReceivePoseChange(notification: NSNotification) {
        println("change")
        let pose = (notification.userInfo as Dictionary<String, AnyObject>)[kTLMKeyPose] as TLMPose
        
        currentPose = pose.type
        
        switch pose.type {
        case .Rest:
            println("rest")
        case .Fist:
            println("fist")
        case .WaveIn:
            println("wavein")
        case .WaveOut:
            println("waveout")
        case .FingersSpread:
            println("fingersspread")
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
