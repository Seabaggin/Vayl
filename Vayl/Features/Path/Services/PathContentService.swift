//
//  PathContentService.swift
//  Vayl — Path
//
//  Loads a Path style's bundled, read-only landmark content (phases +
//  landmarks) from Vayl/Resources/Content/<styleId>-path.json.
//

import Foundation

struct PathContentService {
    /// Loads the full phase/landmark content for one Path style.
    /// `styleId` maps to a bundled file named "<styleId>-path.json"
    /// (e.g. "swinging" -> Resources/Content/swinging-path.json).
    func loadStyle(_ styleId: String) throws -> PathStyleContent {
        try ContentLoader.loadSingle(PathStyleContent.self, from: "\(styleId)-path")
    }
}
