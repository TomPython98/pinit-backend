# Data Generation System Documentation

## Overview
This document describes the comprehensive data generation system for PinIt, including test data creation, backend integration, and maintenance scripts.

## System Architecture

### Components
1. **Backend API** - Django REST Framework endpoints
2. **Data Generation Scripts** - Python scripts for creating test data
3. **Image Generation** - Automated profile picture creation
4. **Database Population** - Comprehensive test data seeding

## Data Generation Scripts

### 1. Final Comprehensive Data Generation Script
**File**: `final_comprehensive_data_generation.py`

**Purpose**: Creates a complete test dataset with all features working

**Features**:
- User registration and profile setup
- Event creation with realistic data
- Social interactions (comments, likes, shares)
- Friend network creation
- Event invitations (FIXED)
- RSVPs and attendance
- User ratings and reputation

**Usage**:
```bash
python3 final_comprehensive_data_generation.py
```

**Generated Data**:
- 17 test users with diverse profiles
- 23 study events across different subjects
- 51 friend requests (34 accepted)
- 124 comments on events
- 199 likes showing engagement
- 88 event shares
- 109 event invitations
- 78 RSVPs
- 46 user ratings

### 2. Test Invitation System Script
**File**: `test_invitation_system.py`

**Purpose**: Tests the invitation system functionality

**Features**:
- Creates test users
- Creates test events
- Tests invitation sending
- Verifies invitation retrieval

**Usage**:
```bash
python3 test_invitation_system.py
```

### 3. Profile Picture Generation Script
**File**: `add_profile_pictures.py`

**Purpose**: Generates and uploads profile pictures for users

**Features**:
- Creates unique profile pictures with user initials
- Color-coded backgrounds
- Uploads to backend via multipart form data
- Handles R2 cloud storage integration

**Usage**:
```bash
python3 add_profile_pictures.py
```

## Test Data Structure

### Users
Each test user includes:
- **Username**: Unique identifier
- **Full Name**: Realistic name
- **University**: Prestigious institutions
- **Degree**: Relevant field of study
- **Interests**: 5 diverse interests
- **Skills**: Technical skills with proficiency levels
- **Profile Picture**: Generated unique image

### Events
Each event includes:
- **Title**: Descriptive event name
- **Description**: Detailed event description
- **Location**: Realistic venue
- **Coordinates**: Real university locations
- **Time**: Future dates (1-30 days ahead)
- **Duration**: 1-3 hours
- **Event Type**: Study, Academic, Cultural
- **Interest Tags**: Relevant tags
- **Max Participants**: 4-12 people
- **Auto-matching**: Enabled

### Social Interactions
- **Comments**: 3-8 per event
- **Likes**: 5-12 per event
- **Shares**: 2-6 per event
- **Invitations**: 3-6 per event
- **RSVPs**: 2-5 per event

### Friend Network
- **Friend Requests**: 2-4 per user
- **Acceptance Rate**: 70%
- **Bidirectional**: Mutual friendships

### User Ratings
- **Ratings per User**: 2-4 ratings given
- **Rating Scale**: 4-5 stars (positive bias)
- **Comments**: Constructive feedback

## Backend Integration

### Fixed Issues
1. **Invitation Endpoint Bug**: Removed duplicate EventInvitation creation
2. **Image Upload**: Fixed R2 storage compatibility
3. **Rating Success Detection**: Corrected response parsing

### API Endpoints Used
- `POST /api/register/` - User registration
- `POST /api/update_user_interests/` - Profile updates
- `POST /api/send_friend_request/` - Friend requests
- `POST /api/accept_friend_request/` - Accept requests
- `POST /api/create_study_event/` - Event creation
- `POST /api/events/comment/` - Add comments
- `POST /api/events/like/` - Like events
- `POST /api/events/share/` - Share events
- `POST /invite_to_event/` - Send invitations
- `POST /api/rsvp_study_event/` - RSVP to events
- `POST /api/submit_user_rating/` - Submit ratings
- `POST /api/upload_user_image/` - Upload images

## Data Quality Features

### Realistic Data
- **University Locations**: Real coordinates for major universities
- **Event Types**: Diverse academic and social events
- **Time Distribution**: Events spread over 30 days
- **Social Patterns**: Realistic engagement levels

### Diversity
- **Academic Fields**: CS, Medicine, Business, Arts, Engineering, Physics, Law, Psychology
- **Universities**: Stanford, Harvard, MIT, NYU, Yale, Caltech, Berkeley, etc.
- **Event Types**: Study groups, workshops, reviews, collaborations
- **Interests**: Technology, Healthcare, Business, Creative, Academic

### Engagement Patterns
- **High Activity**: Lots of comments and likes
- **Social Sharing**: Event sharing for discovery
- **Participation**: Real RSVPs and attendance
- **Reputation**: User rating system

## Maintenance and Updates

### Adding New Users
1. Add user data to `TEST_USERS` array
2. Run the comprehensive generation script
3. Verify user creation and profile setup

### Adding New Events
1. Add event data to `SAMPLE_EVENTS` array
2. Ensure realistic coordinates and timing
3. Include appropriate interest tags

### Updating Social Patterns
1. Modify interaction counts in script
2. Adjust acceptance rates for friend requests
3. Update rating patterns

## Troubleshooting

### Common Issues
1. **Invitation Failures**: Check backend deployment
2. **Image Upload Errors**: Verify R2 credentials
3. **Rating Detection**: Check response parsing logic
4. **Event Creation**: Verify coordinate format

### Debugging
- Enable verbose logging in scripts
- Check API response codes
- Verify database state
- Test individual endpoints

## Performance Considerations

### Batch Operations
- User creation: 0.3s delay between users
- Event creation: 0.5s delay between events
- Social interactions: 0.2s delay between actions

### Rate Limiting
- No current rate limiting on backend
- Scripts include delays to prevent overwhelming
- Consider implementing rate limiting for production

### Database Impact
- Large dataset generation
- Consider cleanup scripts for testing
- Monitor database performance

## Future Enhancements

### Planned Features
1. **Cleanup Scripts**: Remove test data
2. **Data Validation**: Verify data integrity
3. **Performance Testing**: Load testing with large datasets
4. **Automated Testing**: CI/CD integration

### Scalability
1. **Batch Processing**: Process users in batches
2. **Parallel Operations**: Concurrent API calls
3. **Progress Tracking**: Real-time generation progress
4. **Error Recovery**: Resume from failures

## Security Considerations

### Test Data
- No real user information
- Generated usernames and emails
- Safe for development and testing

### API Security
- No authentication required for most endpoints
- Consider adding authentication for production
- Validate all input data

## Monitoring and Analytics

### Generated Metrics
- User registration success rate
- Event creation success rate
- Social interaction success rate
- Invitation success rate
- Overall completion rate

### Quality Metrics
- Data completeness
- Realistic patterns
- Engagement levels
- Error rates

## Conclusion

The data generation system provides a comprehensive test environment for PinIt with realistic data patterns, full feature coverage, and robust error handling. It enables thorough testing of all app features including the previously broken invitation system.
