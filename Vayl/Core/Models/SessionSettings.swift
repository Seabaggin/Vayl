//
//  SessionSettings.swift
//  Vayl
//
//  The two-knob session-settings model: who reads first, and length/pace.
//  Pure struct — no logic beyond the derived soft-cap. `length` implies an
//  in-session gentle timer (built later) via `softCapMinutes`; `.unhurried`
//  means no cap at all.
//

struct SessionSettings: Equatable, Codable {
    /// Who reads the current card first. `.either` = let it decide.
    enum Reader: String, Codable, CaseIterable { case you, partner, either }
    /// Length/pace band. `.unhurried` runs with no timer at all.
    enum Length: String, Codable, CaseIterable { case short, full, unhurried } // ~10 / ~20 / no-cap

    var reader: Reader = .you
    var length: Length = .full

    /// nil == no timer (unhurried); otherwise the soft-cap minutes the
    /// in-session timer consumes.
    var softCapMinutes: Int? {
        switch length {
        case .short:     10
        case .full:      20
        case .unhurried: nil
        }
    }
}
