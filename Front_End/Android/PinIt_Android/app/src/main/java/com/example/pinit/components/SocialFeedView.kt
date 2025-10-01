package com.example.pinit.components

import android.content.Context
import android.net.Uri
import android.util.Log
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Reply
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.pinit.R
import com.example.pinit.models.EventInteractions
import com.example.pinit.ui.theme.PrimaryColor
import com.example.pinit.ui.theme.SecondaryColor
import com.example.pinit.viewmodels.EventDetailViewModel
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit
import kotlin.random.Random

/**
 * Full screen social feed view for event interactions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SocialFeedView(
    eventId: String,
    viewModel: EventDetailViewModel,
    onClose: () -> Unit
) {
    // Add debug logging for the event ID
    Log.d("SocialFeedView", "Opening SocialFeedView with eventId: $eventId")
    
    // Get state from ViewModel
    val interactions = viewModel.interactions.value
    val isFeedLoading = viewModel.isFeedLoading.value
    val feedErrorMessage = viewModel.feedErrorMessage.value
    val newPostText = viewModel.newPostText.value
    val isPostingComment = viewModel.isPostingComment.value
    
    val context = LocalContext.current
    
    // Effect to load feed when dialog opens - use the eventId parameter
    LaunchedEffect(eventId) {
        Log.d("SocialFeedView", "Loading social feed for eventId: $eventId")
        Log.d("SocialFeedView", "viewModel instance: ${viewModel.hashCode()}")
        viewModel.loadSocialFeed()
    }
    
    // Selected post for showing details
    var selectedPost by remember { mutableStateOf<EventInteractions.Post?>(null) }
    
    // Image selection
    val imageUris = remember { mutableStateListOf<Uri>() }
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        imageUris.clear()
        imageUris.addAll(uris)
    }
    
    Dialog(
        onDismissRequest = onClose,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false
        )
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Event Social Feed") },
                    navigationIcon = {
                        IconButton(onClick = onClose) {
                            Icon(Icons.Default.Close, contentDescription = "Close")
                        }
                    }
                )
            }
        ) { padding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                when {
                    isFeedLoading -> {
                        // Loading state
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(color = PrimaryColor)
                        }
                    }
                    feedErrorMessage != null && interactions?.posts?.isEmpty() == true -> {
                        // Error state
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                Icons.Default.Error,
                                contentDescription = "Error",
                                modifier = Modifier.size(64.dp),
                                tint = Color.Red
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = "Failed to load social feed",
                                style = MaterialTheme.typography.headlineSmall,
                                textAlign = TextAlign.Center
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = feedErrorMessage ?: "Unknown error",
                                style = MaterialTheme.typography.bodyLarge,
                                textAlign = TextAlign.Center
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Button(
                                onClick = { viewModel.loadSocialFeed() },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = PrimaryColor
                                )
                            ) {
                                Icon(Icons.Default.Refresh, contentDescription = "Retry")
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Try Again")
                            }
                        }
                    }
                    else -> {
                        // Content state - Posts list
                        Column(
                            modifier = Modifier.fillMaxSize()
                        ) {
                            // Post creation section at top
                            CreatePostSection(
                                newPostText = newPostText,
                                onNewPostTextChange = { viewModel.newPostText.value = it },
                                onPostClick = { viewModel.addPost() },
                                onImagePickerClick = { imagePickerLauncher.launch("image/*") },
                                selectedImageUris = imageUris,
                                onRemoveImage = { imageUris.remove(it) },
                                isPosting = isPostingComment
                            )
                            
                            // Divider
                            HorizontalDivider(
                                modifier = Modifier.padding(vertical = 8.dp),
                                thickness = 1.dp,
                                color = Color.LightGray.copy(alpha = 0.5f)
                            )
                            
                            // Error message if any
                            if (feedErrorMessage != null) {
                                Text(
                                    text = feedErrorMessage,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color.Red,
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                                )
                            }
                            
                            // Posts list
                            if (interactions != null && interactions.posts.isNotEmpty()) {
                                PostsList(
                                    posts = interactions.posts,
                                    onPostClick = { selectedPost = it },
                                    onLikeClick = { viewModel.likePost(it.id) }
                                )
                            } else {
                                // Empty state
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .weight(1f),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally
                                    ) {
                                        Icon(
                                            Icons.Default.Forum,
                                            contentDescription = "No Posts",
                                            modifier = Modifier.size(64.dp),
                                            tint = Color.Gray.copy(alpha = 0.5f)
                                        )
                                        Spacer(modifier = Modifier.height(16.dp))
                                        Text(
                                            text = "No posts yet.",
                                            style = MaterialTheme.typography.titleMedium,
                                            color = Color.Gray
                                        )
                                        Spacer(modifier = Modifier.height(8.dp))
                                        Text(
                                            text = "Be the first to start the conversation!",
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = Color.Gray,
                                            textAlign = TextAlign.Center
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Show post details dialog if a post is selected
    if (selectedPost != null) {
        PostDetailDialog(
            post = selectedPost!!,
            onDismiss = { selectedPost = null },
            onLike = { 
                viewModel.likePost(selectedPost!!.id)
            },
            onReply = { replyText ->
                viewModel.replyToPost(selectedPost!!.id, replyText)
                selectedPost = null
            }
        )
    }
    
    // Show error toast if there is one
    LaunchedEffect(feedErrorMessage) {
        if (feedErrorMessage != null) {
            Toast.makeText(context, feedErrorMessage, Toast.LENGTH_SHORT).show()
        }
    }
}

/**
 * Section for creating a new post
 */
