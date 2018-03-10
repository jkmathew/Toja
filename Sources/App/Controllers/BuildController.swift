//
//  BuildController.swift
//  TojaPackageDescription
//
//  Created by Johnykutty Mathew on 29/01/18.
//

import Foundation
import Vapor
import HTTP
import ZIPFoundation

public final class BuildController {
    
    private let droplet: Droplet
    
    init(_ drop: Droplet) {
        droplet = drop
        addRoutes()
    }
    
    func addRoutes() {
        let buildGroup = droplet.grouped("build")
        buildGroup.get(Build.parameter, handler: installView)
        
        let addGroup = buildGroup.grouped("upload")
        addGroup.get(handler: uploadBuildView)
        addGroup.post(handler: uploadBuild)
    }
    
    func installView(_ request: Request) throws -> ResponseRepresentable {
        let build = try request.parameters.next(Build.self)
        return try build.makeJSON()
    }
    
    func uploadBuildView(_ request: Request) throws -> ResponseRepresentable {
        return try droplet.view.make("uploadBuild")
    }
    
    func uploadBuild(_ request: Request) throws -> ResponseRepresentable {
        guard let file = request.formData?["build"] else {
            throw Abort(.badRequest, reason: "No file in request")
        }
        
        let fileBytes = file.part.body
        guard fileBytes.count > 0 else {
            throw Abort(.badRequest, reason: "No file in request")
        }
        let releaseNotes = request.data[Build.Keys.releaseNotes]?.string ?? ""
        let specialNotes = request.data[Build.Keys.specialNotes]?.string ?? ""
        
        guard let baseUrl = droplet.config["env", "manifest_api"]?.string else {

            let fix1 = "Add env.json and set manifest_api key or MANIFEST_API_BASE_URL environment variable to manifest api url"
            let fix2 = "Provide env.manifest_api parameter for --configs flag in run command"
            let suggestedFixes = [fix1, fix2]
            throw Abort(.notAcceptable, reason: "No manifest api url provided", suggestedFixes: suggestedFixes)
        }
        let addManifestURL = baseUrl + "/build"
        let postJSON = try saveIPA(fileBytes, baseURI: request.uri.baseURI)
        
        let headers = [HeaderKey.contentType: "application/json"]
        let response = try droplet.client.post(addManifestURL, query: [:], headers, postJSON, through: [])

        guard let manifestId = response.json?["data", "id"]?.string else {
            throw Abort(.notAcceptable, reason: "Failed to get resgister manifest", suggestedFixes: [])
        }
        let manifestURL = "\(addManifestURL)/\(manifestId)/manifest.plist"
        let build = Build(manifestURL: manifestURL, releaseNotes: releaseNotes, specialNotes: specialNotes)
        try build.save()
        return response
    }
    
    func saveIPA(_ fileBytes: Bytes, baseURI: String) throws -> JSON {
        let tempDirectory = NSTemporaryDirectory()
        
        let filemanager = FileManager.default
        let fullFileURL = try filemanager.save(fileBytes, extension: "ipa")
        let ipaPath = filemanager.relativePath(fullFileURL.path)
        let destinationPath = tempDirectory + ipaPath
        do {
            try filemanager.unzipItem(at: fullFileURL, to: URL(fileURLWithPath: destinationPath))
        } catch {
            print("UnZIP archive failed with error:\(error)")
            throw error
        }
        
        let payloadPath = "\(destinationPath)/Payload"

        let contents = try filemanager.contentsOfDirectory(atPath: payloadPath)
        
        guard let appFile = contents.first(where: { $0.hasSuffix(".app") }) else {
            throw Abort(.notAcceptable, reason: "No .app found in payload", suggestedFixes: [])
        }
        let appPath = "\(payloadPath)/\(appFile)"
        let plistPath = "\(appPath)/Info.plist"
        let imagePath = "\(appPath)/AppIcon60x60@2x.png"

        var postJSON = JSON()
        
        let plist = try plistContents(from: URL(fileURLWithPath: plistPath))
        guard let bundleId = plist["CFBundleIdentifier"] as? String else {
            throw Abort(.notAcceptable, reason: "Failed to get CFBundleIdentifier", suggestedFixes: [])
        }
        guard let bundleVersion = plist["CFBundleShortVersionString"] as? String else {
            throw Abort(.notAcceptable, reason: "Failed to get CFBundleShortVersionString", suggestedFixes: [])
        }
        guard let buildNumber = plist["CFBundleVersion"] as? String else {
            throw Abort(.notAcceptable, reason: "Failed to get CFBundleVersion", suggestedFixes: [])
        }
        
        let displayName = plist["CFBundleName"] ?? plist["CFBundleName"]
        guard let title = displayName as? String else {
            throw Abort(.notAcceptable, reason: "Failed to get Display name", suggestedFixes: [])
        }
        
        let imageURL = try filemanager.copyToUploads(URL(fileURLWithPath: imagePath), fileName: UUID().uuidString + ".png")
        let imageUploadsPath = filemanager.relativePath(imageURL.path)
        let imagePublicPath = "\(baseURI)/\(imageUploadsPath)"
        try postJSON.set("bundle_identifier", bundleId)
        try postJSON.set("bundle_version", bundleVersion)
        try postJSON.set("build_number", buildNumber)
        try postJSON.set("title", title)
        try postJSON.set("build_url", "\(baseURI)/\(ipaPath)")
        try postJSON.set("display_image", imagePublicPath)
        try postJSON.set("full_size_image", imagePublicPath)
        
        return postJSON
    }
    
    func plistContents(from fileURL: URL) throws -> [String: Any] {
        
        let data = try Data(contentsOf: fileURL)
        guard let result = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            throw Abort(.notAcceptable, reason: "PropertyListSerialization failed", suggestedFixes: [])
        }
        return result
    }
}
