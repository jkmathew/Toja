//
//  URI.swift
//  TojaPackageDescription
//
//  Created by Johnykutty on 2/9/18.
//

import URI

extension URI {
    public var baseURI: String {
        let portString = (port == nil) ? "" : ":\(port ?? 0)"
        return "\(scheme)://\(hostname)\(portString)/"
    }
}
