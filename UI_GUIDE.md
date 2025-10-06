# PinIt UI Guide Documentation

## Overview
This document defines the design system, UI components, and visual guidelines for the PinIt application across iOS and Android platforms.

## Design Philosophy

### Core Principles
- **Simplicity**: Clean, uncluttered interfaces that focus on functionality
- **Consistency**: Unified design language across all platforms
- **Accessibility**: Inclusive design that works for all users
- **Performance**: Smooth, responsive user interactions
- **Brand Identity**: Modern, academic-focused aesthetic

### Design Goals
- Intuitive event discovery and creation
- Seamless social interaction
- Clear information hierarchy
- Efficient navigation patterns
- Engaging visual feedback

## Color System

### Primary Colors
```swift
// iOS Color System
extension Color {
    static let brandPrimary = Color(red: 0.2, green: 0.4, blue: 0.8)      // #3366CC
    static let brandSecondary = Color(red: 0.1, green: 0.7, blue: 0.3)   // #1AB366
    static let brandAccent = Color(red: 0.9, green: 0.3, blue: 0.2)       // #E64D33
}
```

```kotlin
// Android Color System
object PinItColors {
    val BrandPrimary = Color(0xFF3366CC)
    val BrandSecondary = Color(0xFF1AB366)
    val BrandAccent = Color(0xFFE64D33)
    
    val Success = Color(0xFF4CAF50)
    val Warning = Color(0xFFFF9800)
    val Error = Color(0xFFF44336)
    val Info = Color(0xFF2196F3)
}
```

### Semantic Colors
- **Primary**: Main brand color for CTAs and highlights
- **Secondary**: Supporting brand color for accents
- **Success**: Green for positive actions and states
- **Warning**: Orange for caution and pending states
- **Error**: Red for errors and destructive actions
- **Info**: Blue for informational content

### Neutral Colors
```swift
// iOS Neutral Colors
extension Color {
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)       // #1A1A1A
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)    // #808080
    static let bgPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)         // #FFFFFF
    static let bgSecondary = Color(red: 0.95, green: 0.95, blue: 0.95)    // #F2F2F2
    static let cardBackground = Color(red: 1.0, green: 1.0, blue: 1.0)     // #FFFFFF
    static let cardShadow = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.1)
}
```

## Typography

### iOS Typography
```swift
// iOS Font System
extension Font {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption1 = Font.caption
    static let caption2 = Font.caption2
}
```

### Android Typography
```kotlin
// Android Typography System
object PinItTypography {
    val LargeTitle = TextStyle(
        fontSize = 32.sp,
        fontWeight = FontWeight.Bold,
        lineHeight = 40.sp
    )
    
    val Title1 = TextStyle(
        fontSize = 28.sp,
        fontWeight = FontWeight.SemiBold,
        lineHeight = 36.sp
    )
    
    val Title2 = TextStyle(
        fontSize = 24.sp,
        fontWeight = FontWeight.SemiBold,
        lineHeight = 32.sp
    )
    
    val Headline = TextStyle(
        fontSize = 20.sp,
        fontWeight = FontWeight.SemiBold,
        lineHeight = 28.sp
    )
    
    val Body = TextStyle(
        fontSize = 16.sp,
        fontWeight = FontWeight.Normal,
        lineHeight = 24.sp
    )
    
    val Caption = TextStyle(
        fontSize = 12.sp,
        fontWeight = FontWeight.Normal,
        lineHeight = 16.sp
    )
}
```

### Typography Scale
- **Large Title**: 32sp - Page headers
- **Title 1**: 28sp - Section headers
- **Title 2**: 24sp - Card titles
- **Headline**: 20sp - Component headers
- **Body**: 16sp - Primary text content
- **Callout**: 16sp - Secondary text
- **Subheadline**: 15sp - Supporting text
- **Footnote**: 13sp - Captions and labels
- **Caption**: 12sp - Small labels

## Spacing System

### iOS Spacing
```swift
// iOS Spacing System
extension CGFloat {
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48
}
```

### Android Spacing
```kotlin
// Android Spacing System
object PinItSpacing {
    val XS = 4.dp
    val S = 8.dp
    val M = 16.dp
    val L = 24.dp
    val XL = 32.dp
    val XXL = 48.dp
}
```

### Spacing Guidelines
- **XS (4dp)**: Tight spacing for related elements
- **S (8dp)**: Standard spacing for grouped elements
- **M (16dp)**: Default spacing between components
- **L (24dp)**: Section spacing
- **XL (32dp)**: Page-level spacing
- **XXL (48dp)**: Major section separation

## Component Library

### iOS Components

