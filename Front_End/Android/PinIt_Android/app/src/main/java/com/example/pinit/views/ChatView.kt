package com.example.pinit.views

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.pinit.models.ChatManager
import com.example.pinit.models.ChatMessage
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.*
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatView(
    accountManager: UserAccountManager,
    chatManager: ChatManager,
    friendUsername: String,
    onDismiss: () -> Unit
) {
    val currentUser = accountManager.currentUser ?: "Anonymous"
    var messageText by remember { mutableStateOf("") }
    var isSending by remember { mutableStateOf(false) }
    val messages = remember { derivedStateOf { chatManager.getMessages(currentUser, friendUsername) } }
    val listState = rememberLazyListState()
    
    // Social gradient for background
    val socialGradient = Brush.verticalGradient(
        colors = listOf(SocialLight, SocialAccent)
    )
    
    // Connect to chat when view appears
    LaunchedEffect(Unit) {
        // In Swift, this would be chatManager.connect(sender, receiver)
        // We're using a different model in our Kotlin app
        // This could be implemented with a WebSocket in a real app
    }
    
    // Scroll to bottom when new messages are added
    LaunchedEffect(messages.value.size) {
        if (messages.value.isNotEmpty()) {
            delay(100) // Small delay to ensure list is updated
            listState.animateScrollToItem(messages.value.size - 1)
        }
    }
    
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = Color.Transparent
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(socialGradient)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            ) {
                // Header view with rounded style
                Text(
                    text = "💬 Chat with $friendUsername",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SocialDark, shape = RoundedCornerShape(bottomStart = 25.dp, bottomEnd = 25.dp))
                        .padding(vertical = 16.dp)
                )
                
                // Chat messages
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                ) {
                    if (messages.value.isEmpty()) {
                        EmptyChat()
                    } else {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            state = listState,
                            contentPadding = PaddingValues(vertical = 8.dp)
                        ) {
                            items(messages.value) { message ->
                                if (message.sender == "📅") {
                                    // Date/system message in center
                                    Text(
                                        text = message.message,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.Gray,
                                        textAlign = TextAlign.Center,
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 8.dp)
                                    )
                                } else {
                                    // Regular chat bubble
                                    ChatBubble(
                                        message = message,
                                        isCurrentUser = message.sender == currentUser
                                    )
                                }
                            }
                        }
                    }
                }
                
                // Message input - styled with white background
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .background(
                            color = Color.White.copy(alpha = 0.85f),
                            shape = RoundedCornerShape(15.dp)
                        )
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextField(
                        value = messageText,
                        onValueChange = { messageText = it },
                        placeholder = { Text("Type a message...") },
                        modifier = Modifier
                            .weight(1f)
                            .padding(end = 8.dp),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.Transparent,
                            unfocusedContainerColor = Color.Transparent,
                            focusedIndicatorColor = Color.Transparent,
                            unfocusedIndicatorColor = Color.Transparent
                        ),
                        shape = RoundedCornerShape(24.dp)
                    )
                    
                    // Send button
                    Button(
                        onClick = { sendMessage(messageText, chatManager, currentUser, friendUsername) { messageText = ""; isSending = false } },
                        modifier = Modifier.padding(start = 8.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (isSending) Color.Gray else SocialPrimary
                        ),
                        enabled = !isSending && messageText.trim().isNotEmpty()
                    ) {
                        Text("Send")
                    }
                }
            }
        }
    }
}

private fun sendMessage(
    message: String, 
    chatManager: ChatManager, 
    sender: String, 
    receiver: String,
    onSent: () -> Unit
) {
    val messageToSend = message.trim()
    if (messageToSend.isNotEmpty()) {
        chatManager.sendMessage(
            to = receiver,
            sender = sender,
            message = messageToSend
        )
        onSent()
    }
}

@Composable
fun ChatBubble(
    message: ChatMessage,
    isCurrentUser: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalAlignment = if (isCurrentUser) Alignment.End else Alignment.Start
    ) {
        // Sender name
        Text(
            text = message.sender,
            style = MaterialTheme.typography.bodySmall,
            color = TextMuted,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
        )
        
        // Message bubble
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = if (isCurrentUser) Arrangement.End else Arrangement.Start
        ) {
            if (!isCurrentUser) {
                Spacer(modifier = Modifier.width(50.dp))
            }
            
            Box(
                modifier = Modifier
                    .widthIn(max = 260.dp)
                    .clip(
                        RoundedCornerShape(
                            topStart = 12.dp,
                            topEnd = 12.dp,
                            bottomStart = if (isCurrentUser) 12.dp else 4.dp,
                            bottomEnd = if (isCurrentUser) 4.dp else 12.dp
                        )
                    )
                    .background(
                        color = if (isCurrentUser) SocialPrimary else Color.White.copy(alpha = 0.85f)
                    )
                    .padding(vertical = 8.dp, horizontal = 12.dp)
            ) {
                Text(
                    text = message.message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (isCurrentUser) Color.White else TextPrimary
                )
            }
            
            if (isCurrentUser) {
                Spacer(modifier = Modifier.width(50.dp))
            }
        }
        
        // Time stamp (would be populated with actual time in a real app)
        Text(
            text = "Just now",
            style = MaterialTheme.typography.bodySmall,
            color = TextMuted,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
        )
    }
}

@Composable
fun EmptyChat() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "No messages yet",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Start the conversation by sending a message!",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.7f),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 32.dp)
            )
        }
    }
} 