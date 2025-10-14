package com.example.pinit.models

/**
 * Sealed class representing the result of an API operation
 * Provides type-safe error handling and loading states
 */
sealed class Result<out T> {
    /**
     * Successful result with data
     */
    data class Success<T>(val data: T) : Result<T>()
    
    /**
     * Error result with exception
     */
    data class Error(val exception: Exception, val message: String? = null) : Result<Nothing>()
    
    /**
     * Loading state
     */
    data object Loading : Result<Nothing>()
    
    /**
     * Initial/idle state
     */
    data object Idle : Result<Nothing>()
    
    /**
     * Check if result is successful
     */
    val isSuccess: Boolean
        get() = this is Success
    
    /**
     * Check if result is error
     */
    val isError: Boolean
        get() = this is Error
    
    /**
     * Check if result is loading
     */
    val isLoading: Boolean
        get() = this is Loading
    
    /**
     * Get data if successful, null otherwise
     */
    fun getOrNull(): T? = when (this) {
        is Success -> data
        else -> null
    }
    
    /**
     * Get error exception if error, null otherwise
     */
    fun exceptionOrNull(): Exception? = when (this) {
        is Error -> exception
        else -> null
    }
    
    /**
     * Execute action if successful
     */
    inline fun onSuccess(action: (T) -> Unit): Result<T> {
        if (this is Success) action(data)
        return this
    }
    
    /**
     * Execute action if error
     */
    inline fun onError(action: (Exception) -> Unit): Result<T> {
        if (this is Error) action(exception)
        return this
    }
    
    /**
     * Execute action if loading
     */
    inline fun onLoading(action: () -> Unit): Result<T> {
        if (this is Loading) action()
        return this
    }
}

/**
 * Extension function to wrap suspend function calls in Result
 */
suspend fun <T> safeApiCall(
    apiCall: suspend () -> T
): Result<T> {
    return try {
        Result.Success(apiCall())
    } catch (e: Exception) {
        Result.Error(e, e.message)
    }
}


