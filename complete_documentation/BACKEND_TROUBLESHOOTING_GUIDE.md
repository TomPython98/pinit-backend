# Backend Troubleshooting Guide

## Overview
This guide provides solutions for common backend issues, debugging techniques, and maintenance procedures for the PinIt backend API.

## Common Issues and Solutions

### 1. Invitation System Issues

#### Problem: "EventInvitation() got unexpected keyword arguments: 'inviter'"
**Root Cause**: Duplicate EventInvitation creation with invalid field
**Solution**: Fixed in backend - removed duplicate creation
**Status**: ✅ RESOLVED

#### Problem: Invitations not appearing in frontend
**Debug Steps**:
1. Check invitation endpoint response
2. Verify user exists in database
3. Check EventInvitation model fields
4. Verify frontend API call format

**Code Check**:
```python
# Backend: invite_to_event function
event.invite_user(user, is_auto_matched)  # This creates EventInvitation correctly
# Removed duplicate creation with invalid 'inviter' field
```

### 2. Image Upload Issues

#### Problem: 500 error during image upload
**Root Cause**: R2 storage compatibility issues
**Solution**: Fixed image metadata extraction and R2 storage handling

**Debug Steps**:
1. Check R2 credentials
2. Verify image format
3. Check file size limits
4. Test with different image types

**Code Check**:
```python
# Fixed in upload_user_image endpoint
def optimize_image(self):
    # Handle R2 storage by reading into BytesIO
    image_data = self.image.read()
    image_file = BytesIO(image_data)
    # Process with PIL
```

### 3. Rating System Issues

#### Problem: Ratings reported as failed but actually succeeded
**Root Cause**: Incorrect success detection in script
**Solution**: Check for `success: true` in response body, not just status code

**Debug Steps**:
1. Check response status code (200)
2. Parse response JSON
3. Look for `success: true` field
4. Verify rating creation in database

### 4. Event Creation Issues

#### Problem: "Invalid isoformat string" error
**Root Cause**: Incorrect datetime format
**Solution**: Use full ISO 8601 format with timezone

**Correct Format**:
```python
# Correct
"time": "2024-01-15T14:30:00Z"
# Incorrect
"time": "14:30:00"
```

#### Problem: "NOT NULL constraint failed: myapp_studyevent.latitude"
**Root Cause**: Missing required coordinates
**Solution**: Always include latitude and longitude

**Required Fields**:
```python
{
    "latitude": 37.7749,  # Required
    "longitude": -122.4194,  # Required
    "time": "2024-01-15T14:30:00Z",  # Required
    "end_time": "2024-01-15T16:30:00Z"  # Required
}
```

### 5. Friend Request Issues

#### Problem: "Friend request already sent"
**Root Cause**: Duplicate friend request
**Solution**: Check existing requests before sending

**Debug Steps**:
1. Check pending requests
2. Check sent requests
3. Verify user exists
4. Check for existing friendship

### 6. Database Connection Issues

#### Problem: Database connection errors
**Debug Steps**:
1. Check Railway deployment status
2. Verify database credentials
3. Check connection string
4. Test with health check endpoint

**Health Check**:
```bash
curl https://pinit-backend-production.up.railway.app/health/
```

## Debugging Techniques

### 1. API Response Debugging

#### Check Response Status
```python
response = requests.post(url, json=data)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
```

#### Parse JSON Response
```python
try:
    result = response.json()
    print(f"Success: {result.get('success')}")
    print(f"Message: {result.get('message')}")
except:
    print("Invalid JSON response")
```

### 2. Database Debugging

#### Check User Exists
```python
# Test user existence
response = requests.get(f"{BASE_URL}/api/get_all_users/")
users = response.json()
print(f"Users: {users}")
```

#### Check Event Exists
```python
# Test event existence
response = requests.get(f"{BASE_URL}/api/get_study_events/{username}/")
events = response.json()
print(f"Events: {events}")
```

### 3. Endpoint Testing