@Composable
fun CreatePostSection(
    newPostText: String,
    onNewPostTextChange: (String) -> Unit,
    onPostClick: () -> Unit,
    onImagePickerClick: () -> Unit,
    selectedImageUris: List<Uri>,
    onRemoveImage: (Uri) -> Unit,
    isPosting: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Text(
            text = "Share your thoughts",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Text input field
        TextField(
            value = newPostText,
            onValueChange = onNewPostTextChange,
            placeholder = { Text("What's on your mind?") },
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 100.dp),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White,
                disabledContainerColor = Color.White,
                focusedIndicatorColor = PrimaryColor,
                unfocusedIndicatorColor = Color.LightGray
            )
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Selected images grid (if any)
        if (selectedImageUris.isNotEmpty()) {
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                contentPadding = PaddingValues(4.dp)
            ) {
                items(selectedImageUris) { uri ->
                    Box(
                        modifier = Modifier
                            .padding(4.dp)
                            .fillMaxSize()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color.LightGray)
                    ) {
                        Image(
                            painter = painterResource(id = R.drawable.ic_launcher_foreground),
                            contentDescription = "Selected Image",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                        
                        // Remove button
                        IconButton(
                            onClick = { onRemoveImage(uri) },
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .size(24.dp)
                                .background(
                                    color = Color.Black.copy(alpha = 0.5f),
                                    shape = CircleShape
                                )
                        ) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = "Remove Image",
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
        }
        
        // Action buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Image selection button
            IconButton(
                onClick = onImagePickerClick,
                enabled = !isPosting
            ) {
                Icon(
                    Icons.Default.Image,
                    contentDescription = "Add Image",
                    tint = PrimaryColor
                )
            }
            
            // Post button
            Button(
                onClick = onPostClick,
                enabled = newPostText.isNotBlank() && !isPosting,
                colors = ButtonDefaults.buttonColors(
                    containerColor = PrimaryColor
                )
            ) {
                if (isPosting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Posting...")
                } else {
                    Icon(Icons.Default.Send, contentDescription = "Post")
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Post")
                }
            }
        }
    }
}

/**
 * List of posts
 */
@Composable
fun PostsList(
    posts: List<EventInteractions.Post>,
    onPostClick: (EventInteractions.Post) -> Unit,
    onLikeClick: (EventInteractions.Post) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 16.dp)
    ) {
        items(posts) { post ->
            PostItem(
                post = post,
                onClick = { onPostClick(post) },
                onLikeClick = { onLikeClick(post) }
            )
        }
    }
}

/**
 * Single post item
 */
