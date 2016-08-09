//
//  ViewController.swift
//  KMediaPlayer
//
//  Created by kouyongzan on 16/8/5.
//  Copyright © 2016年 kouyongzan. All rights reserved.
//

import UIKit


class VideoViewController: UIViewController {

    var movieView: UIView!
    var mediaPlayer = VLCMediaPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

