// Core/Models/Learn/FindingType+Display.swift
import SwiftUI

extension FindingType {
    var sfSymbol: String {
        switch self {
        case .prevalence: return "chart.pie"
        case .comparison: return "arrow.left.arrow.right"
        case .predictor:  return "point.3.connected.trianglepath.dotted"
        case .myth:       return "xmark.circle"
        case .mechanism:  return "lightbulb"
        }
    }
    var tint: Color {
        switch self {
        case .prevalence, .myth: return AppColors.spectrumCyan
        case .comparison, .mechanism: return AppColors.spectrumPurple
        case .predictor: return AppColors.spectrumMagenta
        }
    }
    var label: String {
        switch self {
        case .prevalence: return "Prevalence"
        case .comparison: return "Comparison"
        case .predictor:  return "Predictor"
        case .myth:       return "Myth-buster"
        case .mechanism:  return "Mechanism"
        }
    }
}
