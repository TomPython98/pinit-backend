# Android UI Guide

## Design System

### Material 3 Implementation
The app follows Google's Material 3 design system with custom theming to match the PinIt brand identity.

### Color Palette

#### Primary Colors
```kotlin
val BrandPrimary = Color(0xFF4F46E5)    // Indigo primary
val BrandSecondary = Color(0xFF3B82F6)  // Royal blue
val BrandAccent = Color(0xFFEC4899)     // Pink accent
val BrandWarning = Color(0xFFF59E0B)    // Amber warning
val BrandSuccess = Color(0xFF10B981)    // Emerald success
```

#### Background Colors
```kotlin
val BgSurface = Color(0xFFF8FAFF)       // Light background
val BgCard = Color(0xFFFFFFFF)          // White cards
val BgAccent = Color(0xFFF0F2FF)        // Accented background
val BgSecondary = Color(0xFFF2F5FA)     // Secondary background
```

#### Text Colors
```kotlin
val TextPrimary = Color(0xFF0F172A)     // Near black
val TextSecondary = Color(0xFF475569)   // Slate 600
val TextLight = Color(0xFFFFFFFF)       // White text
val TextMuted = Color(0xFF94A3B8)       // Slate 400
```

#### Social Colors
```kotlin
val SocialDark = Color(0xFF142A50)      // Dark blue
val SocialMedium = Color(0xFF285087)    // Medium blue
val SocialPrimary = Color(0xFF4682D2)   // Primary blue
val SocialAccent = Color(0xFF82C3EB)    // Accent blue
val SocialLight = Color(0xFFBEE1F5)     // Light blue
```

### Typography

#### Custom Typography Scale
```kotlin
val Typography = Typography(
    displayLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 57.sp,
        lineHeight = 64.sp,
        letterSpacing = (-0.25).sp,
        fontWeight = FontWeight.Normal
    ),
    headlineLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 0.sp,
        fontWeight = FontWeight.Bold
    ),
    titleLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 22.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.sp,
        fontWeight = FontWeight.Bold
    ),
    bodyLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp,
        fontWeight = FontWeight.Normal
    ),
    bodyMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp,
        fontWeight = FontWeight.Normal
    ),
    labelLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp,
        fontWeight = FontWeight.Medium
    )
)
```

### Spacing System

#### Standard Spacing Units
```kotlin
// 4dp base unit system
val spacing4 = 4.dp
val spacing8 = 8.dp
val spacing12 = 12.dp
val spacing16 = 16.dp
val spacing20 = 20.dp
val spacing24 = 24.dp
val spacing32 = 32.dp
val spacing40 = 40.dp
val spacing48 = 48.dp
```

#### Component Spacing
```kotlin
// Card padding
val cardPadding = 16.dp

// Screen padding
val screenPadding = 16.dp

// Section spacing
val sectionSpacing = 24.dp

// Item spacing
val itemSpacing = 8.dp
```

### Shape System

#### Corner Radius
```kotlin
val cornerRadius4 = 4.dp
val cornerRadius8 = 8.dp
val cornerRadius12 = 12.dp
val cornerRadius16 = 16.dp
val cornerRadius20 = 20.dp
val cornerRadius24 = 24.dp
```

#### Component Shapes
```kotlin
// Card shape
val cardShape = RoundedCornerShape(cornerRadius16)

// Button shape
val buttonShape = RoundedCornerShape(cornerRadius12)

// Input field shape
val inputShape = RoundedCornerShape(cornerRadius8)

// Chip shape
val chipShape = RoundedCornerShape(cornerRadius20)
```

## Reusable Components

### 1. PinItCard
```kotlin
@Composable
fun PinItCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = modifier
            .clickable { onClick?.invoke() }
            .shadow(
                elevation = 8.dp,
                spotColor = CardShadow,
                shape = RoundedCornerShape(16.dp)
            ),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = BgCard)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}
```

### 2. PinItButton
```kotlin
@Composable
fun PinItButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    variant: ButtonVariant = ButtonVariant.Primary
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(
            containerColor = when (variant) {
                ButtonVariant.Primary -> BrandPrimary
                ButtonVariant.Secondary -> BrandSecondary
                ButtonVariant.Accent -> BrandAccent
            }
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Medium,
            color = Color.White
        )
    }
}

enum class ButtonVariant {
    Primary, Secondary, Accent
}
```