#### Test Individual Endpoints
```bash
# Test registration
curl -X POST https://pinit-backend-production.up.railway.app/api/register/ \
  -H "Content-Type: application/json" \
  -d '{"username": "test", "password": "test"}'

# Test event creation
curl -X POST https://pinit-backend-production.up.railway.app/api/create_study_event/ \
  -H "Content-Type: application/json" \
  -d '{"host": "test", "title": "Test Event", ...}'
```

## Error Codes and Meanings

### HTTP Status Codes
- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **400 Bad Request**: Invalid request data
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server error

### Common Error Messages
- **"User not found"**: Username doesn't exist
- **"Event not found"**: Event ID doesn't exist
- **"Invalid JSON data"**: Malformed request body
- **"Missing required fields"**: Required parameters missing
- **"Friend request already sent"**: Duplicate friend request

## Monitoring and Logging

### Backend Logs
- Check Railway deployment logs
- Monitor error rates
- Track response times
- Watch for 500 errors

### Database Monitoring
- Check database connection
- Monitor query performance
- Watch for constraint violations
- Track data growth

### API Monitoring
- Test critical endpoints regularly
- Monitor response times
- Check error rates
- Verify data integrity

## Maintenance Procedures

### 1. Regular Health Checks
```bash
# Check API health
curl https://pinit-backend-production.up.railway.app/health/

# Check user endpoint
curl https://pinit-backend-production.up.railway.app/api/get_all_users/

# Check event endpoint
curl https://pinit-backend-production.up.railway.app/api/get_study_events/test_user/
```

### 2. Database Maintenance
- Monitor database size
- Check for orphaned records
- Verify data integrity
- Clean up test data if needed

### 3. Deployment Monitoring
- Check Railway deployment status
- Monitor build logs
- Verify environment variables
- Test after deployments

## Performance Optimization

### 1. Database Queries
- Use select_related for foreign keys
- Use prefetch_related for many-to-many
- Add database indexes
- Optimize query patterns

### 2. API Response Times
- Monitor response times
- Optimize slow endpoints
- Add caching where appropriate
- Use pagination for large datasets

### 3. Error Handling
- Implement proper error handling
- Add logging for debugging
- Return meaningful error messages
- Handle edge cases

## Security Considerations

### 1. Input Validation
- Validate all input data
- Sanitize user inputs
- Check data types
- Enforce length limits

### 2. Authentication
- Consider adding authentication
- Implement rate limiting
- Validate user permissions
- Secure sensitive endpoints

### 3. Data Protection
- Encrypt sensitive data
- Use HTTPS
- Validate file uploads
- Implement CORS properly

## Testing Procedures

### 1. Unit Testing
- Test individual functions
- Mock external dependencies
- Test error conditions
- Verify edge cases

### 2. Integration Testing
- Test API endpoints
- Verify database operations
- Test error handling
- Check response formats

### 3. Load Testing
- Test with large datasets
- Monitor performance
- Check memory usage
- Verify scalability

## Recovery Procedures

### 1. Database Recovery
- Backup database regularly
- Test restore procedures
- Monitor data integrity
- Have rollback plan

### 2. API Recovery
- Monitor endpoint health
- Have fallback procedures
- Test error recovery
- Implement circuit breakers

### 3. Deployment Recovery
- Test deployment process
- Have rollback procedures
- Monitor deployment health
- Verify functionality after deployment

## Best Practices

### 1. Code Quality
- Write clean, readable code
- Add proper error handling
- Use meaningful variable names
- Add comments for complex logic

### 2. API Design
- Use consistent naming conventions
- Return meaningful error messages
- Use appropriate HTTP status codes
- Document all endpoints

### 3. Database Design
- Use proper data types
- Add necessary constraints
- Create appropriate indexes
- Normalize data properly

## Conclusion

This troubleshooting guide provides comprehensive solutions for common backend issues. Regular monitoring, proper error handling, and following best practices will help maintain a stable and reliable backend system.
