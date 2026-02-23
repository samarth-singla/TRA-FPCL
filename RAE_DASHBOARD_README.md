# RAE Dashboard Implementation Guide

## ✅ What's Been Implemented

### 1. **RAE Dashboard Screen** (`lib/screens/dashboard/rae_dashboard.dart`)

#### Features:
- ✅ **Welcome Header** - Personalized greeting with user's phone number
- ✅ **Active Orders Card** - Real-time count using StreamBuilder
- ✅ **Main Actions Grid** - 4 responsive cards:
  - Order Inputs (Blue)
  - Track Orders (Green)
  - Advisory (Purple)
  - Earnings (Amber)
- ✅ **Recent Alerts Section** - Latest 3 notifications with real-time updates

#### Real-time Features:
```dart
// Active Orders - StreamBuilder listening to Supabase
StreamBuilder<List<Map<String, dynamic>>>(
  stream: _supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('rae_uid', currentUser.id)
      .eq('status', 'active'),
  ...
)

// Recent Notifications - StreamBuilder with limit
StreamBuilder<List<Map<String, dynamic>>>(
  stream: _supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_uid', currentUser.id)
      .order('created_at', ascending: false)
      .limit(3),
  ...
)
```

### 2. **Dashboard Router** (`lib/main.dart`)
- ✅ Automatic role-based routing
- ✅ Fetches user profile from Supabase
- ✅ Routes to appropriate dashboard based on role (RAE, SME, ADMIN, SUPPLIER)
- ✅ Shows loading indicator while checking role

### 3. **Updated Dashboard Shell** (`lib/main.dart`)
- ✅ Now accepts custom title and child widget
- ✅ Works with any role-specific dashboard
- ✅ Maintains AppBar with sign-out functionality

---

## 📊 Required Supabase Tables

### Run the SQL in Supabase SQL Editor:

```bash
# File: SUPABASE_TABLES.sql
```

**Tables Created:**
1. ✅ **orders** - Stores all orders with status tracking
2. ✅ **notifications** - User notifications with read status

**Features:**
- ✅ Row Level Security (RLS) policies
- ✅ Realtime subscriptions enabled
- ✅ Indexes for performance
- ✅ Foreign key constraints

---

## 🚀 How to Use

### Step 1: Create Database Tables
1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Copy content from `SUPABASE_TABLES.sql`
4. Click **Run** to create tables

### Step 2: Test the Dashboard
```powershell
flutter run
```

### Step 3: Add Test Data (Optional)
```sql
-- Get your user UID from profiles table
SELECT uid FROM profiles;

-- Insert test notification
INSERT INTO notifications (user_uid, title, message, type)
VALUES ('YOUR_UID_HERE', 'Welcome!', 'Welcome to TRA FPCL', 'success');

-- Insert test order
INSERT INTO orders (rae_uid, product_name, quantity, unit, status)
VALUES ('YOUR_UID_HERE', 'Organic Fertilizer', 50, 'kg', 'active');
```

---

## 🎨 Dashboard Features

### Active Orders Counter
- **Real-time updates** using Supabase Stream
- Shows count of orders with `status = 'active'`
- Filtered by current user's UID
- Loading indicator while fetching

### Main Actions Grid
- **Responsive 2x2 grid**
- Each card navigates to respective feature:
  - **Order Inputs** → Create new orders
  - **Track Orders** → View order status
  - **Advisory** → Farming tips and guidance
  - **Earnings** → View payment history

### Recent Alerts
- **Latest 3 notifications** from database
- Real-time updates using StreamBuilder
- Shows:
  - Title and message
  - Timestamp (formatted as "2h ago", "1d ago", etc.)
  - Read/unread status (different styling)
- Empty state when no notifications

---

## 📱 UI Design

### Color Scheme:
- **Primary Actions**: Blue, Green, Purple, Amber
- **Active Orders**: Orange
- **Notifications**: Blue with opacity variations
- **Background**: Grey[100]

### Layout:
- **16px** padding around screen
- **24px** spacing between sections
- **16px** spacing in grids
- **Rounded corners**: 12-16px
- **Soft shadows** for elevation

---

## 🔄 Real-time Updates

### How it Works:
```dart
// StreamBuilder automatically rebuilds when data changes
_supabase
    .from('orders')
    .stream(primaryKey: ['id'])  // Required for realtime
    .eq('rae_uid', userId)       // Filter by user
    .eq('status', 'active')      // Filter by status
```

### When Changes Occur:
1. ✅ New order created → Counter updates instantly
2. ✅ Order status changes → Counter updates
3. ✅ New notification → Appears in Recent Alerts
4. ✅ Notification marked as read → Styling updates

---

## 🧪 Testing Checklist

- [ ] Login as RAE user
- [ ] Dashboard loads correctly
- [ ] Active Orders shows count (0 if no orders)
- [ ] All 4 action cards are visible and clickable
- [ ] Recent Alerts section shows notifications or empty state
- [ ] Sign out works correctly
- [ ] Real-time: Create order in Supabase → Counter updates
- [ ] Real-time: Create notification → Appears in alerts

---

## 🎯 Next Steps

### Immediate:
1. Implement **Order Inputs** screen
2. Implement **Track Orders** screen with map
3. Implement **Advisory** content system
4. Implement **Earnings** calculation and display

### Future Enhancements:
- [ ] Push notifications integration
- [ ] Offline support with local caching
- [ ] Charts for earnings trends
- [ ] Filter and search in Track Orders
- [ ] Notification categories and filtering
- [ ] Role-specific dashboards (SME, ADMIN, SUPPLIER)

---

## 📁 File Structure

```
lib/
├── main.dart                          # Updated with DashboardRouter
├── services/
│   └── auth_service.dart             # Authentication service
├── screens/
│   ├── auth/
│   │   ├── phone_login_screen.dart
│   │   └── otp_verification_screen.dart
│   └── dashboard/
│       └── rae_dashboard.dart        # NEW: RAE Dashboard
```

---

## 🐛 Troubleshooting

### Orders not showing?
- Check `orders` table exists in Supabase
- Verify RLS policies are enabled
- Ensure `rae_uid` matches your user ID
- Check realtime is enabled for `orders` table

### Notifications not appearing?
- Check `notifications` table exists
- Verify `user_uid` matches your user ID
- Ensure realtime subscription is active
- Check browser console for Supabase errors

### StreamBuilder stuck loading?
- Check internet connection
- Verify Supabase credentials in `main.dart`
- Check Supabase project status
- Review RLS policies (might be blocking access)

---

## 📚 Resources

- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [Flutter StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)
- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)

---

**Last Updated:** February 13, 2026
