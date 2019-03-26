//
//  FileHandler.swift
//  Onyx
//
//  Created by Hafiz Usama on 2019-03-24.
//  Copyright © 2019 HU. All rights reserved.
//

import Foundation
import SSZipArchive

class FileHandler: NSObject {
    weak var fileDelegate: FileDelegate?
    
    init(_ delegate:FileDelegate) {
        self.fileDelegate = delegate
    }
    
    func startDownload(_ fileURLPath:String) {
        let fileURL = URL(string: fileURLPath)
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL!)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            var fileError: Error?
            if let tempLocalUrl = tempLocalUrl, error == nil {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    if statusCode == 200 {
                        print("Successfully downloaded. Status code: \(statusCode)")
                        self.unarchiveFile(tempLocalUrl)
                    } else {
                        fileError = NSError(domain:"", code:statusCode, userInfo:nil)
                    }
                }
                
            } else {
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription ?? "N/A");
                fileError = error
            }
            
            if let _ = fileError {
                DispatchQueue.main.async {
                    self.fileDelegate?.fileAvailableToPlay(nil, fileError)
                }
            }
        }
        task.resume()
    }
    
    func unarchiveFile(_ tempLocalUrl:URL) {
        // Create destination URL
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationFileUrl:URL = documentsUrl.appendingPathComponent("tempFile.zip")
        let unzipDestinationFileUrl:URL = documentsUrl.appendingPathComponent("downloadedFile")
        
        do {
            try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
        } catch (let writeError) {
            print("Error creating a file \(destinationFileUrl) : \(writeError)")
            DispatchQueue.main.async {
                self.fileDelegate?.fileAvailableToPlay(nil, writeError)
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            SSZipArchive.unzipFile(atPath: destinationFileUrl.path, toDestination: unzipDestinationFileUrl.path,progressHandler: { (path, info, a, b) in
            }, completionHandler: { (path, result, error) in
                do {
                    if result {
                        let files = try FileManager.default.contentsOfDirectory(atPath: unzipDestinationFileUrl.path)
                        if let file = files.first {
                            let filePath:URL = unzipDestinationFileUrl.appendingPathComponent(file)
                            // make sure to return back to main thread
                            DispatchQueue.main.async {
                                self.fileDelegate?.fileAvailableToPlay(filePath, nil)
                            }
                        }
                    }
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                    DispatchQueue.main.async {
                        self.fileDelegate?.fileAvailableToPlay(nil, error)
                    }
                }
                
                // cleanup
                do {
                    try FileManager.default.removeItem(atPath: destinationFileUrl.path)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            })
        }
    }
    
    func deleteFile(_ filePath: URL) {
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
}
