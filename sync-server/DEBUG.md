# Debugging 401 Error - Sync Server

## Quick Diagnosis

The 401 error means the device authentication is failing. Here's how to debug it step by step:

## Step 1: Check Server is Running

```bash
# Check if server is accessible
curl http://localhost:3000/health

# Should return: {"status":"OK","timestamp":"..."}
```

## Step 2: Test Device Registration

```bash
# Run the test script
cd sync-server
./test-server.sh

# This will test all endpoints and show exactly where the issue is
```

## Step 3: Check Database Connection

```bash
# Connect to PostgreSQL and verify tables
psql -U postgres -d skadoosh_sync -c "SELECT * FROM users;"
psql -U postgres -d skadoosh_sync -c "SELECT * FROM notes;"
```

## Step 4: Check Server Logs

Make sure your server shows these logs when you try to sync:

```
Auth headers: { 'content-type': 'application/json', 'deviceid': 'android_xxxxx' }
Device ID: android_xxxxx
Database lookup result: [{ id: 'uuid-here' }]
Auth successful for user: uuid-here
```

## Common Issues and Fixes

### Issue 1: Database Not Initialized
**Symptoms:** Server starts but tables don't exist
**Fix:** 
```bash
# Restart server, it should create tables automatically
npm start
```

### Issue 2: Device ID Header Missing
**Symptoms:** "Device ID required in headers" error
**Fix:** Check the header name in sync service (should be 'deviceid')

### Issue 3: Device Not Registered
**Symptoms:** "Device not registered" error  
**Solution:** 
1. Check if device registration succeeded
2. Verify device ID is stored in SharedPreferences
3. Check database for the device entry

### Issue 4: Network Configuration
**Symptoms:** Connection timeout or connection refused
**Fix:**
```bash
# Make sure your Android device can reach your local machine
# Check firewall settings
# Use your machine's local IP, not localhost

# Find your local IP:
ip addr show | grep inet | grep -v 127.0.0.1
# or
ifconfig | grep inet | grep -v 127.0.0.1

# Use format: http://192.168.1.XXX:3000 (not localhost:3000)
```

## Environment File Check

Make sure your `.env` file is properly configured:

```env
PORT=3000
NODE_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=skadoosh_sync
DB_USER=postgres
DB_PASSWORD=your_password
```

## Manual Testing Steps

1. **Start server with debug logs:**
   ```bash
   cd sync-server
   npm run dev  # Shows all console.log outputs
   ```

2. **Test registration manually:**
   ```bash
   curl -X POST http://localhost:3000/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"deviceId":"test123","deviceName":"Test Device"}'
   ```

3. **Test push with registered device:**
   ```bash
   curl -X POST http://localhost:3000/api/sync/push \
     -H "Content-Type: application/json" \
     -H "deviceid: test123" \
     -d '{"notes":[{"localId":1,"title":"Test","eventType":"create"}]}'
   ```

## Flutter App Debug Steps

1. **Check Flutter logs:**
   ```bash
   flutter run
   # Look for sync service debug prints
   ```

2. **Verify device registration in app:**
   - Go to Sync Settings
   - Check if "Configure" shows success message
   - Verify connection test passes

3. **Check SharedPreferences:**
   The app should store:
   - `sync_server_url`
   - `device_id` 
   - `user_id`

## Database Queries for Debugging

```sql
-- Check if device was registered
SELECT * FROM users ORDER BY created_at DESC LIMIT 5;

-- Check notes in database
SELECT * FROM notes ORDER BY created_at DESC LIMIT 5;

-- Check sync events
SELECT * FROM sync_events ORDER BY created_at DESC LIMIT 5;

-- Check for specific device
SELECT * FROM users WHERE device_id = 'your_device_id_here';
```

## If All Else Fails

1. **Clear app data:**
   - Uninstall and reinstall the app
   - Or clear SharedPreferences

2. **Reset server:**
   ```bash
   # Drop and recreate database
   psql -U postgres -c "DROP DATABASE skadoosh_sync;"
   psql -U postgres -c "CREATE DATABASE skadoosh_sync;"
   
   # Restart server (will recreate tables)
   npm start
   ```

3. **Check versions:**
   - Node.js version (should be 18+)
   - PostgreSQL version (should be 12+)
   - Flutter dependencies are up to date

## Success Indicators

When everything works correctly, you should see:

1. **Server logs:**
   ```
   ✅ Database initialized successfully
   🚀 Sync server running on port 3000
   ```

2. **Registration logs:**
   ```
   Registering device: android_xxxxx with name: Samsung Galaxy
   Registration response: 200
   Device registered successfully with userId: uuid-here
   ```

3. **Sync logs:**
   ```
   Notes to push: 1
   Push response status: 200
   Pushed 1 notes successfully
   ```

4. **App behavior:**
   - "Configure" button shows success
   - "Test" button shows "Connection successful"
   - "Sync Now" shows "Sync completed! Pushed: X, Pulled: Y"

Run the test script first to identify exactly where the issue is, then follow the appropriate fix above!