#### Custom Navigation Bar
```swift
struct CustomNavigationBar: View {
    let title: String
    let leadingButton: (() -> AnyView)?
    let trailingButton: (() -> AnyView)?
    
    var body: some View {
        HStack {
            if let leading = leadingButton {
                leading()
            } else {
                Spacer()
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if let trailing = trailingButton {
                trailing()
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .background(Color.bgPrimary)
    }
}
```

#### Custom Text Field
```swift
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(.spacingM)
        .background(Color.bgSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brandPrimary, lineWidth: text.isEmpty ? 0 : 2)
        )
    }
}
```

#### Event Card
```swift
struct EventCard: View {
    let event: StudyEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                EventTypeIcon(type: event.eventType)
            }
            
            Text(event.description ?? "")
                .font(.body)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.brandPrimary)
                
                Text(formatLocation(event.coordinate))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text(formatTime(event.time))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.spacingM)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .cardShadow, radius: 8, x: 0, y: 4)
    }
}
```

### Android Components

#### Custom Button
```kotlin
@Composable
fun PinItButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    variant: ButtonVariant = ButtonVariant.Primary,
    size: ButtonSize = ButtonSize.Medium,
    enabled: Boolean = true
) {
    val backgroundColor = when (variant) {
        ButtonVariant.Primary -> PinItColors.BrandPrimary
        ButtonVariant.Secondary -> PinItColors.BrandSecondary
        ButtonVariant.Outline -> Color.Transparent
    }
    
    val textColor = when (variant) {
        ButtonVariant.Outline -> PinItColors.BrandPrimary
        else -> Color.White
    }
    
    val padding = when (size) {
        ButtonSize.Small -> PinItSpacing.S
        ButtonSize.Medium -> PinItSpacing.M
        ButtonSize.Large -> PinItSpacing.L
    }
    
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .padding(padding),
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(
            containerColor = backgroundColor,
            contentColor = textColor
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Text(
            text = text,
            style = PinItTypography.Body,
            fontWeight = FontWeight.SemiBold
        )
    }
}
```

#### Event Card
```kotlin
@Composable
fun EventCard(
    event: StudyEventMap,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier.padding(PinItSpacing.M)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = event.title,
                    style = PinItTypography.Headline,
                    color = PinItColors.TextPrimary
                )
                
                EventTypeIcon(
                    type = event.eventType,
                    size = 24.dp
                )
            }
            
            Spacer(modifier = Modifier.height(PinItSpacing.S))
            
            Text(
                text = event.description ?: "",
                style = PinItTypography.Body,
                color = PinItColors.TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(PinItSpacing.S))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = "Location",
                        tint = PinItColors.BrandPrimary,
                        modifier = Modifier.size(16.dp)
                    )
                    
                    Spacer(modifier = Modifier.width(PinItSpacing.XS))
                    
                    Text(
                        text = formatLocation(event.coordinate),
                        style = PinItTypography.Caption,
                        color = PinItColors.TextSecondary
                    )
                }
                
                Text(
                    text = formatTime(event.time),
                    style = PinItTypography.Caption,
                    color = PinItColors.TextSecondary
                )
            }
        }
    }
}
```

## Layout Patterns

### iOS Layout Patterns

#### Standard Screen Layout
```swift
struct StandardScreenLayout<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomNavigationBar(title: title)
                
                ScrollView {
                    VStack(spacing: .spacingM) {
                        content
                    }
                    .padding(.horizontal, .spacingM)
                    .padding(.vertical, .spacingL)
                }
            }
        }
    }
}
```

#### Card Grid Layout
```swift
struct CardGridLayout<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let columns: Int
    let itemView: (Item) -> ItemView
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns)) {
            ForEach(items) { item in
                itemView(item)
            }
        }
    }
}
```

### Android Layout Patterns

#### Standard Screen Layout
```kotlin
@Composable
fun StandardScreenLayout(
    title: String,
    content: @Composable () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBar(
            title = { Text(title) },
            backgroundColor = PinItColors.BrandPrimary,
            contentColor = Color.White
        )
        
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(PinItSpacing.M),
            verticalArrangement = Arrangement.spacedBy(PinItSpacing.M)
        ) {
            item {
                content()
            }
        }
    }
}
```

#### Card Grid Layout
```kotlin
@Composable
fun <T> CardGridLayout(
    items: List<T>,
    columns: Int = 2,
    itemContent: @Composable (T) -> Unit
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(columns),
        contentPadding = PaddingValues(PinItSpacing.M),
        horizontalArrangement = Arrangement.spacedBy(PinItSpacing.M),
        verticalArrangement = Arrangement.spacedBy(PinItSpacing.M)
    ) {
        items(items) { item ->
            itemContent(item)
        }
    }
}
```

## Icon System

