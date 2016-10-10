//
//  StartViewController.swift
//  K-Map App
//
//  Created by Kevan Nguyen on 7/8/15.
//  Copyright (c) 2015 Kevan Nguyen. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination: KmapViewController = segue.destinationViewController as! KmapViewController
        let optionalNum = Int((sender?.currentTitle!!)!)
        if let num = optionalNum {
            destination.numVariables = num
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
