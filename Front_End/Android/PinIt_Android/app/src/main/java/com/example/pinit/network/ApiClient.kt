package com.example.pinit.network

import com.example.pinit.models.UserAccountManager
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import android.util.Log

/**
 * API Client for setting up Retrofit
 */
object ApiClient {
    // Base URL of your Django backend
    private const val BASE_URL = "https://pinit-backend-production.up.railway.app/api/"  // Production server
    
    // Reference to UserAccountManager for getting logged-in user
    private var userAccountManager: UserAccountManager? = null
    
    // Create OkHttp client with logging
    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        })
        .addInterceptor { chain ->
            val request = chain.request()
            val url = request.url.toString()
            
            // Special debug logging for get_study_events API calls with techuser1
            if (url.contains("get_study_events") && url.contains("techuser1")) {
                Log.d("ApiClient", "🌐 NETWORK DEBUG: API Request for techuser1 events: $url")
                Log.d("ApiClient", "   Method: ${request.method}")
                Log.d("ApiClient", "   Headers: ${request.headers}")
            }
            
            val response = chain.proceed(request)
            
            // Debug response for techuser1 events
            if (url.contains("get_study_events") && url.contains("techuser1")) {
                val responseBody = response.peekBody(Long.MAX_VALUE).string()
                Log.d("ApiClient", "🌐 NETWORK DEBUG: Response for techuser1 events (status ${response.code})")
                Log.d("ApiClient", "   Response first 500 chars: ${responseBody.take(500)}...")
            }
            
            response
        }
        .connectTimeout(60, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()
    
    // Configure Gson for date/time parsing
    private val gson: Gson = GsonBuilder()
        .setLenient()
        .create()
    
    // Create Retrofit instance
    private val retrofit = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create(gson))
        .build()
    
    // Create API service
    val apiService: ApiService = retrofit.create(ApiService::class.java)
    
    // Create event interactions service
    val eventInteractionsService: EventInteractionsService = retrofit.create(EventInteractionsService::class.java)
    
    /**
     * Set the UserAccountManager instance
     */
    fun setUserAccountManager(accountManager: UserAccountManager) {
        userAccountManager = accountManager
    }
    
    /**
     * Get the current logged-in username
     */
    fun getCurrentUsername(): String? {
        return userAccountManager?.currentUser
    }
    
    /**
     * Get the base URL for API calls
     */
    fun getBaseUrl(): String {
        return BASE_URL
    }
} 