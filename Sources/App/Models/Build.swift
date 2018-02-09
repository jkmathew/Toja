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
    
    var buildURL: String
    var releaseNotes: String
    var specialNotes: String
    
    struct Keys {
        static let id = "id"
        static let buildURL = "buildURL"
        static let releaseNotes = "releaseNotes"
        static let specialNotes = "specialNotes"
    }
    
    init(buildURL: String, releaseNotes: String, specialNotes: String) {
        self.buildURL = buildURL
        self.releaseNotes = releaseNotes
        self.specialNotes = specialNotes
    }
    
    init(row: Row) throws {
        buildURL = try row.get(Build.Keys.buildURL)
        releaseNotes = try row.get(Build.Keys.releaseNotes)
        specialNotes = try row.get(Build.Keys.specialNotes)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Build.Keys.buildURL, buildURL)
        try row.set(Build.Keys.releaseNotes, releaseNotes)
        try row.set(Build.Keys.specialNotes, specialNotes)
        return row
    }
}

extension Build: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Build.Keys.buildURL)
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
            buildURL: try json.get(Build.Keys.buildURL),
            releaseNotes: try json.get(Build.Keys.releaseNotes),
            specialNotes: try json.get(Build.Keys.specialNotes)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Build.Keys.id, id)
        try json.set(Build.Keys.buildURL, buildURL)
        try json.set(Build.Keys.releaseNotes, releaseNotes)
        try json.set(Build.Keys.specialNotes, specialNotes)
        return json
    }
}
