# 🚀 **QwinAI Production Server - Complete Deployment Guide**

## 📋 **Quick Start (5 Minutes)**

### **Step 1: Deploy on Railway (Recommended)**
```bash
# 1. Create GitHub repository
git init
git add .
git commit -m "Production-ready QwinAI server"
git remote add origin https://github.com/YOUR_USERNAME/qwinai-server.git
git push -u origin main

# 2. Deploy on Railway
# Go to railway.app → "New Project" → "Deploy from GitHub"
# Select your repository → Deploy
```

### **Step 2: Configure Environment**
In Railway dashboard:
1. Go to **Variables** tab
2. Add these essential variables:
```
DATABASE_URL=postgresql://... (auto-provided by Railway)
REDIS_URL=redis://... (auto-provided by Railway)
NODE_ENV=production
JWT_SECRET=generate_32_char_random_string
ADMIN_RESET_KEY=your_admin_reset_key
```

### **Step 3: Update Android App**
```kotlin
// In app/src/main/java/com/cyberflux/qwinai/UserStateManager.kt
internal const val SERVER_BASE_URL = "https://YOUR_APP_NAME.up.railway.app/api/"
```

### **Step 4: Test Everything**
```bash
# Test server health
curl https://YOUR_APP_NAME.up.railway.app/health

# Test file processing
curl -X POST https://YOUR_APP_NAME.up.railway.app/api/file-processor/process \
  -F "file=@test.pdf" \
  -F "model=gpt-4"
```

---

## 🏗️ **Detailed Deployment Options**

### **Option 1: Railway (Recommended - Easiest)**

**Why Railway?**
- ✅ Automatic PostgreSQL & Redis
- ✅ Zero-config deployment  
- ✅ Built-in monitoring
- ✅ $5/month starter plan
- ✅ Custom domains included

