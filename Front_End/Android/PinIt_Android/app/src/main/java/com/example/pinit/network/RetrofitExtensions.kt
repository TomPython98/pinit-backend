package com.example.pinit.network

import android.util.Log
import org.json.JSONObject
import retrofit2.Response

/**
 * Extension functions for Retrofit to handle JSONObject responses
 */

/**
 * Extension function to get JSONObject from a Response
 */
fun Response<JSONObject>.body(): JSONObject? {
    return if (this.isSuccessful) {
        val bodyString = this.body()?.toString() ?: return null
        try {
            JSONObject(bodyString)
        } catch (e: Exception) {
            Log.e("RetrofitExtensions", "Error parsing JSONObject: ${e.message}")
            null
        }
    } else {
        Log.e("RetrofitExtensions", "Error getting body: ${this.errorBody()?.string()}")
        null
    }
}

/**
 * Extension function to check if a JSONObject has a specific key
 */
fun JSONObject?.has(key: String): Boolean {
    return this?.has(key) ?: false
}

/**
 * Extension function to get a JSONArray from a JSONObject
 */
fun JSONObject.getJSONArray(key: String): org.json.JSONArray {
    return this.getJSONArray(key)
} 