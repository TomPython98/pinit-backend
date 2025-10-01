package com.example.pinit

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.pinit.models.UserAccountManager
import com.example.pinit.components.MapViewModel
import com.example.pinit.utils.PotentialMatchRegistry
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import android.util.Log
import com.example.pinit.repository.EventRepository
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import kotlinx.coroutines.flow.first

@RunWith(AndroidJUnit4::class)
class MapAutoMatchedTest {

    private lateinit var accountManager: UserAccountManager
    private lateinit var repository: EventRepository

    @Before
    fun setup() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        accountManager = UserAccountManager(appContext)
        repository = EventRepository()
        
        // Login as techuser1
        accountManager.loginUser("techuser1", "password123")
    }

    @Test
    fun testAutoMatchedInvitationsAreRegistered() = runBlocking {
        // Check if we're logged in as techuser1
        assert(accountManager.currentUser == "techuser1") { "Not logged in as techuser1" }
        
        // Clear the potential match registry
        PotentialMatchRegistry.clear()
        
        // Get invitations from the server
        val invitationsResult = repository.getInvitations("techuser1").first()
        
        // Check if successful
        assert(invitationsResult.isSuccess) { "Failed to get invitations: ${invitationsResult.exceptionOrNull()?.message}" }
        
        // Get the response body
        val responseBody = invitationsResult.getOrNull()
        assert(responseBody != null) { "Response body is null" }
        
        // Parse the invitations
        val invitationsArray = responseBody!!.getJSONArray("invitations")
        var foundAutoMatched = false
        var autoMatchedTitle = ""
        
        // Check for auto-matched invitations
        for (i in 0 until invitationsArray.length()) {
            val invitation = invitationsArray.getJSONObject(i)
            val isAutoMatched = invitation.optBoolean("isAutoMatched", false)
            if (isAutoMatched) {
                foundAutoMatched = true
                autoMatchedTitle = invitation.optString("title", "Unknown")
                val id = invitation.optString("id", "")
                Log.d("MapAutoMatchedTest", "Found auto-matched invitation: $autoMatchedTitle (id: $id)")
                PotentialMatchRegistry.registerPotentialMatch(id)
            }
        }
        
        assert(foundAutoMatched) { "No auto-matched invitations found" }
        Log.d("MapAutoMatchedTest", "✅ Test passed: Found auto-matched invitation: $autoMatchedTitle")
        
        // Check that we registered the auto-matched invitation
        assert(PotentialMatchRegistry.count() > 0) { "No potential matches registered" }
        Log.d("MapAutoMatchedTest", "✅ Test passed: PotentialMatchRegistry has ${PotentialMatchRegistry.count()} entries")
    }
} 