### Event Type Icons
```swift
// iOS Event Type Icons
struct EventTypeIcon: View {
    let type: EventType
    
    var body: some View {
        Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(.title2)
    }
    
    private var iconName: String {
        switch type {
        case .study: return "book.fill"
        case .party: return "party.popper.fill"
        case .business: return "briefcase.fill"
        case .cultural: return "theatermasks.fill"
        case .academic: return "graduationcap.fill"
        case .networking: return "person.3.fill"
        case .social: return "person.2.fill"
        case .language_exchange: return "globe"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .study: return .brandPrimary
        case .party: return .brandAccent
        case .business: return .brandSecondary
        case .cultural: return .purple
        case .academic: return .blue
        case .networking: return .green
        case .social: return .orange
        case .language_exchange: return .teal
        case .other: return .gray
        }
    }
}
```

```kotlin
// Android Event Type Icons
@Composable
fun EventTypeIcon(
    type: EventType,
    size: Dp = 24.dp,
    modifier: Modifier = Modifier
) {
    val (icon, color) = when (type) {
        EventType.STUDY -> Icons.Default.School to PinItColors.BrandPrimary
        EventType.PARTY -> Icons.Default.Celebration to PinItColors.BrandAccent
        EventType.BUSINESS -> Icons.Default.Business to PinItColors.BrandSecondary
        EventType.CULTURAL -> Icons.Default.TheaterComedy to Color.Purple
        EventType.ACADEMIC -> Icons.Default.School to Color.Blue
        EventType.NETWORKING -> Icons.Default.People to Color.Green
        EventType.SOCIAL -> Icons.Default.PeopleOutline to Color.Orange
        EventType.LANGUAGE_EXCHANGE -> Icons.Default.Language to Color.Teal
        EventType.OTHER -> Icons.Default.MoreHoriz to Color.Gray
    }
    
    Icon(
        imageVector = icon,
        contentDescription = type.name,
        tint = color,
        modifier = modifier.size(size)
    )
}
```

## Animation Guidelines

### iOS Animations
```swift
// Standard Animation Durations
extension Animation {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
}

// Common Animation Patterns
struct FadeInView<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.standard) {
                    isVisible = true
                }
            }
    }
}
```

### Android Animations
```kotlin
// Standard Animation Durations
object PinItAnimations {
    val Quick = 200.ms
    val Standard = 300.ms
    val Slow = 500.ms
}

// Common Animation Patterns
@Composable
fun FadeInContent(
    isVisible: Boolean,
    content: @Composable () -> Unit
) {
    val alpha by animateFloatAsState(
        targetValue = if (isVisible) 1f else 0f,
        animationSpec = tween(durationMillis = PinItAnimations.Standard)
    )
    
    Box(
        modifier = Modifier.alpha(alpha)
    ) {
        content()
    }
}
```

## Accessibility Guidelines

### iOS Accessibility
```swift
// Accessibility Labels and Hints
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}
```

### Android Accessibility
```kotlin
@Composable
fun AccessibleButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .semantics {
                contentDescription = text
                role = Role.Button
            }
    ) {
        Text(text)
    }
}
```

## Responsive Design

### iOS Responsive Patterns
```swift
// Device-specific layouts
struct ResponsiveLayout<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 768 {
                // iPad layout
                HStack {
                    content
                }
            } else {
                // iPhone layout
                VStack {
                    content
                }
            }
        }
    }
}
```

### Android Responsive Patterns
```kotlin
@Composable
fun ResponsiveLayout(
    content: @Composable () -> Unit
) {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    
    if (screenWidth > 600.dp) {
        // Tablet layout
        Row {
            content()
        }
    } else {
        // Phone layout
        Column {
            content()
        }
    }
}
```

## Dark Mode Support

### iOS Dark Mode
```swift
// Dark mode color definitions
extension Color {
    static let adaptivePrimary = Color.primary
    static let adaptiveSecondary = Color.secondary
    static let adaptiveBackground = Color(UIColor.systemBackground)
    static let adaptiveGroupedBackground = Color(UIColor.systemGroupedBackground)
}
```

### Android Dark Mode
```kotlin
// Dark mode color definitions
object PinItColors {
    val Primary = Color(0xFF3366CC)
    val PrimaryDark = Color(0xFF1E3A8A)
    
    val Background = Color(0xFFFFFFFF)
    val BackgroundDark = Color(0xFF121212)
    
    val Surface = Color(0xFFFFFFFF)
    val SurfaceDark = Color(0xFF1E1E1E)
}
```

## Performance Guidelines

### iOS Performance
- Use `LazyVStack` and `LazyHStack` for large lists
- Implement proper image caching
- Use `@StateObject` for expensive view models
- Minimize view updates with proper state management

### Android Performance
- Use `LazyColumn` and `LazyRow` for large lists
- Implement proper image loading with Coil
- Use `remember` for expensive computations
- Minimize recomposition with proper state management

This UI guide provides comprehensive design standards and component libraries for maintaining consistency across the PinIt application on both iOS and Android platforms.

