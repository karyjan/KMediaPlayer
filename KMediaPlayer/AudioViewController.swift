//
//  AudioViewController.swift
//  KMediaPlayer
//
//  Created by kouyongzan on 16/8/8.
//  Copyright © 2016年 kouyongzan. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class AudioViewController: UIViewController ,VLCMediaDelegate ,VLCMediaPlayerDelegate{
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var hearBtn: UIButton!
    @IBOutlet weak var remaningLabel: UILabel!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var toggleBtn: UIButton!
    @IBOutlet weak var preBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var cycleBtn: UIButton!
    @IBOutlet weak var progressSilder: MusicSlider!
    
    enum MusicCycleType {
        case MusicCycleTypeLoopAll
        case MusicCycleTypeLoopSingle
        case MusicCycleTypeShuffle
    }
    
    var _medias = [VLCMedia]()
    var playingBeforeSliding:Bool = false
    var duration:Int32 = 0;

    /// Mapped for case insensitivity
    var medias: [VLCMedia]? {
        get {
            return _medias
        }
        set {
            if let newValue = newValue {
                _medias = newValue
                NSLog("medias count is:%i",_medias.count)
            }
        }
    }

    //
    var currentIndex:Int = -1
    //
    var cycleType:MusicCycleType = .MusicCycleTypeLoopAll
    
    var mediaPlayer = VLCMediaPlayer()

    class var sharedInstance: AudioViewController {
        get {
            struct Static {
                static var instance : AudioViewController? = nil
                static var token : dispatch_once_t = 0
            }
            
            dispatch_once(&Static.token) {
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                Static.instance = storyboard.instantiateViewControllerWithIdentifier("VCAudioPlayer") as? AudioViewController
            }
            return Static.instance!
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true

        mediaPlayer.addObserver(self,forKeyPath:"remainingTime",options: NSKeyValueObservingOptions.New, context: nil)
        mediaPlayer.addObserver(self,forKeyPath:"time",options: NSKeyValueObservingOptions.New, context: nil)

        mediaPlayer.addObserver(self,forKeyPath:"isPlaying",options:NSKeyValueObservingOptions.New,context:nil)

    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.navigationController?.navigationBarHidden = false
        mediaPlayer.removeObserver(self,forKeyPath:"remainingTime")
        mediaPlayer.removeObserver(self,forKeyPath:"time")
        mediaPlayer.removeObserver(self,forKeyPath:"isPlaying")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.cyanColor()
        
        progressSilder.value = 0
        
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback,withOptions:AVAudioSessionCategoryOptions.AllowBluetooth)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error as NSError
        {
            print(error)
        }
                
        // Do any additional setup after loading the view.
        mediaPlayer.drawable = self.view
        mediaPlayer.delegate = self
        
        if(currentIndex > -1) {playMediaAtIndex(currentIndex)}
        else {playNext()}
    }

    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        progressSilder.value = mediaPlayer.position
        switch keyPath! {
        case "remainingTime","time":
            remaningLabel.text = mediaPlayer.remainingTime.stringValue
            currentLabel.text = mediaPlayer.time.stringValue
            break
        
        case "isPlaying":
            setMusicIsPlaying()
            break
        default:
            break
        }
        
    }
    
    func playNext() -> Void {
        let media = getNextMedia()
        playMedia(media)
    }
    
    func playPre() -> Void {
        let media = getPreMedia()
        playMedia(media)
    }
    
    func getPreMedia() -> VLCMedia? {
        if(_medias.count == 0){
            return nil
        }
        switch cycleType {
            case .MusicCycleTypeLoopSingle:
                if(currentIndex < 0) {currentIndex = 0 }
                if(currentIndex > _medias.count-1) {currentIndex = _medias.count-1}
                return _medias[currentIndex]
            case .MusicCycleTypeShuffle:
                let random = Int(arc4random_uniform(UInt32(_medias.count)))
                currentIndex = random
                return _medias[currentIndex]
            default:
                
                if(currentIndex == 0){
                    currentIndex = _medias.count;
                }
                
                if(currentIndex >= 1 && currentIndex <= _medias.count){
                    currentIndex -= 1
                    
                    let media = _medias[currentIndex]
                    return media
                }
            }
        return nil
    }
    
    
    func getNextMedia() -> VLCMedia? {
        if(_medias.count == 0){
            return nil
        }
        switch cycleType {
            case .MusicCycleTypeLoopSingle:
                if(currentIndex < 0) {currentIndex = 0 }
                if(currentIndex > _medias.count-1) {currentIndex = _medias.count-1}
                return _medias[currentIndex]
            case .MusicCycleTypeShuffle:
                let random = Int(arc4random_uniform(UInt32(_medias.count)))
                currentIndex = random
                return _medias[currentIndex]
            default:
                if(currentIndex == _medias.count-1){
                    currentIndex = -1;
                }
                
                if(currentIndex >= -1 && currentIndex < _medias.count-1){
                    currentIndex += 1
                    
                    let media = _medias[currentIndex]
                    return media
                }
        }
        return nil
    }
    
    func setMusicIsPlaying() {
        if (mediaPlayer.playing) {
            toggleBtn.setImage(UIImage(named: "big_pause_button"), forState:.Normal)
        } else {
            toggleBtn.setImage(UIImage(named: "big_play_button") ,forState:.Normal);
        }
    }
    
    func indexOfMedia(path:NSURL) -> Int {
        if(_medias.count == 0) {return -1}
        for i in 0...(_medias.count - 1) {
            let media:VLCMedia = _medias[i]
            if(media.url.absoluteString.stringByRemovingPercentEncoding == path.absoluteString){
                return i
            }
        }
        return -1
    }
    
    
    func playMediaAtIndex(i:Int) {
        if(_medias.count == 0 ) { return }
        if(i < 0 || i > _medias.count - 1){return}
        currentIndex = i;
        let media = _medias[currentIndex]
        playMedia(media)
    }
    
    func playMedia(media:VLCMedia?) -> Void {
        if(media != nil){
            media?.delegate = self
            if(progressSilder != nil) {progressSilder.value = 0}
            mediaPlayer.media = media
            mediaPlayer.play()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCycleBtnClicked(sender: AnyObject) {
        if(cycleType == .MusicCycleTypeLoopAll) {cycleType = .MusicCycleTypeShuffle}
        else if(cycleType == .MusicCycleTypeShuffle) {cycleType = .MusicCycleTypeLoopSingle}
        else if(cycleType == .MusicCycleTypeLoopSingle) {cycleType = .MusicCycleTypeLoopAll}
        
        switch cycleType {
            case .MusicCycleTypeShuffle:
                cycleBtn.setImage(UIImage(named:"shuffle_icon"), forState: .Normal)
                break
            case .MusicCycleTypeLoopSingle:
                cycleBtn.setImage(UIImage(named:"loop_single_icon"), forState: .Normal)
                break
            default:
                cycleBtn.setImage(UIImage(named:"loop_all_icon"), forState: .Normal)
                break
            
            }
    }
    
    @IBAction func onPreBtnClicked(sender: AnyObject?) {
        playPre()
    }
    
    
    @IBAction func onNextBtnClicked(sender: AnyObject?) {
        playNext()
    }
    
    
    @IBAction func onValueChanged(sender: AnyObject) {
        
        if(!mediaPlayer.seekable || duration < 10) {return}
        
        playingBeforeSliding = mediaPlayer.playing
        if(playingBeforeSliding){
            mediaPlayer.pause()
        }
        
        
        let seekTime = ((Int32)(progressSilder.value * 100)  *  duration / 100)
        
        let delta:Int = seekTime - mediaPlayer.time.intValue
        NSLog("the delta is :%i", delta)
        if(delta > 0 ){ mediaPlayer.jumpForward(Int32(delta/1000)) }
        else { mediaPlayer.jumpBackward(Int32(abs(delta/1000))) }
        
        if(playingBeforeSliding){mediaPlayer.play()}
        
    }
    
    
    @IBAction func onToggleBtnClicked(sender: AnyObject?) {
        if(mediaPlayer.playing){
            mediaPlayer.pause()
        }else{
            mediaPlayer.play()
        }
    }
    
    
    @IBAction func onDismissBtnClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion:{
            if(self.mediaPlayer.playing){MusicIndicator.sharedInstance().state = .Playing}
            else {MusicIndicator.sharedInstance().state = .Paused}
            })
    }
    //#mark
    
    func mediaPlayerStateChanged(aNotification: NSNotification!) {
        NSLog("%@", VLCMediaPlayerStateToString(mediaPlayer.state))
        if(mediaPlayer.state == VLCMediaPlayerState.Stopped){
            playNext()
        }
        
        if(mediaPlayer.playing){MusicIndicator.sharedInstance().state = .Playing}
        else {MusicIndicator.sharedInstance().state = .Paused}
        
    }
    
    func mediaPlayerTimeChanged(aNotification: NSNotification!) {
        duration = Int32(mediaPlayer.time.intValue + abs(mediaPlayer.remainingTime.intValue))
        let currentTime = Int(mediaPlayer.time.intValue/1000)
        let durationTime = Int(duration / 1000)
        dispatch_async(dispatch_get_main_queue()) {
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationTime
        }
    }
    
    func mediaDidFinishParsing(aMedia: VLCMedia!) {
        if(aMedia != nil){
            titleLabel.text = aMedia.metadataForKey("title")
            artistLabel.text = aMedia.metadataForKey("artist")
            albumLabel.text = aMedia.metadataForKey("album")
            
            let songInfo: NSMutableDictionary = NSMutableDictionary()
            if(aMedia.metaDictionary.indexForKey("title") != nil){songInfo[MPMediaItemPropertyTitle] = aMedia.metadataForKey("title")}
            if(aMedia.metaDictionary.indexForKey("artist") != nil){songInfo[MPMediaItemPropertyArtist] = aMedia.metadataForKey("artist")}
            if(aMedia.metaDictionary.indexForKey("album") != nil){songInfo[MPMediaItemPropertyAlbumTitle] = aMedia.metadataForKey("album")}
            
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as! [String : AnyObject]
        }
    }
    
}