### 3. PinItTextField
```kotlin
@Composable
fun PinItTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorMessage: String? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            label = { Text(label) },
            isError = isError,
            leadingIcon = leadingIcon,
            trailingIcon = trailingIcon,
            keyboardOptions = keyboardOptions,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = BrandPrimary,
                unfocusedBorderColor = Divider,
                errorBorderColor = Color.Red
            ),
            shape = RoundedCornerShape(8.dp)
        )
        
        if (isError && errorMessage != null) {
            Text(
                text = errorMessage,
                color = Color.Red,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(start = 16.dp, top = 4.dp)
            )
        }
    }
}
```

### 4. PinItChip
```kotlin
@Composable
fun PinItChip(
    text: String,
    selected: Boolean = false,
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    FilterChip(
        onClick = onClick,
        label = { Text(text) },
        selected = selected,
        modifier = modifier,
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = BrandPrimary,
            selectedLabelColor = Color.White,
            containerColor = BgAccent,
            labelColor = TextPrimary
        ),
        shape = RoundedCornerShape(20.dp)
    )
}
```

### 5. PinItIconButton
```kotlin
@Composable
fun PinItIconButton(
    onClick: () -> Unit,
    icon: ImageVector,
    contentDescription: String,
    modifier: Modifier = Modifier,
    tint: Color = BrandPrimary
) {
    IconButton(
        onClick = onClick,
        modifier = modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(BgCard)
            .shadow(
                elevation = 8.dp,
                shape = CircleShape,
                spotColor = CardShadow
            )
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = tint,
            modifier = Modifier.size(20.dp)
        )
    }
}
```

## Layout Components

### 1. SectionHeader
```kotlin
@Composable
fun SectionHeader(
    title: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleLarge,
        fontWeight = FontWeight.Bold,
        color = TextPrimary,
        modifier = modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
}
```

### 2. PinItDivider
```kotlin
@Composable
fun PinItDivider(
    modifier: Modifier = Modifier
) {
    Divider(
        color = Divider,
        thickness = 1.dp,
        modifier = modifier.padding(horizontal = 16.dp)
    )
}
```

### 3. LoadingIndicator
```kotlin
@Composable
fun LoadingIndicator(
    modifier: Modifier = Modifier,
    color: Color = BrandPrimary
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(
            color = color,
            strokeWidth = 3.dp
        )
    }
}
```

## Event Components

### 1. EventCard
```kotlin
@Composable
fun EventCard(
    event: StudyEventMap,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    PinItCard(
        modifier = modifier.clickable { onClick() },
        onClick = onClick
    ) {
        Column {
            // Event header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = event.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary,
                    modifier = Modifier.weight(1f)
                )
                
                EventTypeChip(eventType = event.eventType)
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Event details
            Text(
                text = event.description ?: "",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Event metadata
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = "Time",
                        tint = TextMuted,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = event.time.format(DateTimeFormatter.ofPattern("MMM dd, HH:mm")),
                        style = MaterialTheme.typography.bodySmall,
                        color = TextMuted
                    )
                }
                
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.People,
                        contentDescription = "Attendees",
                        tint = TextMuted,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${event.attendees}",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextMuted
                    )
                }
            }
        }
    }
}
```

### 2. EventTypeChip
```kotlin
@Composable
fun EventTypeChip(
    eventType: EventType?,
    modifier: Modifier = Modifier
) {
    val (backgroundColor, textColor) = when (eventType) {
        EventType.STUDY -> BrandPrimary to Color.White
        EventType.PARTY -> BrandAccent to Color.White
        EventType.BUSINESS -> BrandSecondary to Color.White
        EventType.CULTURAL -> BrandWarning to Color.White
        EventType.ACADEMIC -> BrandSuccess to Color.White
        else -> BgAccent to TextPrimary
    }
    
    Box(
        modifier = modifier
            .background(
                color = backgroundColor,
                shape = RoundedCornerShape(12.dp)
            )
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = eventType?.displayName ?: "Other",
            style = MaterialTheme.typography.labelSmall,
            color = textColor,
            fontWeight = FontWeight.Medium
        )
    }
}
```

## Profile Components

