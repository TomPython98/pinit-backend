package com.example.pinit.views

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.PrimaryColor

@Composable
fun LoginView(
    accountManager: UserAccountManager,
    onLoginSuccess: () -> Unit,
    onRegisterClick: () -> Unit
) {
    // State for form fields
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isLoggingIn by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var debugInfo by remember { mutableStateOf("") }
    
    // Use the connection error from the account manager
    val connectionError = accountManager.connectionErrorMessage
    val serverStatus = accountManager.serverStatus

    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .align(Alignment.Center),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // App logo and title
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(PrimaryColor)
            ) {
                Text(
                    "PinIt",
                    style = TextStyle(
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 24.sp
                    )
                )
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Server status indicator
            if (connectionError != null) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = Color.Red.copy(alpha = 0.1f)
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Error,
                            contentDescription = "Connection Error",
                            tint = Color.Red,
                            modifier = Modifier.size(32.dp)
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = "Connection Error",
                            fontWeight = FontWeight.Bold,
                            color = Color.Red
                        )
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        Text(
                            text = connectionError,
                            textAlign = TextAlign.Center,
                            color = Color.DarkGray
                        )
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            Button(
                                onClick = { accountManager.pingAllServers() },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = Color.Red.copy(alpha = 0.8f)
                                )
                            ) {
                                Text("Retry Connection")
                            }
                            
                            // Manual connection test button
                            Button(
                                onClick = { 
                                    debugInfo = "Starting connection tests...\n"
                                    accountManager.testConnectionsForUI { results ->
                                        debugInfo = results
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = Color.Gray
                                )
                            ) {
                                Text("Test URLs")
                            }
                        }
                    }
                }
            } else {
                // Server status (when connected or checking)
                Text(
                    text = serverStatus,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (serverStatus.contains("Connected")) 
                              Color.Green else Color.Gray,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
            }
            
            // Debug info (if any)
            if (debugInfo.isNotEmpty()) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = Color.Gray.copy(alpha = 0.1f)
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(8.dp)
                    ) {
                        Text(
                            text = "Debug Info:",
                            fontWeight = FontWeight.Bold,
                            color = Color.DarkGray
                        )
                        
                        Text(
                            text = debugInfo,
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.DarkGray
                        )
                    }
                }
            }
            
            // Username Field
            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                label = { Text("Username") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "Username Icon"
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Next
                )
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Password Field
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = "Password Icon"
                    )
                },
                visualTransformation = PasswordVisualTransformation(),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done
                )
            )
            
            // Error message (if any)
            if (errorMessage != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = errorMessage!!,
                    color = Color.Red,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Login Button
            Button(
                onClick = {
                    isLoggingIn = true
                    errorMessage = null
                    
                    accountManager.login(username, password) { success, message ->
                        isLoggingIn = false
                        if (success) {
                            onLoginSuccess()
                        } else {
                            errorMessage = message
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                enabled = !isLoggingIn && username.isNotBlank() && password.isNotBlank()
            ) {
                if (isLoggingIn) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Login")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Register button
            TextButton(
                onClick = { onRegisterClick() },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Don't have an account? Register")
            }
            
            // Version info
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = "Android App Version: 1.0",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray
            )
        }
    }
} 