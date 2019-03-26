//
//  PlayerViewController.swift
//  Onyx
//
//  Created by Hafiz Usama on 2019-03-24.
//  Copyright © 2019 HU. All rights reserved.
//

import UIKit
import AVKit

class PlayerViewController: AVPlayerViewController {

    weak var playerDelegate: PlayerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.showsPlaybackControls = false
    }
    
    @IBAction func exitButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true) {
            self.playerDelegate?.donePlaying()
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
