//
//  ViewController.swift
//  Onyx
//
//  Created by Hafiz Usama on 2019-03-24.
//  Copyright © 2019 HU. All rights reserved.
//

import UIKit
import AVKit
import CoreMotion

let kDownloadText = "Download"
let kStartText = "Start"
let fileURLPath = "https://storage.googleapis.com/onyx-internal-data/interview-data/onyx_data.zip"

class ViewController: UIViewController, FileDelegate, PlayerDelegate, UIAccelerometerDelegate {

    @IBOutlet weak var controlButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    
    let motion = CMMotionManager()
    var fileHandler: FileHandler?
    var currentVideoPath:URL?
    var videoState: VideoState = .none
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.slider.isHidden = true
        self.slider.isEnabled = false
        self.fileHandler = FileHandler(self)
    }
    
    //FileDelegate Implementation
    func fileAvailableToPlay(_ videoPath:URL?, _ error: Error?) {
        if let _ = error {
            self.controlButton.setTitle(kDownloadText, for: .normal)
            self.controlButton.isEnabled = true
            self.videoState = .none
        }
        else if let videoPath = videoPath {
            self.currentVideoPath = videoPath
            self.startAccelerometers()
        }
    }
    
    //PlayerDelegate Implementation
    func donePlaying() {
        self.currentVideoPath?.deleteLastPathComponent()
        if let videoPath = currentVideoPath {
            self.fileHandler?.deleteFile(videoPath)
        }
        
        self.currentVideoPath = nil
        self.controlButton.setTitle(kDownloadText, for: .normal)
        self.controlButton.isEnabled = true
        self.slider.isHidden = true
        self.videoState = .none
        self.slider.value = 0
    }
    
    func startDownload() {
        self.controlButton.setTitle(kStartText, for: .normal)
        self.controlButton.isEnabled = false
        self.slider.isHidden = false
        self.fileHandler?.startDownload(fileURLPath)
    }
    
    func startPlay(_ videoPath:URL) {
        let player = AVPlayer(url: videoPath)
        if let playerNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "PlayerNavigationController") as? UINavigationController, let playerController = playerNavigationController.topViewController as? PlayerViewController {
            playerController.playerDelegate = self
            playerController.player = player
            present(playerNavigationController, animated: true) {
                player.play()
            }
        }
    }
    
    func startAccelerometers() {
        // Make sure the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
            self.motion.startAccelerometerUpdates()
            
            // Configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: (1.0/60.0),
                               repeats: true, block: { (timer) in
                                // Get the accelerometer data.
                                if let data = self.motion.accelerometerData {
                                    let value = data.acceleration.x
                                    self.slider.value = Float(value)
                                    if value > -0.10 && value < 0.10 {
                                        self.controlButton.isEnabled = true
                                    } else {
                                        self.controlButton.isEnabled = false
                                    }
                                }
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: .default)
        }
    }
    
    func stopAccelerometers() {
        if self.motion.isAccelerometerAvailable {
            self.motion.stopAccelerometerUpdates()
        }
        
        self.timer?.invalidate()
    }
    
    @IBAction func controlButtonTapped(_ sender: UIButton) {
        if self.videoState == .none {
            self.videoState = .download
            self.startDownload()
        } else if self.videoState == .download, let videoPath = self.currentVideoPath {
            self.videoState = .play
            self.controlButton.isEnabled = false
            self.startPlay(videoPath)
            self.stopAccelerometers()
        }
    }
}

enum VideoState {
    case download
    case play
    case none
}

protocol FileDelegate: NSObjectProtocol {
    func fileAvailableToPlay(_ filePath:URL?, _ error: Error?)
}

protocol PlayerDelegate: NSObjectProtocol {
    func donePlaying()
}
