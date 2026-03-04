import SwiftUI

// Decorative overlays removed for functionality testing.
// Stubs kept so existing references compile.

struct ConstructionLines: View {
    var showVertical: Bool = true
    var showHorizontal: Bool = true
    var verticalOffset: CGFloat = 0.5
    var horizontalOffset: CGFloat = 0.4

    var body: some View {
        EmptyView()
    }
}

struct InkSplatter: View {
    var count: Int = 5

    var body: some View {
        EmptyView()
    }
}

struct AnnotationText: View {
    let text: String
    var color: Color = .clear

    var body: some View {
        EmptyView()
    }
}
