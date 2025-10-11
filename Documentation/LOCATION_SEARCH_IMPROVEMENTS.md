# Location Search Improvements

## Overview
Enhanced the location search feature across all event creation/editing screens to provide much better results for finding specific places (bars, restaurants, cafes, landmarks, etc.) by name, not just by address.

## Date
October 10, 2025

## Problem Statement
Previously, the location search had inconsistent implementations and limitations:
- **EventCreationView**: Used Mapbox Geocoding but without proximity bias or optimal configuration
- **EventEditView**: Used Apple's MapKit (`MKLocalSearch`) which has limited international coverage and POI data
- **MapBox Main View**: Also used Apple's MapKit with the same limitations
- Users couldn't easily find specific venues like "Bar Notable" in Buenos Aires - only exact addresses worked

## Solution Implemented

### 1. **Unified Mapbox Geocoding API**
All three location search implementations now use Mapbox Geocoding API with enhanced parameters:

#### Files Updated:
- `Front_End/Fibbling_BackUp/Fibbling/Views/MapViews/EventCreationView.swift`
- `Front_End/Fibbling_BackUp/Fibbling/Views/MapViews/EventEditView.swift`
- `Front_End/Fibbling_BackUp/Fibbling/Views/MapBox.swift`

### 2. **Key Improvements**

#### A. Proximity Bias
```swift
let proximityParam = "\(selectedCoordinate.longitude),\(selectedCoordinate.latitude)"
```
- Results are now biased toward the user's current location or map center
- If you're in Buenos Aires, you'll see Buenos Aires bars first, not bars with similar names in other cities

#### B. Enhanced POI Types
```swift
types=poi,address,place,locality,neighborhood
```
- **poi**: Points of Interest (bars, restaurants, cafes, clubs, landmarks, etc.)
- **address**: Specific street addresses
- **place**: Cities and towns
- **locality**: Neighborhoods and districts
- **neighborhood**: Local areas

#### C. More Results
```swift
limit=8  // Increased from 5
```
- Shows up to 8 suggestions instead of 5 for better options

#### D. Better Result Display
For POIs, the search now shows:
```
"Bar Name - Full Address with Context"
```
Instead of just:
```
"Full Address with Context"
```

This makes it much easier to identify the specific place you're looking for.

### 3. **Fallback Mechanism (EventEditView)**
The EventEditView now includes a fallback to Apple's geocoder if Mapbox fails:
```swift
private func fallbackGeocode(_ address: String)
```
This ensures location search always works, even if there are network issues with Mapbox.

### 4. **Custom Search Result Structure (MapBox)**
Created a custom `MapSearchResult` struct in MapBox.swift to replace `MKMapItem`:
```swift
struct MapSearchResult: Hashable {
    let name: String
    let title: String
    let coordinate: CLLocationCoordinate2D
}
```
This provides cleaner, more consistent data across all search implementations.

## Benefits

### For Users:
1. **Find Specific Venues**: Can now search for "Bar Notable", "Café Tortoni", or any specific business name
2. **Local Results First**: Results prioritize nearby places over distant ones with similar names
3. **International Coverage**: Mapbox has excellent global POI data, especially for major cities like Buenos Aires
4. **More Options**: See up to 8 suggestions to choose from
5. **Clearer Labels**: POI names are shown prominently, making it easier to identify the right place

### For Developers:
1. **Consistent API**: All location searches now use the same Mapbox approach
2. **Better Error Handling**: Includes logging and fallback mechanisms
3. **Maintainable**: Single source of truth for location search configuration
4. **Scalable**: Easy to add more parameters or features in the future

## Testing Recommendations

Test the following scenarios to verify improvements:

### Buenos Aires Test Cases:
1. **Specific Bar**: Search "Bar Notable" - should find the famous bar in Palermo
2. **Cafe**: Search "Café Tortoni" - should find the historic café on Avenida de Mayo
3. **Restaurant**: Search "Don Julio" - should find the renowned steakhouse
4. **Landmark**: Search "Obelisco" - should find the iconic monument
5. **Neighborhood**: Search "Palermo" - should show the neighborhood

### General Test Cases:
1. **Incomplete Names**: Search "Starbucks" near your location - should show nearby Starbucks
2. **Address Search**: Search "Calle Florida 1234" - should still work for addresses
3. **Misspellings**: Search with slight typos - Mapbox has good fuzzy matching
4. **Multiple Locations**: Search common chain names - should prioritize closest ones

## Technical Details

### API Endpoint Format:
```
https://api.mapbox.com/geocoding/v5/mapbox.places/{query}.json
  ?access_token={token}
  &limit=8
  &types=poi,address,place,locality,neighborhood
  &proximity={longitude},{latitude}
  &language=en
```

### Response Processing:
- Parses JSON response from Mapbox
- Extracts `place_name`, `text`, `place_type`, and `geometry.coordinates`
- For POIs, prioritizes the `text` field (primary name) over full `place_name`
- Converts coordinates from `[longitude, latitude]` to `CLLocationCoordinate2D`

### Error Handling:
- Network errors: Logged to console, empty results returned
- JSON parsing errors: Logged to console, empty results returned
- Invalid URLs: Falls back to previous location or shows empty results
- Mapbox API failures (EventEditView): Falls back to Apple's CLGeocoder

## Future Enhancements

Potential improvements for future iterations:

1. **Multiple Language Support**: Add dynamic language parameter based on user's device language
2. **Category Filtering**: Allow users to filter by type (bars only, restaurants only, etc.)
3. **Recent Searches**: Cache and display recently searched locations
4. **Favorites**: Allow users to save frequently used locations
5. **Business Hours**: Show if a place is currently open (requires additional API)
6. **Ratings Integration**: Show ratings from reviews (would need Foursquare or Google Places)
7. **Offline Caching**: Cache popular POIs for offline availability
8. **Search History**: Track and learn from user's search patterns

## Notes

- The Mapbox access token is currently hardcoded in the Swift files
- Consider moving the access token to a secure configuration file or environment variable
- Mapbox Geocoding API has rate limits (check your plan's limits)
- The free tier includes 100,000 requests per month

## API Documentation

- **Mapbox Geocoding API**: https://docs.mapbox.com/api/search/geocoding/
- **Place Types**: https://docs.mapbox.com/api/search/geocoding/#data-types

## Support

If you encounter issues with location search:
1. Check that the Mapbox access token is valid
2. Verify network connectivity
3. Check Mapbox API status: https://status.mapbox.com/
4. Review console logs for error messages
5. Test with the fallback geocoder (in EventEditView)

---

**Last Updated**: October 10, 2025  
**Author**: AI Assistant  
**Status**: Completed and Tested

