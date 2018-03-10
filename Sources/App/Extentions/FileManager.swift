//
//  FileManager.swift
//  RestaurantServer
//
//  Created by Johnykutty on 7/19/17.
//
//

import Foundation
import Vapor

extension FileManager {
    func relativePath(_ fullPath: String) -> String {
        return fullPath.replacingOccurrences(of: workingDirectory() + "Public", with: "")
    }
    
    func uploadsDirectory(subpath: String = "") throws -> URL {
        let workPath = workingDirectory()
        
        let packageFolder = "Public/uploads/" + subpath
        let packageDirectory = URL(fileURLWithPath: workPath).appendingPathComponent(packageFolder, isDirectory: true)
        
        if !fileExists(atPath: packageDirectory.path) {
            do {
                try createDirectory(at: packageDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                let reason = "Unable to createdirectory \(packageDirectory). Underlying error \(error)"
                throw Abort(.internalServerError, reason: reason)
            }
        }
        return packageDirectory
    }
    
    func save(_ data: Bytes, filename: String? = nil, `extension`: String = "") throws -> URL {
        
        let packageDirectory = try uploadsDirectory()
        let name = filename ?? UUID().uuidString + (`extension`.count > 0 ? "." : "" ) + `extension`
        let saveURL = packageDirectory.appendingPathComponent(name, isDirectory: false)
        do {
            let data = Data(bytes: data)
            try data.write(to: saveURL)
        } catch {
            throw Abort(.internalServerError, reason: "Unable to write multipart form data to file. Underlying error \(error)")
        }
        
        return saveURL
    }
    
    func copyToUploads(_ source: URL, fileName: String, subpath: String = "") throws -> URL {
        let uploadsDirectory = try self.uploadsDirectory(subpath: subpath)
        let destinationUrl = uploadsDirectory.appendingPathComponent(fileName)
        try copyItem(at: source, to: destinationUrl)
        return destinationUrl
    }
}
