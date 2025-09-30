# Data Generation Scripts Documentation

## 📁 Script Organization

### Primary Scripts Location: `/scripts/`
All main data generation scripts are located in the `/scripts/` folder for easy access and organization.

### 🧹 Recent Cleanup (September 2025)
Removed 25+ redundant, outdated, and confusing data generation files from the backend directories:
- **Empty files**: create_matches.py, fix_matches.py, simple_matches.py, etc.
- **Austrian data files**: populate_austria_data.py, complete_auto_matching_setup.py (conflicted with Buenos Aires setup)
- **Debug/test files**: debug_*.py, test_*.py (development-only files)
- **Files with broken paths**: Files referencing old project locations
- **Useless files**: Minimal test files and broken utilities

**Kept useful utilities**: fix_interests.py, generate_potential_matches.py, fix_database.py

## 🚀 Complete Buenos Aires Data Generation Workflow

### 1. Generate Base Data
**Script**: `scripts/generate_buenos_aires_data.py`
**Purpose**: Creates users, events, and basic social structure for Buenos Aires international students
**Usage**:
```bash
cd scripts
python generate_buenos_aires_data.py
```

**What it creates**:
- 1000+ international students with realistic profiles
- 150+ events across Buenos Aires neighborhoods
- User profiles with interests, skills, and academic info
- Events with proper interest tags and locations
- Basic event invitations

**Key Features**:
- ✅ **Future dates**: Events are created 1-30 days in the future
- ✅ **Realistic data**: Uses Faker with Spanish locale for authentic names
- ✅ **Buenos Aires locations**: Real neighborhoods and universities
- ✅ **Interest matching**: Events have interest tags that match user profiles
- ✅ **Diverse event types**: Study, social, cultural, networking, etc.

### 2. Build Social Network
**Script**: `scripts/create_social_network.py`
**Purpose**: Creates friend connections, reviews, and private events
**Usage**:
```bash
cd scripts
python create_social_network.py
```

**What it creates**:
- Friend connections between users
- Friend requests (pending and sent)
- User reviews and ratings
- Private events with exclusive invitations
- Social interactions and relationships

### 3. Enable Auto-Matching
**Script**: `scripts/run_auto_matching.py`
**Purpose**: Runs the intelligent auto-matching system to create event suggestions
**Usage**:
```bash
cd scripts
python run_auto_matching.py
```

**What it creates**:
- Auto-matched invitations based on user interests
- Smart event suggestions for each user
- Personalized event recommendations
- Enhanced user engagement through relevant events

**⚠️ Important**: This script was fixed to use the correct path:
```python
# Fixed path (was pointing to wrong directory)
sys.path.append('/Users/tombesinger/Desktop/PinItApp/Back_End/StudyCon/StudyCon')
```

### 4. Generated Credentials
**File**: `scripts/buenos_aires_credentials.txt`
**Purpose**: Contains login credentials for all generated users
**Format**:
```
Username,Password,Email
mercedes_cuesta_934,buenosaires123,mercedes.cuesta@example.com
stanislav_marion_954,buenosaires123,stanislav.marion@example.com
...
```

**Default Password**: `buenosaires123` (for all accounts)

## 📋 Complete Setup Workflow

### Quick Setup (Recommended)
```bash
# 1. Navigate to project root
cd /Users/tombesinger/Desktop/PinItApp

# 2. Start Django server (in separate terminal)
cd Back_End/StudyCon/StudyCon
source ../venv/bin/activate
python manage.py runserver 0.0.0.0:8000

# 3. Generate complete dataset (in main terminal)
cd scripts
python generate_buenos_aires_data.py
python create_social_network.py
python run_auto_matching.py

# 4. Verify data
echo "Setup complete! Check scripts/buenos_aires_credentials.txt for login accounts"
```

### Manual Step-by-Step Setup
```bash
# 1. Activate virtual environment
cd Back_End/StudyCon
source venv/bin/activate

# 2. Reset database (optional)
cd StudyCon
python manage.py flush --noinput
python manage.py migrate

# 3. Generate base data
cd ../../../scripts
python generate_buenos_aires_data.py

# 4. Build social connections
python create_social_network.py

# 5. Enable auto-matching
python run_auto_matching.py

# 6. Start server
cd ../Back_End/StudyCon/StudyCon
python manage.py runserver 0.0.0.0:8000
```

## 🧪 Test Accounts

### Recommended Test Accounts
All accounts use password: `buenosaires123`

| Username | Email | Features |
|----------|-------|----------|
| `claire_monteiro_554` | claire.monteiro@example.com | 30+ auto-matched events |
| `mercedes_cuesta_934` | mercedes.cuesta@example.com | Multiple hosted events |
| `alfonso_tasca_798` | alfonso.tasca@example.com | Rich social connections |
| `vinícius_rios_707` | vinicius.rios@example.com | Diverse event types |
| `ruggiero_stahr_308` | ruggiero.stahr@example.com | High engagement |