**Steps:**
1. **Create Railway Account**: [railway.app](https://railway.app)
2. **Connect GitHub**: Link your repository
3. **Auto-Deploy**: Railway detects Node.js and deploys automatically
4. **Add Database**: Railway → "New" → "Database" → "PostgreSQL"
5. **Add Redis**: Railway → "New" → "Database" → "Redis"
6. **Configure Variables**: Use Railway dashboard

**Database Schema Auto-Setup:**
Railway will automatically run the database migrations on first deployment.

---

### **Option 2: Heroku**

```bash
# Install Heroku CLI
npm install -g heroku

# Login and create app
heroku login
heroku create your-app-name

# Add PostgreSQL and Redis
heroku addons:create heroku-postgresql:essential-0
heroku addons:create heroku-redis:basic

# Deploy
git push heroku main

# Check logs
heroku logs --tail
```

**Environment Variables:**
```bash
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=your_32_char_secret
heroku config:set ADMIN_RESET_KEY=your_admin_key
```

---

### **Option 3: DigitalOcean App Platform**

```yaml
# .do/app.yaml
name: qwinai-server
services:
- name: api
  source_dir: /
  github:
    repo: YOUR_USERNAME/qwinai-server
    branch: main
  run_command: npm start
  environment_slug: node-js
  instance_count: 1
  instance_size_slug: basic-xxs
  
databases:
- name: qwinai-db
  engine: PG
  version: "13"
  
- name: qwinai-redis
  engine: REDIS
  version: "6"
```

Deploy: `doctl apps create .do/app.yaml`

---

### **Option 4: Self-Hosted (Advanced)**

**Requirements:**
- Ubuntu 20.04+ or similar
- Node.js 18+
- PostgreSQL 13+
- Redis 6+
- Nginx (reverse proxy)
- SSL certificate

```bash
# 1. Install dependencies
sudo apt update
sudo apt install nodejs npm postgresql redis-server nginx

# 2. Clone and setup
git clone https://github.com/YOUR_USERNAME/qwinai-server.git
cd qwinai-server
npm install --production

# 3. Configure PostgreSQL
sudo -u postgres createdb qwinai_production
sudo -u postgres createuser qwinai_user

# 4. Setup environment
cp .env.example .env
# Edit .env with your configuration

# 5. Start services
npm start
```

**Nginx Configuration:**
```nginx
server {
    listen 443 ssl;
    server_name api.yourdomain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 🗄️ **Database Setup**

### **Automatic Schema Creation**
The server automatically creates all required tables on startup:

```sql
-- Tables created automatically:
CREATE TABLE user_states (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(32) UNIQUE NOT NULL,
    device_fingerprint TEXT NOT NULL,
    credits_consumed_today_chat INTEGER DEFAULT 0,
    credits_consumed_today_image INTEGER DEFAULT 0,
    has_active_subscription BOOLEAN DEFAULT false,
    subscription_type VARCHAR(50),
    subscription_end_time BIGINT DEFAULT 0,
    current_date DATE DEFAULT CURRENT_DATE,
    app_version VARCHAR(10) DEFAULT '18',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE processed_files_secure (
    id SERIAL PRIMARY KEY,
    processing_id UUID UNIQUE NOT NULL,
    file_hash VARCHAR(64) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    total_tokens INTEGER NOT NULL,
    chunk_count INTEGER NOT NULL,
    model_used VARCHAR(50) NOT NULL,
    user_ip INET,
    user_id VARCHAR(100),
    access_count INTEGER DEFAULT 1,
    last_processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    UNIQUE(file_hash, model_used)
);
```

### **Manual Database Setup (if needed)**
```bash
# Connect to your database
psql $DATABASE_URL

# Run the schema creation
\i database_schema.sql
```

---

## 🔒 **Security Configuration**

### **Essential Security Settings**
```bash
# Generate secure JWT secret (32+ characters)
openssl rand -hex 32

# Generate admin reset key
openssl rand -hex 16

# Enable SSL/HTTPS (production requirement)
# Most platforms (Railway, Heroku) provide SSL automatically
```

### **CORS Configuration**
Update allowed origins for your Android app:
```javascript
// In app.js
const allowedOrigins = [
    'https://your-android-app-domain.com',
    'https://your-web-app.com'
];
```

### **Rate Limiting**
The server includes comprehensive rate limiting:
- 100 requests per hour per IP (general)
- 20 file uploads per hour per IP
- 1000 requests per hour per authenticated user

---

## 📊 **Monitoring & Health Checks**

### **Built-in Monitoring**
Access monitoring dashboard:
```
GET https://your-server.com/health
GET https://your-server.com/api/file-processor/stats
```

### **Performance Metrics**
The server tracks:
- Request response times
- File processing performance
- Memory usage
- Active connections
- Error rates

### **Alerting**
Configure environment variables for alerts:
```bash
ALERT_EMAIL=admin@yourdomain.com
ALERT_WEBHOOK=https://your-monitoring-service.com/webhook
```

---

## 🧪 **Testing Your Deployment**

### **Health Check**
```bash
curl https://your-server.com/health
# Expected: {"status":"OK","timestamp":"...","services":{...}}
```

### **User State API**
```bash
# Get user state
curl "https://your-server.com/api/user-state/a1b2c3d4e5f6g7h8"

# Update user state
curl -X PUT "https://your-server.com/api/user-state/a1b2c3d4e5f6g7h8" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "a1b2c3d4e5f6g7h8",
    "deviceFingerprint": "test-fingerprint",
    "creditsConsumedTodayChat": 5,
    "creditsConsumedTodayImage": 2,
    "hasActiveSubscription": false,
    "date": "2025-01-08",
    "appVersion": "18"
  }'
```

### **File Processing**
```bash
# Test PDF processing
curl -X POST "https://your-server.com/api/file-processor/process" \
  -F "file=@sample.pdf" \
  -F "model=gpt-4" \
  -F "maxTokensPerChunk=6000"

# Expected: {"success":true,"processingId":"...","chunks":[...]}
```

---

## 🚀 **Performance Optimization**

### **Scaling Configuration**
```json
{
  "instances": {
    "min": 1,
    "max": 5
  },
  "autoscaling": {
    "cpu_threshold": 70,
    "memory_threshold": 80
  }
}
```

### **Redis Caching**
The server automatically uses Redis for:
- File processing results (30 minutes)
- User state caching (5 minutes)
- Rate limiting counters

### **Connection Pooling**
PostgreSQL connection pool is optimized for:
- Min connections: 5
- Max connections: 20
- Idle timeout: 30 seconds

---

## 🛠️ **Troubleshooting**

### **Common Issues**

**1. Database Connection Errors**
```bash
# Check DATABASE_URL format
echo $DATABASE_URL
# Should be: postgresql://user:pass@host:5432/dbname
```

**2. Redis Connection Issues**
```bash
# Check Redis connectivity
redis-cli -u $REDIS_URL ping
# Should return: PONG
```

**3. File Upload Failures**
```bash
# Check file size limits
curl -I https://your-server.com/health
# Look for: max-file-size: 50MB
```

**4. Memory Issues**
```bash
# Monitor memory usage
curl https://your-server.com/api/file-processor/stats
# Check: memoryUsage field
```

### **Debugging Tools**
```bash
# Enable debug logging
NODE_ENV=development npm start

# Check specific logs
curl https://your-server.com/health | jq '.services'

# Monitor in real-time
curl -N https://your-server.com/debug/logs
```

---

## 📈 **Production Monitoring**

### **Key Metrics to Monitor**
1. **Response Time**: < 500ms average
2. **Error Rate**: < 1% of requests
3. **Memory Usage**: < 80% of available
4. **Disk Usage**: < 70% for temp files
5. **Active Connections**: Monitor concurrent users

### **Recommended Monitoring Tools**
- **Railway**: Built-in metrics dashboard
- **Heroku**: Heroku Metrics
- **Self-hosted**: Prometheus + Grafana
- **External**: UptimeRobot, DataDog

---

## 💰 **Cost Estimates**

### **Railway (Recommended)**
- **Starter**: $5/month (perfect for testing)
- **Pro**: $20/month (production ready)
- **Scale**: $40/month (high traffic)

### **Usage-Based Scaling**
- **1K users**: ~$10-15/month
- **10K users**: ~$20-30/month
- **100K users**: ~$50-100/month

### **Cost Optimization Tips**
1. Use Redis caching effectively
2. Implement request batching
3. Monitor and clean up temp files
4. Use CDN for static assets
5. Implement database query optimization

---

## 🎯 **Success Checklist**

✅ **Deployment Complete When:**

1. **Server Health**: `curl /health` returns 200 OK
2. **Database**: User states can be created/retrieved
3. **File Processing**: PDFs can be uploaded and processed
4. **Token Counting**: Accurate token counts for all models
5. **Security**: Rate limiting and CORS working
6. **Monitoring**: Metrics and logs accessible
7. **Android Integration**: App connects successfully

✅ **Production Ready When:**

1. **SSL/HTTPS**: All traffic encrypted
2. **Monitoring**: Alerts configured
3. **Backups**: Database backups scheduled
4. **Scaling**: Auto-scaling configured
5. **Documentation**: Team knows how to deploy/debug

---

## 🔗 **Next Steps After Deployment**

1. **Update Android App**: Change `SERVER_BASE_URL` to your domain
2. **Test All Features**: File upload, user state, token counting
3. **Monitor Performance**: Check logs and metrics daily for first week
4. **Setup Backups**: Configure automated database backups
5. **Document Operations**: Create runbook for your team

**Your users will now have enterprise-grade file processing and persistent user state! 🎉**