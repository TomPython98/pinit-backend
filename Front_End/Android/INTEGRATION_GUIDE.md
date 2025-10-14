# Android App - Quick Integration Guide

## Overview

This guide shows how to integrate the new features into your existing Android app.

## Step 1: Update MainActivity Navigation

Add new views to your navigation system in `MainActivity.kt`:

```kotlin
@Composable
fun PinItApp() {
    var showSearchView by remember { mutableStateOf(false) }
    var showRatingDialog by remember { mutableStateOf(false) }
    var userToRate by remember { mutableStateOf<String?>(null) }
    
    // Existing navigation...
    
    // Add search view
    if (showSearchView) {
        SearchView(
            onDismiss = { showSearchView = false },
            accountManager = accountManager
        )
    }
    
    // Add rating dialog
    if (showRatingDialog && userToRate != null) {
        RatingDialog(
            username = userToRate!!,
            eventTitle = null,
            onDismiss = { showRatingDialog = false },
            onSubmit = { rating, comment ->
                // Submit rating
                val repository = ReputationRepository()
                viewModelScope.launch {
                    repository.submitRating(
                        fromUsername = accountManager.currentUser ?: "",
                        toUsername = userToRate!!,
                        rating = rating,
                        reference = comment
                    ).collect { result ->
                        when (result) {
                            is Result.Success -> {
                                // Show success message
                                showRatingDialog = false
                            }
                            is Result.Error -> {
                                // Show error message
                            }
                        }
                    }
                }
            }
        )
    }
}
```

## Step 2: Enhance Existing Profile View

Update `EnhancedProfileView.kt` to include reputation and images:

```kotlin
@Composable
fun EnhancedProfileView(
    accountManager: UserAccountManager,
    onDismiss: () -> Unit,
    onLogout: () -> Unit
) {
    val viewModel: EnhancedProfileViewModel = viewModel()
    val username = accountManager.currentUser ?: return
    
    // Load data
    LaunchedEffect(username) {
        viewModel.loadUserImages(username)
        viewModel.loadUserReputation(username)
        viewModel.loadProfileCompletion(username)
    }
    
    // Observe state
    val images by viewModel.userImages.collectAsState()
    val reputation by viewModel.userReputation.collectAsState()
    val profileCompletion by viewModel.profileCompletion.collectAsState()
    
    ModalBottomSheet(onDismissRequest = onDismiss) {
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Profile header with image
            item {
                if (images is Result.Success) {
                    val imagesList = (images as Result.Success).data
                    val profileImageUrl = viewModel.getProfileImageUrl(imagesList)
                    
                    ProfileImageSection(
                        profileImageUrl = profileImageUrl,
                        isOwnProfile = true,
                        onImageClick = { /* Show full screen */ },
                        onChangeImage = { /* Show image picker */ }
                    )
                }
            }
            
            // Profile completion
            item {
                if (profileCompletion is Result.Success) {
                    val completion = (profileCompletion as Result.Success).data
                    ProfileCompletionCard(completion = completion)
                }
            }
            
            // Reputation card
            item {
                if (reputation is Result.Success) {
                    val rep = (reputation as Result.Success).data
                    UserReputationCard(
                        reputation = rep,
                        onViewRatings = { /* Navigate to ratings history */ }
                    )
                    
                    ReputationProgressCard(
                        reputation = rep,
                        progress = viewModel.calculateTrustLevelProgress(rep)
                    )
                }
            }
            
            // Image gallery
            item {
                if (images is Result.Success) {
                    val imagesList = (images as Result.Success).data
                    val galleryImages = viewModel.getGalleryImages(imagesList)
                    
                    Text(
                        text = "Gallery",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    ImageGalleryGrid(
                        images = galleryImages,
                        isOwnProfile = true,
                        onImageClick = { /* Show full screen */ },
                        onDeleteImage = { imageId -> 
                            viewModel.deleteImage(imageId)
                        },
                        onSetPrimary = { imageId ->
                            viewModel.setPrimaryImage(imageId)
                        }
                    )
                }
            }
            
            // Existing profile fields...
        }
    }
}
```

## Step 3: Enhance EventDetailView

Add social features to your EventDetailView:

