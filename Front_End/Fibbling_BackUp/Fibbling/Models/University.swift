import SwiftUI

struct University {
    let name: String
    let color: Color
    let textColor: Color
    let logo: String
}

extension University {
    static func sampleData() -> [University] {
        return [
            University(name: "Technical University", color: Color.blue, textColor: .white, logo: "wrench.fill"),
            University(name: "Earth Science University", color: Color.green, textColor: .white, logo: "leaf.fill"),
            University(name: "Medical University", color: Color.red, textColor: .white, logo: "cross.fill"),
            University(name: "Business School", color: Color.purple, textColor: .white, logo: "chart.bar.fill"),
            University(name: "Design Academy", color: Color.orange, textColor: .white, logo: "paintbrush.fill"),
            University(name: "Law School", color: Color.gray, textColor: .black, logo: "scroll.fill")
        ]
    }
}
