package com.example.pinit.repository

import android.content.Context
import android.net.Uri
import android.util.Log
import com.example.pinit.models.*
import com.example.pinit.network.ApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.File
import java.io.FileOutputStream

/**
 * Repository for image management
 */
class ImageRepository {
    private val TAG = "ImageRepository"
    private val apiService = ApiClient.apiService
    
    /**
     * Get user images
     */
    fun getUserImages(username: String): Flow<Result<List<UserImage>>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Fetching images for user: $username")
            val response = apiService.getUserImages(username)
            
            if (response.isSuccessful && response.body() != null) {
                val images = response.body()!!.images
                Log.d(TAG, "Successfully fetched ${images.size} images")
                emit(Result.Success(images))
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to fetch images: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception fetching images", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Upload user image
     */
    fun uploadImage(
        context: Context,
        imageUri: Uri,
        imageType: ImageType,
        caption: String? = null
    ): Flow<Result<UploadImageResponse>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Uploading image: type=$imageType, caption=$caption")
            
            // Convert URI to file
            val file = createTempFileFromUri(context, imageUri)
            if (file == null) {
                emit(Result.Error(Exception("Failed to create file from URI"), "Failed to process image"))
                return@flow
            }
            
            // Create request body for image type
            val imageTypeBody = imageType.value.toRequestBody("text/plain".toMediaTypeOrNull())
            
            // Create multipart body for image
            val requestFile = file.asRequestBody("image/*".toMediaTypeOrNull())
            val imagePart = MultipartBody.Part.createFormData("image", file.name, requestFile)
            
            // Create caption body if provided
            val captionBody = caption?.toRequestBody("text/plain".toMediaTypeOrNull())
            
            val response = apiService.uploadUserImage(imageTypeBody, imagePart, captionBody)
            
            // Clean up temp file
            file.delete()
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!
                if (result.success) {
                    Log.d(TAG, "Successfully uploaded image: ${result.url}")
                    emit(Result.Success(result))
                } else {
                    val error = result.message ?: "Failed to upload image"
                    Log.e(TAG, "Image upload failed: $error")
                    emit(Result.Error(Exception(error), error))
                }
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to upload image: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception uploading image", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Delete user image
     */
    fun deleteImage(imageId: String): Flow<Result<Boolean>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Deleting image: $imageId")
            val response = apiService.deleteUserImage(imageId)
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!
                if (result.success) {
                    Log.d(TAG, "Successfully deleted image")
                    emit(Result.Success(true))
                } else {
                    val error = result.message ?: "Failed to delete image"
                    Log.e(TAG, "Image deletion failed: $error")
                    emit(Result.Error(Exception(error), error))
                }
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to delete image: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception deleting image", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Set image as primary
     */
    fun setPrimaryImage(imageId: String): Flow<Result<Boolean>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Setting primary image: $imageId")
            val response = apiService.setPrimaryImage(imageId)
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!
                if (result.success) {
                    Log.d(TAG, "Successfully set primary image")
                    emit(Result.Success(true))
                } else {
                    val error = result.message ?: "Failed to set primary image"
                    Log.e(TAG, "Set primary image failed: $error")
                    emit(Result.Error(Exception(error), error))
                }
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to set primary image: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception setting primary image", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Helper function to create temp file from URI
     */
    private fun createTempFileFromUri(context: Context, uri: Uri): File? {
        return try {
            val inputStream = context.contentResolver.openInputStream(uri) ?: return null
            val tempFile = File.createTempFile("upload_", ".jpg", context.cacheDir)
            val outputStream = FileOutputStream(tempFile)
            
            inputStream.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }
            
            tempFile
        } catch (e: Exception) {
            Log.e(TAG, "Error creating temp file from URI", e)
            null
        }
    }
    
    /**
     * Get profile image URL (primary image or null)
     */
    fun getProfileImageUrl(images: List<UserImage>): String? {
        return images.firstOrNull { it.is_primary && it.image_type == "profile" }?.url
            ?: images.firstOrNull { it.image_type == "profile" }?.url
    }
    
    /**
     * Get gallery images
     */
    fun getGalleryImages(images: List<UserImage>): List<UserImage> {
        return images.filter { it.image_type == "gallery" }
            .sortedByDescending { it.uploaded_at }
    }
}

