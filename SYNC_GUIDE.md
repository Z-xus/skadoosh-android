# Skadoosh Note Sync System

This document provides a comprehensive overview of the synchronization system implemented for the Skadoosh notes application.

## Overview

The sync system enables seamless synchronization of notes across multiple devices and platforms using an **event-driven, server-centric architecture**. The system only syncs note creations and updates, never deletions, ensuring data safety.

## Architecture

### Sync Method: Event-Driven with Timestamps

**Why this approach?**
- Efficient bandwidth usage (only syncs changes)
- Real-time or near real-time updates
- Simple conflict resolution
- Perfect for your "no deletion" requirement
- Scales well across multiple devices

### Components

1. **Client-side (Flutter App)**
   - Extended Note model with sync fields
   - SyncService for server communication
   - Enhanced NoteDatabase with sync support
   - Sync Settings UI

2. **Server-side (Node.js)**
   - Express.js API server
   - PostgreSQL database
   - Device authentication
   - Event tracking system

## How It Works

### 1. Device Registration
```
Client → Server: Register device with unique ID
Server → Database: Store device info
Server → Client: Return user ID
```

### 2. Note Creation/Update
```
User creates/edits note → Local database → Mark needsSync=true
```

### 3. Sync Process
```
1. Push Phase:
   Client → Server: Send notes marked needsSync=true
   Server → Database: Store/update notes + create sync events
   
2. Pull Phase:
   Client → Server: Request changes since last sync
   Server → Client: Return notes from other devices
   Client → Local DB: Apply remote changes
```

## Database Schema

### Client (Isar - Flutter)
```dart
class Note {
  Id id = Isar.autoIncrement;     // Local ID
  late String title;
  
  // Sync fields
  String? serverId;               // Server UUID
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastSyncedAt;
  bool needsSync = false;         // Pending sync flag
  String deviceId = '';           // Device identifier
}
```

### Server (PostgreSQL)
```sql
-- Device management
users (id, device_id, device_name, created_at, last_seen)

-- Note storage
notes (id, user_id, title, content, created_at, updated_at, 
       device_id, local_id, version)

-- Sync event tracking
sync_events (id, user_id, note_id, event_type, created_at, device_id)
```

## Sync Flow Details

### Initial Setup
1. User opens Sync Settings
2. Enters server URL (your VPS)
3. App generates unique device ID
4. Registers with server
5. Ready to sync!

### Ongoing Synchronization
1. **Create Note**: Local → Mark needsSync=true
2. **Sync Now**: 
   - Push local changes to server
   - Pull remote changes from server
   - Update sync timestamps
3. **Automatic**: App can sync periodically or on app start

### Conflict Resolution
- **Last-write-wins**: Server timestamp determines latest version
- **No deletions**: Ensures no data loss
- **Version tracking**: Each note has version number

## Files Modified/Created

### Flutter Client
- **lib/models/note.dart**: Added sync fields
- **lib/models/note_database.dart**: Enhanced with sync methods
- **lib/services/sync_service.dart**: New sync logic
- **lib/pages/sync_settings_page.dart**: New settings UI
- **lib/pages/settings.dart**: Added sync navigation
- **pubspec.yaml**: Added HTTP and device info dependencies

### Sync Server
- **sync-server/**: Complete Node.js server
- **package.json**: Server dependencies
- **src/index.js**: Main server file
- **src/routes/auth.js**: Device registration
- **src/routes/sync.js**: Sync endpoints
- **src/database/init.js**: Database setup
- **.env.example**: Configuration template
- **README.md**: Deployment guide

## Alternative Sync Methods Considered

1. **Timestamp-Based Sync**
   - Uses lastModified timestamps
   - Simple but less efficient
   - Good for periodic syncing

2. **Version-Based Sync**
   - Each note has version number
   - Better conflict handling
   - More complex implementation

3. **Merkle Tree Sync**
   - Hash-based sync for large datasets
   - Very efficient but complex
   - Overkill for note apps

4. **Operational Transform (OT)**
   - For real-time collaborative editing
   - Very complex implementation
   - Not needed for simple notes

5. **CRDTs (Conflict-Free Replicated Data Types)**
   - Automatic conflict resolution
   - Complex but powerful
   - Future consideration

## Security Features

- **Device Authentication**: Each device has unique ID
- **Rate Limiting**: Prevents abuse (100 req/15min)
- **CORS Protection**: Configurable allowed origins
- **Input Validation**: Server validates all inputs
- **HTTPS Support**: Via reverse proxy (Nginx)

## Deployment Options

### 1. VPS Deployment (Recommended)
```bash
# Install Node.js, PostgreSQL
# Clone repo, configure .env
# Use PM2 for process management
# Nginx reverse proxy for HTTPS
```

### 2. Docker Deployment
```bash
# Containerized with PostgreSQL
# Easy scaling and management
# Include docker-compose setup
```

### 3. Cloud Services
- **Heroku**: Easy deployment with PostgreSQL addon
- **DigitalOcean App Platform**: Managed deployment
- **AWS/GCP**: Full cloud infrastructure

## Usage Instructions

### For Users:
1. Install app on multiple devices
2. Go to Settings → Sync Settings
3. Enter your server URL
4. Tap "Configure" to register device
5. Use "Sync Now" to sync notes
6. Notes automatically sync on create/edit

### For Developers:
1. Deploy sync server to your VPS
2. Configure domain and SSL certificate
3. Update client with server URL
4. Test sync functionality
5. Monitor server health and logs

## Benefits of This Approach

✅ **Cross-Platform**: Works on Android, iOS, Web, Desktop  
✅ **Real-time**: Near-instant sync when online  
✅ **Offline-First**: Works offline, syncs when online  
✅ **Data Safety**: No deletion sync prevents data loss  
✅ **Scalable**: Handles multiple devices efficiently  
✅ **Simple**: Easy to understand and maintain  
✅ **Self-Hosted**: Full control over your data  

## Future Enhancements

- **Automatic Sync**: Background sync on connectivity
- **Rich Content**: Support for images, formatting
- **Collaboration**: Share notes between users
- **Encryption**: End-to-end encryption for privacy
- **WebSocket**: Real-time sync notifications
- **Offline Queue**: Better offline change handling

## Getting Started

1. **Deploy Server**: Follow sync-server/README.md
2. **Configure Client**: Update app with server URL
3. **Test Sync**: Create notes on different devices
4. **Monitor**: Check server logs and health

The sync system is now ready to keep your notes synchronized across all your devices!