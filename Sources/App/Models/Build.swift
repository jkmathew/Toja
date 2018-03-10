//
//  Build.swift
//  TojaPackageDescription
//
//  Created by Johnykutty Mathew on 29/01/18.
//

import Foundation
import Vapor
import FluentProvider
import HTTP

final class Build: Model {
    let storage = Storage()
    
    var manifestURL: String
    var releaseNotes: String
    var specialNotes: String
    
    struct Keys {
        static let id = "id"
        static let manifestURL = "buildURL"
        static let releaseNotes = "releaseNotes"
        static let specialNotes = "specialNotes"
    }
    
    init(manifestURL: String, releaseNotes: String, specialNotes: String) {
        self.manifestURL = manifestURL
        self.releaseNotes = releaseNotes
        self.specialNotes = specialNotes
    }
    
    init(row: Row) throws {
        manifestURL = try row.get(Build.Keys.manifestURL)
        releaseNotes = try row.get(Build.Keys.releaseNotes)
        specialNotes = try row.get(Build.Keys.specialNotes)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Build.Keys.manifestURL, manifestURL)
        try row.set(Build.Keys.releaseNotes, releaseNotes)
        try row.set(Build.Keys.specialNotes, specialNotes)
        return row
    }
}

extension Build: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Build.Keys.manifestURL)
            builder.string(Build.Keys.releaseNotes)
            builder.string(Build.Keys.specialNotes)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Build: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            manifestURL: try json.get(Build.Keys.manifestURL),
            releaseNotes: try json.get(Build.Keys.releaseNotes),
            specialNotes: try json.get(Build.Keys.specialNotes)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Build.Keys.id, id)
        try json.set(Build.Keys.manifestURL, manifestURL)
        try json.set(Build.Keys.releaseNotes, releaseNotes)
        try json.set(Build.Keys.specialNotes, specialNotes)
        return json
    }
}
