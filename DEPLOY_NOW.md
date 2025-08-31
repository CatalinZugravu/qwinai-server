# 🚀 DEPLOY CREDIT SYSTEM FIX NOW

## ✅ **Code is Ready - Deploy Immediately**

Your credit system fixes are **committed and pushed** to GitHub. Now deploy to Railway:

---

## 📋 **DEPLOYMENT STEPS (5 minutes)**

### **Step 1: Railway Setup**
1. **Go to**: [railway.app](https://railway.app)  
2. **Sign in** with GitHub
3. **Click**: "New Project" 
4. **Select**: "Deploy from GitHub repo"
5. **Choose**: `CatalinZugravu/qwinai-server`
6. **Click**: "Deploy Now"

### **Step 2: Add Database**
1. In Railway dashboard, **click**: "New" → "Database" → "PostgreSQL"
2. **Wait** for PostgreSQL to initialize (1-2 minutes)
3. Railway auto-generates `DATABASE_URL` environment variable

### **Step 3: Add Redis** 
1. **Click**: "New" → "Database" → "Redis" 
2. Railway auto-generates `REDIS_URL` environment variable

### **Step 4: Configure Environment Variables**
In Railway dashboard → **Variables** tab, add:
```
NODE_ENV=production
JWT_SECRET=your_32_char_random_secret_here_generate_new_one
ADMIN_RESET_KEY=your_admin_reset_key_for_testing
ALLOWED_ORIGINS=https://your-domain.com
```

### **Step 5: Get Your Railway URL** 
1. Railway will show your URL like: `https://your-app-name.up.railway.app`
2. **Copy this URL** - you'll need it for Android app

---

## 🗄️ **DATABASE MIGRATION (CRITICAL)**

Once deployed, run the migration to add ad credits columns:

### **Option A: Railway Console**
1. In Railway dashboard → **your PostgreSQL service** 
2. Click **"Connect"** → **"Query"**
3. **Paste and run** this SQL:

```sql
-- Add ad credits columns
ALTER TABLE user_states 
ADD COLUMN IF NOT EXISTS ad_credits_chat_today INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS ad_credits_image_today INTEGER DEFAULT 0;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_states_ad_credits 
ON user_states(ad_credits_chat_today, ad_credits_image_today);

-- Test query to verify
SELECT 
    device_id,
    credits_consumed_today_chat,
    ad_credits_chat_today,
    (15 + COALESCE(ad_credits_chat_today, 0) - credits_consumed_today_chat) AS available_chat_credits
FROM user_states 
LIMIT 3;
```

### **Option B: Command Line**
```bash
# Get DATABASE_URL from Railway dashboard
export DATABASE_URL="your_railway_database_url_here"

# Run migration
psql $DATABASE_URL -f migrations/add_ad_credits.sql
```

---

## 🧪 **TEST YOUR DEPLOYMENT**

### **1. Health Check**
```bash
# Replace YOUR_URL with your Railway URL
curl https://YOUR_URL.up.railway.app/health
```
**Expected Result**: `{"status":"OK","timestamp":"...","services":{...}}`

### **2. Test New User (Should Get 15/20 Credits)**
```bash
curl "https://YOUR_URL.up.railway.app/api/user-state/TESTDEVICE123?fingerprint=testfingerprint123"
```
**✅ Expected Result**: 
```json
{
  "availableChatCredits": 15,
  "availableImageCredits": 20,
  "creditsConsumedTodayChat": 0,
  "creditsConsumedTodayImage": 0
}
```

### **3. Test Credit Consumption**
```bash
curl -X POST "https://YOUR_URL.up.railway.app/api/user-state/TESTDEVICE123/consume-credits" \
  -H "Content-Type: application/json" \
  -d '{
    "creditType": "chat",
    "amount": 3,
    "fingerprint": "testfingerprint123"
  }'
```
**✅ Expected Result**: 
```json
{
  "success": true,
  "message": "Successfully consumed 3 chat credits",
  "data": {
    "availableCredits": 12,
    "totalConsumedToday": 3
  }
}
```

### **4. Test Reinstall Detection**
```bash
# Same fingerprint, different device ID (simulates reinstall)
curl -X POST "https://YOUR_URL.up.railway.app/api/user-state/NEWDEVICE456/consume-credits" \
  -H "Content-Type: application/json" \
  -d '{
    "creditType": "chat", 
    "amount": 1,
    "fingerprint": "testfingerprint123"
  }'
```
**✅ Expected**: Should find existing user, consume 1 more credit (total: 4 consumed, 11 available)

### **5. Test Ad Credits**
```bash
curl -X POST "https://YOUR_URL.up.railway.app/api/user-state/TESTDEVICE123/add-ad-credits" \
  -H "Content-Type: application/json" \
  -d '{
    "creditType": "chat",
    "fingerprint": "testfingerprint123"  
  }'
```
**✅ Expected**: Adds 1 ad credit, total available becomes 12 (11 + 1 ad credit)

---

## 📱 **UPDATE ANDROID APP**

Once deployed, update your Android app:

### **File**: `app/src/main/java/com/cyberflux/qwinai/security/UserStateManager.kt`
```kotlin
// Line 48 - Replace with YOUR Railway URL
internal const val SERVER_BASE_URL = "https://YOUR_URL.up.railway.app/api/"
```

### **Rebuild and Test App**
1. **Build**: `./gradlew assembleDebug` 
2. **Install**: `./gradlew installDebug`
3. **Test**: New users should get 15 chat + 20 image credits
4. **Test**: Reinstall should preserve consumed credits

---

## 🎉 **SUCCESS INDICATORS**

Your system is working when you see these **new log messages**:

### **✅ Good Logs:**
```
👤 NEW USER detected: abc123 - Available credits: chat=15, image=20
🔥 [127.0.0.1] CONSUMING 3 chat credits for device: abc123  
✅ CONSUMED 3 chat credits for abc123: 0 → 3 (12 remaining)
🔒 REINSTALL DETECTED: Found user by fingerprint, updating device_id
📺 [127.0.0.1] Adding AD credits (chat) for device: abc123
✅ Added 1 AD credit for chat: 0 → 1
```

### **❌ Old Broken Logs (should NOT see):**
```
✅ User state retrieved: chat=0, image=0  # ← This was the bug!
👤 New user detected: newdevice1234567   # ← Should show credits
🔄 Resetting daily credits... chat=0     # ← Should be 15/20
```

---

## 🚨 **IF DEPLOYMENT FAILS**

### **Common Issues:**

1. **"Build Failed"**
   - Check Railway logs for Node.js version
   - Ensure `package.json` has correct `engines` field

2. **"Database Connection Failed"**  
   - Verify PostgreSQL service is running in Railway
   - Check `DATABASE_URL` environment variable exists

3. **"Migration Failed"**
   - Check if `user_states` table exists
   - Run table creation SQL first if needed

### **Alternative: Manual Database Setup**
If migration fails, create the table manually:

```sql
-- Run this in Railway PostgreSQL console
CREATE TABLE IF NOT EXISTS user_states (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(32) UNIQUE NOT NULL,
    device_fingerprint TEXT,
    credits_consumed_today_chat INTEGER DEFAULT 0,
    credits_consumed_today_image INTEGER DEFAULT 0,
    ad_credits_chat_today INTEGER DEFAULT 0,
    ad_credits_image_today INTEGER DEFAULT 0,
    has_active_subscription BOOLEAN DEFAULT false,
    subscription_type VARCHAR(50),
    subscription_end_time BIGINT DEFAULT 0,
    tracking_date DATE DEFAULT CURRENT_DATE,
    app_version VARCHAR(10) DEFAULT '18',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 📞 **Support Commands**

If you need help debugging:

```bash
# Check Railway deployment status
curl -I https://YOUR_URL.up.railway.app/health

# View recent users (debugging)
curl "https://YOUR_URL.up.railway.app/api/user-state/TESTDEVICE/stats"

# Force reset a user (testing)
curl -X POST "https://YOUR_URL.up.railway.app/api/user-state/TESTDEVICE/reset" \
  -H "Content-Type: application/json" \
  -d '{"adminKey":"your_admin_key","reason":"testing"}'
```

---

## 🎯 **DEPLOYMENT COMPLETE WHEN:**

✅ Health endpoint returns 200 OK  
✅ Database migration completed successfully  
✅ New users get 15 chat + 20 image credits  
✅ Credit consumption works and shows remaining  
✅ Daily reset gives proper defaults (not 0)  
✅ Reinstall detection prevents credit abuse  
✅ Ad credits can be earned and tracked  
✅ Android app connects and shows proper credits  

**Your credit abuse problem is now FIXED! 🎉**