@Composable
fun PostItem(
    post: EventInteractions.Post,
    onClick: () -> Unit,
    onLikeClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.White
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 1.dp
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header with avatar and username
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Avatar
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(PrimaryColor.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = post.username.take(1).uppercase(),
                        color = PrimaryColor,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                Spacer(modifier = Modifier.width(8.dp))
                
                // Username and time
                Column {
                    Text(
                        text = post.username,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Text(
                        text = formatTimeAgo(post.createdAt),
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Post content
            Text(
                text = post.text,
                style = MaterialTheme.typography.bodyLarge
            )
            
            // Post images if any
            if (!post.imageUrls.isNullOrEmpty()) {
                Spacer(modifier = Modifier.height(12.dp))
                
                LazyVerticalGrid(
                    columns = GridCells.Fixed(if (post.imageUrls.size > 1) 2 else 1),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(if (post.imageUrls.size > 1) 200.dp else 300.dp),
                    contentPadding = PaddingValues(4.dp)
                ) {
                    items(post.imageUrls) { imageUrl ->
                        Image(
                            painter = painterResource(id = R.drawable.ic_launcher_foreground),
                            contentDescription = "Post Image",
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(4.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.LightGray),
                            contentScale = ContentScale.Crop
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Actions and stats
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Like button
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .clickable(onClick = onLikeClick)
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Icon(
                        imageVector = if (post.isLikedByCurrentUser) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                        contentDescription = "Like",
                        tint = if (post.isLikedByCurrentUser) Color.Red else Color.Gray,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${post.likes}",
                        style = MaterialTheme.typography.bodySmall,
                        color = if (post.isLikedByCurrentUser) Color.Red else Color.Gray
                    )
                }
                
                // Reply button/indicator
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .clickable(onClick = onClick)
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Reply,
                        contentDescription = "Replies",
                        tint = Color.Gray,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${post.replies.size}",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray
                    )
                }
            }
            
            // Show replies indicator if there are any
            if (post.replies.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                HorizontalDivider(thickness = 1.dp, color = Color.LightGray.copy(alpha = 0.5f))
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "View ${post.replies.size} ${if (post.replies.size == 1) "reply" else "replies"}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = PrimaryColor,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .clickable(onClick = onClick)
                        .padding(4.dp)
                )
            }
        }
    }
}

/**
 * Dialog for post details and replies
 */
@Composable
fun PostDetailDialog(
    post: EventInteractions.Post,
    onDismiss: () -> Unit,
    onLike: () -> Unit,
    onReply: (String) -> Unit
) {
    var replyText by remember { mutableStateOf("") }
    var isSendingReply by remember { mutableStateOf(false) }
    
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        )
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .heightIn(max = 600.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color.White
            )
        ) {
            Column(
                modifier = Modifier.fillMaxWidth()
            ) {
                // Header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Post Details",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                
                HorizontalDivider()
                
                // Scrollable content
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    // Original post
                    PostItem(
                        post = post,
                        onClick = { /* Already in detail view */ },
                        onLikeClick = onLike
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Replies section
                    Text(
                        text = "Replies (${post.replies.size})",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    if (post.replies.isEmpty()) {
                        // No replies yet
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(100.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No replies yet. Be the first to reply!",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.Gray,
                                textAlign = TextAlign.Center
                            )
                        }
                    } else {
                        // List of replies
                        LazyColumn(
                            modifier = Modifier
                                .fillMaxWidth()
                                .weight(1f)
                        ) {
                            items(post.replies) { reply ->
                                ReplyItem(reply = reply)
                            }
                        }
                    }
                }
                
                // Reply input section
                HorizontalDivider()
                
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextField(
                        value = replyText,
                        onValueChange = { replyText = it },
                        placeholder = { Text("Write a reply...") },
                        modifier = Modifier.weight(1f),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.White,
                            unfocusedContainerColor = Color.White,
                            disabledContainerColor = Color.White,
                            focusedIndicatorColor = PrimaryColor,
                            unfocusedIndicatorColor = Color.LightGray
                        ),
                        singleLine = true
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    IconButton(
                        onClick = { 
                            if (replyText.isNotBlank() && !isSendingReply) {
                                isSendingReply = true
                                onReply(replyText)
                                replyText = ""
                                isSendingReply = false
                            }
                        },
                        enabled = replyText.isNotBlank() && !isSendingReply
                    ) {
                        Icon(
                            Icons.Default.Send,
                            contentDescription = "Send Reply",
                            tint = if (replyText.isNotBlank() && !isSendingReply) PrimaryColor else Color.Gray
                        )
                    }
                }
            }
        }
    }
}

/**
 * Display a single reply
 */
@Composable
fun ReplyItem(reply: EventInteractions.Post) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    ) {
        // Avatar
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(PrimaryColor.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = reply.username.take(1).uppercase(),
                style = MaterialTheme.typography.bodySmall,
                color = PrimaryColor,
                fontWeight = FontWeight.Bold
            )
        }
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Column(
            modifier = Modifier
                .weight(1f)
                .background(
                    color = Color.LightGray.copy(alpha = 0.2f),
                    shape = RoundedCornerShape(12.dp)
                )
                .padding(12.dp)
        ) {
            // Username and time
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = reply.username,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                
                Text(
                    text = formatTimeAgo(reply.createdAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
            
            Spacer(modifier = Modifier.height(4.dp))
            
            // Reply content
            Text(
                text = reply.text,
                style = MaterialTheme.typography.bodyMedium
            )
            
            // Reply images if any
            if (!reply.imageUrls.isNullOrEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Image(
                    painter = painterResource(id = R.drawable.ic_launcher_foreground),
                    contentDescription = "Reply Image",
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(150.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color.LightGray),
                    contentScale = ContentScale.Crop
                )
            }
        }
    }
}

/**
 * Format a timestamp to a readable "time ago" string
 */
fun formatTimeAgo(timestamp: String): String {
    try {
        val instant = Instant.parse(timestamp)
        val timeAgo = ZonedDateTime.ofInstant(instant, ZoneId.systemDefault())
        val now = ZonedDateTime.now()
        
        val minutesAgo = ChronoUnit.MINUTES.between(timeAgo, now)
        val hoursAgo = ChronoUnit.HOURS.between(timeAgo, now)
        val daysAgo = ChronoUnit.DAYS.between(timeAgo, now)
        
        return when {
            minutesAgo < 1 -> "Just now"
            minutesAgo < 60 -> "$minutesAgo ${if (minutesAgo == 1L) "minute" else "minutes"} ago"
            hoursAgo < 24 -> "$hoursAgo ${if (hoursAgo == 1L) "hour" else "hours"} ago"
            daysAgo < 30 -> "$daysAgo ${if (daysAgo == 1L) "day" else "days"} ago"
            else -> {
                val formatter = java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy")
                timeAgo.format(formatter)
            }
        }
    } catch (e: Exception) {
        return "Unknown time"
    }
} 