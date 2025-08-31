@echo off
echo.
echo 🚀 QWINAI CREDIT SYSTEM FIX - QUICK DEPLOY
echo ================================================
echo.
echo ✅ Code is already committed and pushed to GitHub!
echo ✅ All credit system issues are FIXED in the code!
echo.
echo 📋 MANUAL STEPS REQUIRED:
echo.
echo 1. Go to: https://railway.app
echo 2. Sign in with GitHub
echo 3. Click "New Project" → "Deploy from GitHub repo"
echo 4. Select: CatalinZugravu/qwinai-server
echo 5. Click "Deploy Now"
echo.
echo 6. Add PostgreSQL: New → Database → PostgreSQL
echo 7. Add Redis: New → Database → Redis
echo.
echo 8. Add Environment Variables:
echo    NODE_ENV=production
echo    JWT_SECRET=[generate 32 char secret]
echo    ADMIN_RESET_KEY=[your admin key]
echo.
echo 9. Get your Railway URL (something like: https://xyz.up.railway.app)
echo.
echo 📋 After deployment, run database migration:
echo.
echo In Railway PostgreSQL console, run:
echo ALTER TABLE user_states ADD COLUMN IF NOT EXISTS ad_credits_chat_today INTEGER DEFAULT 0;
echo ALTER TABLE user_states ADD COLUMN IF NOT EXISTS ad_credits_image_today INTEGER DEFAULT 0;
echo.
echo 🧪 Test with:
echo curl https://YOUR_URL.up.railway.app/health
echo curl "https://YOUR_URL.up.railway.app/api/user-state/TEST123?fingerprint=test"
echo.
echo Expected: {"availableChatCredits":15,"availableImageCredits":20}
echo.
echo 📱 Update Android app UserStateManager.kt with your Railway URL
echo.
echo 🎉 Your credit system abuse prevention is now READY TO DEPLOY!
echo.
pause