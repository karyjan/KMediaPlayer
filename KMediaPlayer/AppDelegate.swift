//
//  AppDelegate.swift
//  KMediaPlayer
//
//  Created by kouyongzan on 16/8/5.
//  Copyright © 2016年 kouyongzan. All rights reserved.
//

import UIKit
import FileBrowser

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UINavigationControllerDelegate {

    var window: UIWindow?
    var localFileBrowser = FileBrowser()

    let audioExtensions:[String] = ["mp3","ape","flac","wav","m4a","wma","aac"]
    let videoExtensions:[String] = ["mp4","mov","mtk","avi","m4v","wmv","mpeg"]
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
        
        window = UIWindow()
        window?.bounds = UIScreen.mainScreen().bounds
        
        let fileManager = NSFileManager.defaultManager()
        
        let path = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
        
        NSLog("%@",path.absoluteString)
        localFileBrowser.didSelectFile = onDidSelectedFile
        localFileBrowser.delegate = self
        
        window?.rootViewController = localFileBrowser
        window?.makeKeyAndVisible()
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if (event?.type == UIEventType.RemoteControl) {
            let subtype = event!.subtype
            switch subtype {
            case .RemoteControlTogglePlayPause,.RemoteControlPlay,.RemoteControlPause:
                AudioViewController.sharedInstance.onToggleBtnClicked(nil)
                NSLog("继续播放")
                break
            case .RemoteControlNextTrack:
                AudioViewController.sharedInstance.playNext()
                NSLog("下一曲");
                break
            case .RemoteControlPreviousTrack:
                AudioViewController.sharedInstance.playPre()
                NSLog("上一曲")
                break;
            default:
                break;
            }
        }
    }
    
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        
        if(viewController is AudioViewController || viewController is VideoViewController){
//            navigationController.setNavigationBarHidden(true, animated: false)
        }else{
            
            viewController.navigationItem.rightBarButtonItem = nil;
            
            let indicator:MusicIndicator = MusicIndicator.sharedInstance()
            indicator.hidesWhenStopped = false;
            indicator.tintColor = UIColor.redColor()
            
            if(indicator.state != .Playing){
                indicator.state = .Playing;
                indicator.state = .Stopped;
            }else{
                indicator.state = .Playing;
            }
            
            let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self,action: #selector(AppDelegate.onIndicatorClicked(_:)))
            tapGesture.numberOfTapsRequired = 1
            indicator.addGestureRecognizer(tapGesture)
            
            
            let item:UIBarButtonItem = UIBarButtonItem(customView: indicator);
            item.style = .Plain
            item.target = self
            item.action = #selector(AppDelegate.onIndicatorClicked(_:));
            viewController.navigationItem.rightBarButtonItem = item;

        }
    }
    
    func onDidSelectedFile(file:FBFile) -> Void {
        NSLog("%@,%@",file.displayName,file.filePath.absoluteString)
        
        if let fileExtension = file.fileExtension?.lowercaseString where audioExtensions.contains(fileExtension){
            
            let parentDirectory = file.filePath.URLByDeletingLastPathComponent;
            let medias:[VLCMedia] = FileParser.sharedInstance.filesForDirectory(parentDirectory!)
            
            let audioVC = AudioViewController.sharedInstance
            let index = audioVC.indexOfMedia(file.filePath)
            if(index > -1){
                audioVC.playMediaAtIndex(index);
            }else{
                //            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                //            let audioVC =  storyboard.instantiateViewControllerWithIdentifier("VCAudioPlayer") as! AudioViewController
                audioVC.medias = medias
                let i = audioVC.indexOfMedia(file.filePath)
                audioVC.playMediaAtIndex(i)
            }

            localFileBrowser.presentViewController(audioVC, animated: true, completion: nil)
        }
        
        if let fileExtension = file.fileExtension?.lowercaseString where videoExtensions.contains(fileExtension){
            
            let videoVC = VideoViewController(contentURL: file.filePath)
            localFileBrowser.presentViewController(videoVC, animated: true, completion: nil)
            videoVC.play()
        }
    }
    
    func onIndicatorClicked(sender:AnyObject?){
        let audioVC = AudioViewController.sharedInstance
        if (audioVC.medias!.count == 0) {
            return
        }
        localFileBrowser.presentViewController(audioVC,animated: true,completion: nil);
    }
}

