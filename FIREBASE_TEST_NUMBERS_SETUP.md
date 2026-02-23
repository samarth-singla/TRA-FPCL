# Firebase Test Phone Numbers Setup Guide

## 🚨 Current Issue: OTP Verification Error

You're getting an OTP verification error because the test number setup might be incorrect.

---

## ✅ Step-by-Step Fix

### 1. Firebase Console Configuration

1. **Open Firebase Console**: https://console.firebase.google.com
2. **Select Project**: `tra-fpcl`
3. **Go To**: Authentication → Sign-in method
4. **Click**: Phone (should show "Enabled")
5. **Scroll Down** to: "Phone numbers for testing"

### 2. Add Test Phone Numbers (EXACT Format)

Click "Add phone number" and enter:

| Phone Number | Verification Code | Notes |
|-------------|------------------|-------|
| `+919999999999` | `123456` | Must be EXACTLY 6 digits |
| `+919876543210` | `111111` | Alternative number |

**⚠️ IMPORTANT**:
- Phone number MUST start with `+` (plus sign)
- Phone number MUST have country code (`+91` for India)
- NO spaces, NO dashes, NO parentheses
- Verification code MUST be EXACTLY 6 digits
- Click **SAVE** after adding

---

## 📱 How to Test

### In Your App:

1. **Phone Number**: Enter `9999999999` (app will add +91 automatically)
2. **Click**: "Send OTP"
3. **Wait for**: "OTP sent successfully" message
4. **Enter OTP**: Type `123456` (the code you set in Firebase)
5. **Click**: "Verify OTP"

---

## 🐛 Troubleshooting

### Error: "Invalid OTP code"

**Possible Causes:**
1. ❌ Test number not saved in Firebase (click Save!)
2. ❌ Wrong verification code (must match Firebase exactly)
3. ❌ Phone number format mismatch

**Solution:**
```
Firebase Test Number: +919999999999
App Input: 9999999999
Test Code: 123456
```

### Error: "Verification ID not found"

**Cause:** OTP wasn't sent properly

**Solution:**
1. Check internet connection
2. Make sure phone number is in test numbers list
3. Try sending OTP again

### Error: "Session expired"

**Cause:** Took too long (>60 seconds) to enter OTP

**Solution:**
1. Request new OTP
2. Enter code immediately

---

## 🔍 Verify Setup

Run this checklist:

- [ ] Firebase Console open
- [ ] Project: `tra-fpcl` selected
- [ ] Authentication → Sign-in method → Phone = Enabled
- [ ] Test number added: `+919999999999`
- [ ] Test code added: `123456`
- [ ] Clicked **SAVE** button
- [ ] No spaces/dashes in phone number
- [ ] Code is exactly 6 digits

---

## 📊 Terminal Logs to Watch

After updating the code, when you test login, you should see:

### ✅ Success Flow:
```
📱 Sending OTP to: +919999999999
ℹ️ If using test number, enter the test code you configured in Firebase
✅ OTP sent! Verification ID: ...
📝 For test numbers: Enter your configured test code (e.g., 123456)

[User enters OTP]

🔐 Verifying OTP: 123456 for role: RAE
✓ Verification ID exists: ...
📝 Credential created, attempting sign in...
🔄 Signing in with credential...
👤 Firebase user: [your-uid]
📝 Creating new profile with role: RAE
✅ New profile created for UID: [your-uid] with role: RAE
```

### ❌ Error Flow:
```
❌ Firebase Auth error: invalid-verification-code
```

**This means**: The code you entered doesn't match Firebase

---

## 🎯 Quick Test

**Try this RIGHT NOW:**

1. **Add to Firebase Console**:
   - Phone: `+919999999999`
   - Code: `123456`
   - **SAVE**

2. **In Your App**:
   - Enter: `9999999999`
   - Send OTP
   - Enter: `123456`
   - Verify

3. **Check Terminal** for the exact error

---

## 💡 Alternative: Use Real Phone Number

If test numbers don't work, enable real SMS:

1. **Upgrade Firebase** to Blaze plan
2. **Enable Billing** in Google Cloud Console
3. **Use your real number**
4. **Receive real SMS** with OTP

**Cost**: Free for first 10,000 verifications/month

---

## 📞 Need Help?

After following this guide:
1. Run: `flutter run`
2. Try login with `9999999999` and code `123456`
3. Copy the **EXACT error** from terminal
4. Share the error message

---

**Last Updated**: February 19, 2026
