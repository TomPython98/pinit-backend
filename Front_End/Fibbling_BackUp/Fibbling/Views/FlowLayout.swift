import SwiftUI

// MARK: - FlowLayout (Shared Component)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let dimensions = calculateDimensions(proposal: proposal, subviews: subviews)
        return dimensions.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let dimensions = calculateDimensions(proposal: proposal, subviews: subviews)
        
        var x = bounds.minX
        var y = bounds.minY
        
        for (index, row) in dimensions.rows.enumerated() {
            x = bounds.minX
            
            if index > 0 {
                y += dimensions.rowHeights[index - 1] + spacing
            }
            
            for viewIndex in row {
                let viewSize = dimensions.sizes[viewIndex]
                subviews[viewIndex].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height)
                )
                x += viewSize.width + spacing
            }
        }
    }
    
    private func calculateDimensions(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, rows: [[Int]], sizes: [CGSize], rowHeights: [CGFloat]) {
        var sizes: [CGSize] = []
        var rows: [[Int]] = [[]]
        var rowHeights: [CGFloat] = []
        
        // Get the width we're working with
        guard let maxWidth = proposal.width else {
            return (CGSize(width: 0, height: 0), [], [], [])
        }
        
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var currentRowIndex = 0
        
        for (index, view) in subviews.enumerated() {
            // Get the size this view wants to be
            let viewSize = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            sizes.append(viewSize)
            
            // If this view doesn't fit on current row, start a new row
            if currentRowWidth + viewSize.width > maxWidth && currentRowWidth > 0 {
                // Save height of completed row
                rowHeights.append(currentRowHeight)
                
                // Start a new row
                currentRowIndex += 1
                rows.append([])
                currentRowWidth = viewSize.width
                currentRowHeight = viewSize.height
            } else {
                // Add to the current row
                currentRowWidth += viewSize.width + (currentRowWidth > 0 ? spacing : 0)
                currentRowHeight = max(currentRowHeight, viewSize.height)
            }
            
            rows[currentRowIndex].append(index)
        }
        
        // Add the height of the last row
        if !rows.isEmpty {
            rowHeights.append(currentRowHeight)
        }
        
        // Calculate total height: sum of row heights plus spacing between rows
        let height = rowHeights.reduce(0, +) + CGFloat(max(0, rowHeights.count - 1)) * spacing
        
        return (CGSize(width: maxWidth, height: height), rows, sizes, rowHeights)
    }
}
