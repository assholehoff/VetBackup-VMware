//
//  EdgeBorder.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-03.
//

import SwiftUI

struct EdgeBorder: Shape {
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        Path { p in
            if edges.contains(.top) {
                p.move(to: CGPoint(x: rect.minX, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            }
            if edges.contains(.trailing) {
                p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            if edges.contains(.bottom) {
                p.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            }
            if edges.contains(.leading) {
                p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            }
        }
    }
}
