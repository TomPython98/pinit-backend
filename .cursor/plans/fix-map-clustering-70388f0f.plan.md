<!-- 70388f0f-c8e2-45d1-8927-02734c561d22 afe7432d-707a-484c-a561-26c9a048c45d -->
# Fix Multi-Event Selection Empty Events Bug

## Problem

When clicking a cluster with multiple events at the same location, the multi-event selection list opens but shows "No events found" (0 events) due to a race condition.

## Root Cause

The cluster tap handler in `MapBox.swift` (line 960-962) uses `DispatchQueue.main.async` to call `onMultiEventSelect`, which delays the event passing. By the time the async block executes, the sheet has already been presented with an empty `multiEventSelectionEvents` array, and `MultiEventSelectionView` captures this empty state.

**Flow:**

```
Cluster tap → DispatchQueue.main.async → onMultiEventSelect called
                                      ↓
                        Sheet presents with empty array BEFORE async completes
                                      ↓
                        MultiEventSelectionView captures [] in @State
```

## Solution

Remove the `DispatchQueue.main.async` wrapper from the cluster tap handler to ensure events are passed synchronously before the sheet is presented.

## Changes Required

### File: `Front_End/Fibbling_BackUp/Fibbling/Views/MapBox.swift`

**Line 958-963** - Remove async wrapper:

```swift
// BEFORE (causes race condition):
clusterView.onTap = {
    DispatchQueue.main.async {
        self.onMultiEventSelect?(Array(cluster.events))
    }
}

// AFTER (synchronous execution):
clusterView.onTap = {
    self.onMultiEventSelect?(Array(cluster.events))
}
```

## Why This Works

1. **Synchronous execution** ensures `onMultiEventSelect` is called immediately on tap
2. **Events are set first** in the callback (line 1255: `multiEventSelectionEvents = Array(events)`)
3. **Sheet presents after** events are set (line 1256: `showMultiEventSelection = true`)
4. **MultiEventSelectionView** captures the populated events array in its `@State` initialization
5. **Result**: Events display correctly in the list

## Testing

After the fix, tapping a cluster with 2 events at the same location should:

- Open the multi-event selection sheet
- Show "2 events at this location" in the header
- Display both events in the scrollable list
- Allow selection of either event

## Files Modified

- `Front_End/Fibbling_BackUp/Fibbling/Views/MapBox.swift` - Remove async wrapper from cluster tap handler

### To-dos

- [ ] Add camera change observer in makeUIView to track zoom changes and update region binding
- [ ] Add helper functions to convert Mapbox zoom to MKCoordinateSpan
- [ ] Update clustering thresholds in clusterEvents function with proper distance-based values
- [ ] Remove minZoom and maxZoom parameters from ViewAnnotationOptions in updateAnnotations
- [ ] Add tap gesture handler to ClusterAnnotationView class
- [ ] Wire up cluster tap to zoom-in functionality in updateAnnotations
- [ ] Add special handling for events at identical coordinates
- [ ] Test clustering behavior at different zoom levels with the 3 test events
- [ ] Update COMPREHENSIVE_TECHNICAL_DOCUMENTATION.md with new clustering approach