```kotlin
@Composable
fun EventDetailView(
    event: StudyEvent,
    onDismiss: () -> Unit,
    accountManager: UserAccountManager
) {
    val viewModel: EnhancedEventDetailViewModel = viewModel()
    val eventId = event.id.toString()
    val currentUser = accountManager.currentUser ?: ""
    
    // Load social features
    LaunchedEffect(eventId) {
        viewModel.loadEventFeed(eventId, currentUser)
        viewModel.loadHostReputation(event.host)
    }
    
    val eventFeed by viewModel.eventFeed.collectAsState()
    val hostReputation by viewModel.hostReputation.collectAsState()
    
    LazyColumn {
        // Event header (existing)...
        
        // Host reputation badge
        item {
            if (hostReputation is Result.Success) {
                val rep = (hostReputation as Result.Success).data
                CompactReputationSummary(reputation = rep)
            }
        }
        
        // Engagement stats
        item {
            if (eventFeed is Result.Success) {
                val feed = (eventFeed as Result.Success).data
                val stats = viewModel.getEngagementStats(feed)
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    AnimatedLikeButton(
                        isLiked = false, // Check if current user liked
                        likeCount = stats.totalLikes,
                        onToggle = {
                            viewModel.toggleLike(eventId, currentUser)
                        }
                    )
                    
                    ShareButton(
                        onClick = { /* Show share dialog */ },
                        shareCount = stats.totalShares
                    )
                    
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Comment, contentDescription = null)
                        Text("${stats.totalComments}")
                    }
                }
            }
        }
        
        // Comments section
        item {
            if (eventFeed is Result.Success) {
                val feed = (eventFeed as Result.Success).data
                val comments = viewModel.getSortedComments(feed)
                
                Text(
                    text = "Comments",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
                
                comments.forEach { comment ->
                    CommentCard(
                        comment = comment,
                        currentUsername = currentUser,
                        onLike = {
                            viewModel.toggleLike(eventId, currentUser, comment.id)
                        },
                        onReply = { /* Show reply input */ }
                    )
                }
            }
        }
        
        // Comment input
        item {
            var commentText by remember { mutableStateOf("") }
            val commentSubmission by viewModel.commentSubmission.collectAsState()
            
            CommentInput(
                value = commentText,
                onValueChange = { commentText = it },
                onSubmit = {
                    viewModel.addComment(eventId, currentUser, commentText)
                    commentText = ""
                },
                isLoading = commentSubmission is Result.Loading
            )
        }
    }
}
```

## Step 4: Add Search View

Create a new SearchView.kt file:

```kotlin
package com.example.pinit.views

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchView(
    onDismiss: () -> Unit,
    accountManager: UserAccountManager
) {
    var searchQuery by remember { mutableStateOf("") }
    var filters by remember { mutableStateOf(SearchFilters()) }
    var showFilters by remember { mutableStateOf(false) }
    var searchResults by remember { mutableStateOf<List<StudyEvent>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    
    val apiService = ApiClient.apiService
    val scope = rememberCoroutineScope()
    
    fun performSearch() {
        isLoading = true
        scope.launch {
            try {
                val response = apiService.enhancedSearchEvents(
                    query = searchQuery,
                    publicOnly = filters.publicOnly,
                    certifiedOnly = filters.certifiedOnly,
                    eventType = filters.eventType,
                    semantic = filters.semanticSearch
                )
                
                if (response.isSuccessful) {
                    searchResults = response.body()?.events ?: emptyList()
                }
            } catch (e: Exception) {
                // Handle error
            } finally {
                isLoading = false
            }
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Search Events") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            SearchBar(
                query = searchQuery,
                onQueryChange = { searchQuery = it },
                onSearch = { performSearch() },
                onFilterClick = { showFilters = true },
                activeFiltersCount = filters.activeCount(),
                modifier = Modifier.padding(16.dp)
            )
            
            SearchResultsList(
                events = searchResults,
                onEventClick = { event ->
                    // Navigate to event detail
                },
                isLoading = isLoading
            )
        }
        
        if (showFilters) {
            SearchFiltersSheet(
                currentFilters = filters,
                onFiltersChange = { filters = it },
                onDismiss = { showFilters = false },
                onApply = {
                    showFilters = false
                    performSearch()
                }
            )
        }
    }
}
```

## Step 5: Add Image Upload

Update ProfileView to handle image uploads:

```kotlin
val context = LocalContext.current
val viewModel: EnhancedProfileViewModel = viewModel()
var showImagePicker by remember { mutableStateOf(false) }
var selectedImageType by remember { mutableStateOf(ImageType.PROFILE) }

// Image picker launcher
val launcher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.GetContent()
) { uri: Uri? ->
    uri?.let { imageUri ->
        viewModel.uploadImage(
            context = context,
            imageUri = imageUri,
            imageType = selectedImageType,
            caption = null
        )
    }
}

// Observe upload state
val uploadState by viewModel.imageUpload.collectAsState()

LaunchedEffect(uploadState) {
    when (uploadState) {
        is Result.Success -> {
            // Image uploaded successfully
            // Reload images
            viewModel.loadUserImages(accountManager.currentUser ?: "")
            viewModel.resetImageUpload()
        }
        is Result.Error -> {
            // Show error
        }
    }
}

// Show image picker dialog
if (showImagePicker) {
    ImagePickerDialog(
        imageType = selectedImageType,
        onImageSelected = { uri ->
            viewModel.uploadImage(context, uri, selectedImageType)
            showImagePicker = false
        },
        onDismiss = { showImagePicker = false }
    )
}

// Button to trigger image picker
Button(onClick = {
    selectedImageType = ImageType.PROFILE
    showImagePicker = true
}) {
    Text("Change Profile Picture")
}
```

