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
    func save(_ data: Bytes, filename: String? = nil, `extension`: String = "") throws -> String {
        let workPath = workingDirectory()
        
        let name = filename ?? UUID().uuidString + `extension`
        let imageFolder = "Public/uploads"
        let imageDirectory = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true)
        
        if !fileExists(atPath: imageDirectory.path) {
            do {
                try createDirectory(at: imageDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                let reason = "Unable to createdirectory \(imageDirectory). Underlying error \(error)"
                throw Abort(.internalServerError, reason: reason)
            }
        }
        let saveURL = imageDirectory.appendingPathComponent(name, isDirectory: false)
        do {
            let data = Data(bytes: data)
            try data.write(to: saveURL)
        } catch {
            throw Abort(.internalServerError, reason: "Unable to write multipart form data to file. Underlying error \(error)")
        }
        
        return saveURL.path.replacingOccurrences(of: workPath + "Public", with: "")
    }
}
