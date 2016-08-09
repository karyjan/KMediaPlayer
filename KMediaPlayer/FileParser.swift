//
//  FileParser.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 13/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

public class FileParser {
    
    static let sharedInstance = FileParser()
    
    var _excludesFileExtensions = [String]()
    
    /// Mapped for case insensitivity
    var excludesFileExtensions: [String]? {
        get {
            return _excludesFileExtensions.map({$0.lowercaseString})
        }
        set {
            if let newValue = newValue {
                _excludesFileExtensions = newValue
            }
        }
    }
    
    var excludesFilepaths: [NSURL]?
    
    let fileManager = NSFileManager.defaultManager()
    
    func documentsURL() -> NSURL {
        return fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
    }
    
    func filesForDirectory(directoryPath: NSURL) -> [VLCMedia]  {
        var files = [VLCMedia]()
        var filePaths = [NSURL]()
        // Get contents
        do  {
            filePaths = try self.fileManager.contentsOfDirectoryAtURL(directoryPath, includingPropertiesForKeys: [], options: [.SkipsHiddenFiles])
        } catch {
            return files
        }
        // Parse
        for filePath in filePaths {
            let file = VLCMedia.init(URL: filePath)
            if let excludesFileExtensions = excludesFileExtensions, let fileExtensions = filePath.pathExtension where excludesFileExtensions.contains(fileExtensions) {
                continue
            }
            if let excludesFilepaths = excludesFilepaths where excludesFilepaths.contains(filePath) {
                continue
            }
            if filePath.lastPathComponent?.isEmpty == false {
                files.append(file)
            }
        }
        // Sort
        files = files.sort(){$0.url.lastPathComponent < $1.url.lastPathComponent}
        return files
    }

}