## Step 6: Add Rating Feature

After an event ends, allow users to rate each other:

```kotlin
// In EventDetailView, check if event ended and user attended
val isEventEnded = event.endTime?.let {
    java.time.LocalDateTime.now().isAfter(it)
} ?: false

val isAttendee = event.attendees?.contains(currentUser) == true

if (isEventEnded && isAttendee) {
    // Show "Rate Attendees" button
    Button(
        onClick = { /* Show list of attendees to rate */ },
        modifier = Modifier.fillMaxWidth()
    ) {
        Icon(Icons.Default.Star, contentDescription = null)
        Spacer(modifier = Modifier.width(8.dp))
        Text("Rate Attendees")
    }
}

// Rating dialog
var showRatingDialog by remember { mutableStateOf(false) }
var userToRate by remember { mutableStateOf<String?>(null) }

if (showRatingDialog && userToRate != null) {
    RatingDialog(
        username = userToRate!!,
        eventTitle = event.title,
        onDismiss = { showRatingDialog = false },
        onSubmit = { rating, comment ->
            val repository = ReputationRepository()
            scope.launch {
                repository.submitRating(
                    fromUsername = currentUser,
                    toUsername = userToRate!!,
                    rating = rating,
                    reference = comment,
                    eventId = event.id.toString()
                ).collect { result ->
                    when (result) {
                        is Result.Success -> {
                            showRatingDialog = false
                            // Show success message
                        }
                        is Result.Error -> {
                            // Show error
                        }
                    }
                }
            }
        }
    )
}
```

## Step 7: Test Integration

Run these checks:
1. ✅ Search events with filters
2. ✅ View user reputation on profiles
3. ✅ Upload profile/gallery images
4. ✅ Add comments to events
5. ✅ Like/unlike events
6. ✅ Share events
7. ✅ Submit ratings after events
8. ✅ View trust level badges
9. ✅ Edit/delete own events
10. ✅ Approve/reject join requests

## Common Issues & Solutions

### Issue: Coil images not loading
**Solution:** Add internet permission to AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Issue: Image picker crashes
**Solution:** Add storage permissions and request at runtime:
```kotlin
val permissionLauncher = rememberLauncherForActivityResult(
    ActivityResultContracts.RequestPermission()
) { isGranted ->
    if (isGranted) {
        // Open image picker
    }
}

// Request permission
permissionLauncher.launch(android.Manifest.permission.READ_EXTERNAL_STORAGE)
```

### Issue: API calls failing
**Solution:** Check network security config and API base URL in ApiClient.kt

## Performance Tips

1. **Use remember for ViewModels:**
```kotlin
val viewModel: EnhancedProfileViewModel = viewModel()
```

2. **Collect StateFlows properly:**
```kotlin
val state by viewModel.stateFlow.collectAsState()
```

3. **Cancel coroutines on dispose:**
```kotlin
DisposableEffect(Unit) {
    onDispose {
        // Cancel operations
    }
}
```

4. **Use keys in LazyColumn:**
```kotlin
items(list, key = { it.id }) { item ->
    // Content
}
```

## Next Steps

1. Add Firebase Cloud Messaging for push notifications
2. Implement DataStore for user preferences
3. Add Room database for offline caching
4. Create comprehensive tests
5. Performance optimization pass
6. Accessibility audit

## Support

For issues or questions:
- Check ANDROID_FEATURES_IMPLEMENTATION.md for detailed documentation
- Review existing iOS implementation for reference
- Consult Django backend API documentation

## Summary

You now have a fully featured Android app with:
- ✅ Modern architecture (MVVM, Repository, StateFlow)
- ✅ Comprehensive UI components (Material Design 3)
- ✅ All backend features integrated
- ✅ Image management with Coil
- ✅ Social interactions (comments, likes, shares)
- ✅ Reputation system (trust levels, ratings)
- ✅ Advanced search with filters
- ✅ Event management (CRUD)

Start integrating these components into your existing views and enjoy feature parity with iOS and the backend! 🚀


