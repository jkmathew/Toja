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
        let addGroup = buildGroup.grouped("upload")
        addGroup.get(handler: uploadBuildView)
        addGroup.post(handler: uploadBuild)
    }
    
    func uploadBuildView(_ request: Request) throws -> ResponseRepresentable {
        print("uploadBuild \(request.uri.baseURI)")

//        var json = JSON()
//        return try droplet.view.make("addBuild", json)
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
//        let build = Build()
        var postJSON = try saveIPA(fileBytes, baseURI: request.uri.baseURI)
        
        /*
         {
         "build_url":"//buildURL",
         "display_image":"//imageurl",
         "full_size_image":"//imageurl",
         "bundle_identifier":"com.test.testapp",
         "bundle_version":"1.0.0",
         "build_number":"15",
         "title":"Sample app"
         }
         
         */
        let headers = [HeaderKey.contentType: "application/json"]
        let response = try droplet.client.post(addManifestURL, query: [:], headers, postJSON, through: [])
//        return try droplet.view.make("addBuild", json)
//        response.decodeJSONBody()
        print("upload response")
        return response
    }
    
    func saveIPA(_ fileBytes: Bytes, baseURI: String) throws -> JSON {
        let temp = NSTemporaryDirectory()
        print(temp)
        
        let filemanager = FileManager.default
        let fullFileURL = try filemanager.save(fileBytes, extension: "ipa")
        let filePath = filemanager.relativePath(fullFileURL.path)
        let destinationPath = temp + filePath
        do {
            try filemanager.unzipItem(at: fullFileURL, to: URL(fileURLWithPath: destinationPath))
        } catch {
            print("UnZIP archive failed with error:\(error)")
        }
        
        let payloadPath = "\(destinationPath)/Payload"

        let contents = try filemanager.contentsOfDirectory(atPath: payloadPath)
        
        guard let appFile = contents.first(where: { $0.hasSuffix(".app") }) else {
            throw Abort(.notAcceptable, reason: "No .app found in payload", suggestedFixes: [])
        }
        let appPath = "\(payloadPath)/\(appFile)"
        let plistPath = "\(appPath)/Info.plist"
        var postJSON = JSON()

        try postJSON.set("build_url", "\(baseURI)/\(filePath)")
        try postJSON.set("display_image", "specialNotes")
        try postJSON.set("full_size_image", "specialNotes")
        try postJSON.set("bundle_identifier", "specialNotes")
        try postJSON.set("bundle_version", "specialNotes")
        try postJSON.set("build_number", "specialNotes")
        try postJSON.set("title", "specialNotes")
        
        return postJSON
    }
}
