package com.example.pinit.utils

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * Utility class for making API requests to the Django backend
 */
object JsonUtils {
    private const val TAG = "JsonUtils"
    private const val API_BASE_URL = "https://pinit-backend-production.up.railway.app/api"

    /**
     * Make a request to the API
     * 
     * @param endpoint The API endpoint to call (without the base URL and leading slash)
     * @param method The HTTP method to use (GET, POST, PUT, DELETE)
     * @param requestBody The request body as a JSONObject (for POST, PUT)
     * @param onSuccess Callback for successful API calls
     * @param onError Callback for API errors
     */
    suspend fun makeApiRequest(
        endpoint: String,
        method: String = "GET",
        requestBody: JSONObject? = null,
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        withContext(Dispatchers.IO) {
            try {
                val fullUrl = URL("$API_BASE_URL/$endpoint")
                Log.d(TAG, "📡 Making $method request to: $fullUrl")
                
                val connection = fullUrl.openConnection() as HttpURLConnection
                connection.requestMethod = method
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                
                if (method == "POST" || method == "PUT") {
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    
                    // Write request body if provided
                    if (requestBody != null) {
                        val outputStream = connection.outputStream
                        outputStream.write(requestBody.toString().toByteArray())
                        outputStream.close()
                        Log.d(TAG, "📦 Sent payload: $requestBody")
                    }
                }
                
                val responseCode = connection.responseCode
                Log.d(TAG, "📥 HTTP Response code: $responseCode")
                
                if (responseCode in 200..299) {
                    // Success response
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    Log.d(TAG, "📄 Response: $response")
                    
                    withContext(Dispatchers.Main) {
                        onSuccess(response)
                    }
                } else {
                    // Error response
                    val errorMessage = try {
                        connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                    } catch (e: Exception) {
                        "Error reading error response: ${e.message}"
                    }
                    
                    Log.e(TAG, "❌ API Error: $responseCode - $errorMessage")
                    
                    withContext(Dispatchers.Main) {
                        onError("API Error: $responseCode - $errorMessage")
                    }
                }
            } catch (e: IOException) {
                Log.e(TAG, "❌ Network error: ${e.message}")
                withContext(Dispatchers.Main) {
                    onError("Network error: ${e.message}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Unexpected error: ${e.message}")
                withContext(Dispatchers.Main) {
                    onError("Unexpected error: ${e.message}")
                }
            }
        }
    }
} 