### 1. ProfileHeader
```kotlin
@Composable
fun ProfileHeader(
    profile: UserProfile,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Profile picture
        Box(
            modifier = Modifier
                .size(60.dp)
                .clip(CircleShape)
                .background(BrandPrimary)
        ) {
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = "Profile",
                tint = Color.White,
                modifier = Modifier
                    .size(30.dp)
                    .align(Alignment.Center)
            )
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        // Profile info
        Column {
            Text(
                text = profile.fullName.ifEmpty { profile.username },
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            
            if (profile.university.isNotEmpty()) {
                Text(
                    text = profile.university,
                    style = MaterialTheme.typography.bodyMedium,
                    color = TextSecondary
                )
            }
            
            if (profile.degree.isNotEmpty()) {
                Text(
                    text = profile.degree,
                    style = MaterialTheme.typography.bodySmall,
                    color = TextMuted
                )
            }
        }
    }
}
```

### 2. InterestChip
```kotlin
@Composable
fun InterestChip(
    interest: String,
    selected: Boolean = false,
    onClick: () -> Unit = {},
    onRemove: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .background(
                color = if (selected) BrandPrimary else BgAccent,
                shape = RoundedCornerShape(20.dp)
            )
            .clickable { onClick() }
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = interest,
            style = MaterialTheme.typography.bodySmall,
            color = if (selected) Color.White else TextPrimary,
            fontWeight = FontWeight.Medium
        )
        
        if (onRemove != null) {
            Spacer(modifier = Modifier.width(4.dp))
            IconButton(
                onClick = onRemove,
                modifier = Modifier.size(16.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Remove",
                    tint = if (selected) Color.White else TextMuted,
                    modifier = Modifier.size(12.dp)
                )
            }
        }
    }
}
```

## Map Components

### 1. MapContainer
```kotlin
@Composable
fun MapContainer(
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(BgAccent)
    ) {
        content()
    }
}
```

### 2. MapMarker
```kotlin
@Composable
fun MapMarker(
    event: StudyEventMap,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(BrandPrimary)
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = Icons.Default.Place,
            contentDescription = "Event Location",
            tint = Color.White,
            modifier = Modifier.size(20.dp)
        )
    }
}
```

## Animation Guidelines

### 1. Standard Animations
```kotlin
// Fade in animation
val alpha by animateFloatAsState(
    targetValue = if (isVisible) 1f else 0f,
    animationSpec = tween(300)
)

// Scale animation
val scale by animateFloatAsState(
    targetValue = if (isPressed) 0.95f else 1f,
    animationSpec = tween(100)
)
```

### 2. Transition Animations
```kotlin
// Slide transition
val slideOffset by animateDpAsState(
    targetValue = if (isVisible) 0.dp else 300.dp,
    animationSpec = tween(300, easing = EaseInOut)
)
```

## Accessibility Guidelines

### 1. Content Descriptions
```kotlin
Icon(
    imageVector = Icons.Default.Person,
    contentDescription = "User profile picture"
)
```

### 2. Semantic Labels
```kotlin
Text(
    text = "Event title",
    modifier = Modifier.semantics {
        contentDescription = "Event: ${event.title}"
    }
)
```

### 3. Focus Management
```kotlin
TextField(
    value = text,
    onValueChange = { text = it },
    modifier = Modifier.focusRequester(focusRequester)
)
```

## Dark Mode Support

### 1. Color Scheme
```kotlin
@Composable
fun PinItTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
```

### 2. Adaptive Colors
```kotlin
val surfaceColor = if (isDarkTheme) Color(0xFF1A1C1E) else Color.White
val textColor = if (isDarkTheme) Color.White else Color.Black
```

## Performance Guidelines

### 1. Lazy Loading
```kotlin
LazyColumn {
    items(events) { event ->
        EventCard(event = event)
    }
}
```

### 2. State Hoisting
```kotlin
@Composable
fun EventList(
    events: List<StudyEventMap>,
    onEventClick: (StudyEventMap) -> Unit
) {
    LazyColumn {
        items(events) { event ->
            EventCard(
                event = event,
                onClick = { onEventClick(event) }
            )
        }
    }
}
```

### 3. Memoization
```kotlin
val formattedTime = remember(event.time) {
    event.time.format(DateTimeFormatter.ofPattern("MMM dd, HH:mm"))
}
```

This UI guide provides a comprehensive foundation for building consistent, accessible, and performant user interfaces in the PinIt Android app.

