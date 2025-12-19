# Skadoosh Sync Server

A Node.js-based synchronization server for the Skadoosh notes application. This server enables real-time synchronization of notes across multiple devices (Android, web, desktop, CLI).

## Features

- 📱 Cross-platform sync (Android, iOS, Web, Desktop)
- 🔄 Event-driven synchronization (create/update only)
- 🚫 No deletion sync (data safety)
- 🔐 Device-based authentication
- 📊 PostgreSQL database
- 🛡️ Security features (rate limiting, CORS, helmet)
- ⚡ Efficient bandwidth usage

## Quick Start

### Prerequisites

- Node.js 18+ 
- PostgreSQL 12+
- npm or yarn

### Installation

1. Clone and install dependencies:
```bash
cd sync-server
npm install
```

2. Set up environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Create PostgreSQL database:
```sql
CREATE DATABASE skadoosh_sync;
CREATE USER skadoosh_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE skadoosh_sync TO skadoosh_user;
```

4. Start the server:
```bash
# Development
npm run dev

# Production
npm start
```

## Environment Variables

```env
# Server Configuration
PORT=3000
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=skadoosh_sync
DB_USER=skadoosh_user
DB_PASSWORD=your_secure_password

# CORS Configuration
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

## Deployment on VPS

### Option 1: Direct Deployment

```bash
# On your VPS
git clone <your-repo>
cd skadoosh-android/sync-server
npm install --production
cp .env.example .env
# Configure .env

# Install PM2 for process management
npm install -g pm2
pm2 start src/index.js --name "skadoosh-sync"
pm2 startup
pm2 save
```

### Option 2: Docker Deployment

```dockerfile
# Dockerfile (create this in sync-server directory)
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY src ./src
COPY .env ./

EXPOSE 3000
CMD ["node", "src/index.js"]
```

```bash
# Build and run
docker build -t skadoosh-sync .
docker run -d -p 3000:3000 --name skadoosh-sync skadoosh-sync
```

### Option 3: Docker Compose (Recommended)

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=postgres
      - DB_USER=skadoosh_user
      - DB_PASSWORD=secure_password
      - DB_NAME=skadoosh_sync
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: skadoosh_sync
      POSTGRES_USER: skadoosh_user
      POSTGRES_PASSWORD: secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

## Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/skadoosh-sync
server {
    listen 80;
    server_name your-sync-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register device

### Sync
- `GET /api/sync/changes?since=<timestamp>` - Get changes since timestamp
- `POST /api/sync/push` - Push local changes
- `GET /api/sync/notes` - Get all notes (initial sync)

### Health
- `GET /health` - Server health check

## Database Schema

### Tables

**users**
- `id` (UUID, Primary Key)
- `device_id` (VARCHAR, Unique)
- `device_name` (VARCHAR)
- `created_at` (TIMESTAMP)
- `last_seen` (TIMESTAMP)

**notes**
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key)
- `title` (TEXT)
- `content` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `device_id` (VARCHAR)
- `local_id` (INTEGER)
- `version` (INTEGER)

**sync_events**
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key)
- `note_id` (UUID, Foreign Key)
- `event_type` (VARCHAR: create/update)
- `created_at` (TIMESTAMP)
- `device_id` (VARCHAR)

## Security Features

- **Rate Limiting**: 100 requests per 15 minutes per IP
- **CORS**: Configurable allowed origins
- **Helmet**: Security headers
- **Input Validation**: Request validation
- **Device Authentication**: Device-based access control

## Monitoring

Check server health:
```bash
curl https://your-server.com/health
```

Monitor with PM2:
```bash
pm2 status
pm2 logs skadoosh-sync
pm2 monit
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL is running
   - Verify connection credentials
   - Ensure database exists

2. **CORS Errors**
   - Check `ALLOWED_ORIGINS` in .env
   - Ensure client domain is included

3. **Rate Limiting**
   - Increase rate limit in `src/index.js`
   - Check if IP is being blocked

### Logs

```bash
# PM2 logs
pm2 logs skadoosh-sync

# Docker logs
docker logs skadoosh-sync

# Direct logs (development)
npm run dev
```

## License

MIT License - see LICENSE file for details.