### Account Features
- ✅ **Hosted Events**: Each user hosts 1-3 events
- ✅ **Auto-Matched Invitations**: 20-30 personalized event suggestions
- ✅ **Social Connections**: Friends, ratings, and reviews
- ✅ **Realistic Profiles**: Interests, skills, university info
- ✅ **Geographic Distribution**: Spread across Buenos Aires

## 🔧 Legacy Scripts (Back_End/StudyCon/)

### Deprecated Scripts
These scripts are kept for reference but **should not be used** for new data generation:

- `populate_austria_data.py` - ❌ Creates Austrian data (wrong location)
- `complete_auto_matching_setup.py` - ❌ Overwrites Buenos Aires data
- `simple_populate.py` - ❌ Creates minimal test data
- `reset_and_populate_db.py` - ❌ Generic population script

### Debug Scripts (Keep for troubleshooting)
- `debug_auto_matching.py` - Debug auto-matching issues
- `debug_frontend_events.py` - Debug frontend event display
- `fix_auto_matching.py` - Fix auto-matching problems
- `apply_auto_matches.py` - Apply auto-matching manually

### Test Scripts (Keep for development)
- `test_auto_matching.py` - Test auto-matching functionality
- `test_enhanced_matching.py` - Test enhanced matching algorithms
- `test_profile_completion.py` - Test profile completion

## 📊 Data Statistics

### After Complete Setup
- **Users**: ~1000 international students
- **Events**: ~170 events (all future dates)
- **Auto-Matched Invitations**: ~250 intelligent suggestions
- **Social Connections**: ~500 friend relationships
- **User Reviews**: ~200 ratings and reviews
- **Geographic Coverage**: All major Buenos Aires neighborhoods

### Event Distribution
- **Study Events**: 30%
- **Social Events**: 25%
- **Cultural Events**: 20%
- **Networking Events**: 15%
- **Academic Events**: 10%

### User Profile Completion
- **Interests**: 100% (5-10 interests per user)
- **Skills**: 80% (2-5 skills per user)
- **University Info**: 90%
- **Bio**: 70%
- **Profile Photos**: 0% (not implemented)

## 🚨 Common Issues & Solutions

### Issue: Auto-Matched Events Not Appearing
**Cause**: Events have past dates
**Solution**: See [Troubleshooting Auto-Matching](./Troubleshooting_Auto_Matching.md)

### Issue: No Events on Map
**Cause**: Using wrong API endpoint or past event dates
**Solution**: 
1. Ensure CalendarManager uses `/api/get_study_events/<username>/`
2. Verify events have future dates
3. Check auto-matching was run

### Issue: Users Can't Login
**Cause**: Credentials file not generated or wrong password
**Solution**: 
1. Check `scripts/buenos_aires_credentials.txt` exists
2. Use password: `buenosaires123`
3. Regenerate data if needed

### Issue: Server Won't Start
**Cause**: Virtual environment not activated or dependencies missing
**Solution**:
```bash
cd Back_End/StudyCon
source venv/bin/activate
pip install -r requirements.txt
cd StudyCon
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

## 🔄 Data Regeneration

### When to Regenerate Data
- After major database schema changes
- When testing new features
- If data becomes corrupted
- When updating to new locations/scenarios

### Quick Regeneration
```bash
# Clear existing data
cd Back_End/StudyCon/StudyCon
source ../venv/bin/activate
python manage.py flush --noinput

# Regenerate everything
cd ../../../scripts
python generate_buenos_aires_data.py
python create_social_network.py
python run_auto_matching.py
```

### Partial Regeneration
```bash
# Only regenerate auto-matching (keeps users and events)
cd scripts
python run_auto_matching.py

# Only regenerate social connections (keeps users and events)
python create_social_network.py
```

## 📝 Script Customization

### Modifying User Count
Edit `generate_buenos_aires_data.py`:
```python
# Change these values
NUM_USERS = 1000  # Adjust user count
NUM_EVENTS = 150  # Adjust event count
```

### Adding New Event Types
Edit `generate_buenos_aires_data.py`:
```python
EVENT_TYPES = [
    'study', 'social', 'cultural', 'networking', 
    'academic', 'language_exchange', 'business',
    'your_new_type'  # Add here
]
```

### Changing Location
To adapt for different cities:
1. Update `BUENOS_AIRES_NEIGHBORHOODS` with new locations
2. Update `UNIVERSITIES` with local institutions
3. Update `INTERESTS` with region-specific interests
4. Update Faker locale if needed

## 🔗 Related Documentation

- [Troubleshooting Auto-Matching](./Troubleshooting_Auto_Matching.md)
- [API Documentation](./API_Documentation.md)
- [Database Schema](./Database_Schema.md)
- [System Interactions](./System_Interactions.md)

---

**Last Updated**: January 2025  
**Scripts Version**: 2.0  
**Data Format**: Buenos Aires International Students  
**Status**: ✅ Production Ready
