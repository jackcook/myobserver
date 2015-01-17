//
//  ViewController.swift
//  Explorer
//
//  Created by Jack Cook on 1/17/15.
//  Copyright (c) 2015 Jack Cook. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let deviceSize = UIScreen.mainScreen().bounds
        
        let leftPanorama = GMSPanoramaView(frame: CGRectMake(0, 0, deviceSize.width / 2, deviceSize.height))
        leftPanorama.moveNearCoordinate(CLLocationCoordinate2DMake(-33.732, 150.312))
        
        let rightPanorama = GMSPanoramaView(frame: CGRectMake(deviceSize.width / 2, 0, deviceSize.width / 2, deviceSize.height))
        rightPanorama.moveNearCoordinate(CLLocationCoordinate2DMake(-33.732, 150.312))
        
        self.view.addSubview(leftPanorama)
        self.view.addSubview(rightPanorama)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
