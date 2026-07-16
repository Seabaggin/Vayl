// Core/Models/Learn/Voice.swift
//
// A public-facing educator Vayl points people toward.
//
// Voices are creators only, by consent (2026-07-16). A researcher publishing a
// paper makes their WORK citable — that's what publication is for, and it's why
// findings carry `author`/`citation`. It does not make the person a channel that
// opted into being followed, least of all from a non-monogamy app. So researchers
// appear as citations under findings; people whose own public account IS their
// chosen channel appear here.
//
// `kind` and the Creators/Researchers filter are gone with them: the axis had one
// value left. `role` is a free string, so an educator who is also a researcher can
// still say so ("Researcher · Counseling Psychology") without a filter dimension.

import Foundation

struct Voice: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let role: String
    let blurb: String
    let platform: String
    let link: String?
}
