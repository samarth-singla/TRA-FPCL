# Wallet & Payment System - Quick Start

## What's Been Implemented

A complete wallet and payment system with the following workflow:

1. **FPCL chooses supplier** for pending orders
2. **District Advisor (SME) approves order** → Payment automatically deducted from RAE's wallet  
3. **FPCL admin makes final approval or rejection**
4. **If admin rejects after SME approval** → Payment automatically refunded to RAE's wallet

---

## Files Created/Modified

### New Files
1. `SUPABASE_WALLET_TABLES.sql` - Database schema for wallets & transactions
2. `lib/services/wallet_service.dart` - Wallet management service
3. `lib/screens/wallet/wallet_screen.dart` - Wallet UI for RAEs
4. `WALLET_PAYMENT_IMPLEMENTATION_GUIDE.md` - Complete documentation

### Modified Files
1. `lib/services/admin_service.dart` - Added refund logic in rejectOrder()
2. `lib/services/sme_service.dart` - Added order approval with payment

---

## Quick Setup (3 Steps)

### Step 1: Run Database Migration

Go to Supabase SQL Editor and run:

```bash
SUPABASE_WALLET_TABLES.sql
```

This creates the wallet tables and extends the orders table with payment tracking fields.

### Step 2: Add Test Balance

For testing, add balance to a RAE's wallet:

```sql
-- Find your test RAE's uid
SELECT uid, name, role FROM profiles WHERE role = 'RAE';

-- Add ₹10,000 test balance
UPDATE wallets
SET balance = 10000.00
WHERE user_uid = '<your_rae_uid>';

-- Or insert if wallet doesn't exist
INSERT INTO wallets (user_uid, balance)
VALUES ('<your_rae_uid>', 10000.00)
ON CONFLICT (user_uid) 
DO UPDATE SET balance = 10000.00;
```

### Step 3: Add Wallet Button to RAE Dashboard

In [lib/screens/dashboard/rae_dashboard.dart](lib/screens/dashboard/rae_dashboard.dart), add to the header:

```dart
import '../wallet/wallet_screen.dart';

// In the header Row with profile icon, add:
IconButton(
  icon: const Icon(Icons.account_balance_wallet, 
      color: Colors.white, size: 26),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WalletScreen()),
  ),
  tooltip: 'My Wallet',
)
```

---

## Test the Workflow

### Test 1: Normal Flow (No Refund)
1. **RAE**: Place an order
2. **SME**: Approve order (payment deducted from wallet)
3. **Admin**: Approve order (no refund)
4. ✅ Order confirmed, RAE paid

### Test 2: Refund Flow
1. **RAE**: Place an order
2. **SME**: Approve order (payment deducted from wallet)
3. **Admin**: Reject order
4. ✅ **Payment automatically refunded to RAE's wallet**

### Test 3: View Wallet
1. **RAE**: Open wallet screen
2. See balance and all transactions
3. Add funds using "Add Funds" button (demo only)

---

## Order Status & Payment Status

### Order Status
- `pending` - Waiting for SME/Admin approval
- `confirmed` - Approved by admin, ready for processing  
- `cancelled` - Rejected

### Payment Status
- `pending` - No payment yet
- `paid` - Payment deducted (after SME approves)
- `refunded` - Payment returned (if admin rejects after SME approval)

---

## Key Features

✅ **Automatic Payment on SME Approval** - No manual payment step needed  
✅ **Automatic Refunds** - System detects paid orders and refunds when rejected  
✅ **Transaction History** - Complete audit trail of all payments/refunds  
✅ **Real-time Balance** - Wallet balance updates instantly via Supabase realtime  
✅ **Insufficient Balance Handling** - Prevents order approval if wallet balance too low  
✅ **Notifications** - RAEs notified of payments and refunds  

---

## Important Notes

### For RAEs:
- Check wallet balance before placing large orders
- Use "Add Funds" to top up wallet (demo feature, integrate payment gateway in production)
- View all transactions in wallet screen

### For SMEs (District Advisors):
- When you approve an order, payment is immediately deducted from RAE's wallet
- If insufficient balance, approval will fail with error message
- Only approve orders you're confident admin will also approve (to avoid refunds)

### For Admins:
- If you reject an order that SME already approved, system automatically refunds RAE
- Check payment status in order details to see if refund will be triggered
- Supplier selection can be done before or after SME approval

---

## Next Steps

1. **Run the database migration** (SUPABASE_WALLET_TABLES.sql)
2. **Add test balance** to a RAE wallet
3. **Add wallet button** to RAE dashboard
4. **Test the workflow** with test orders

For detailed documentation, see [WALLET_PAYMENT_IMPLEMENTATION_GUIDE.md](WALLET_PAYMENT_IMPLEMENTATION_GUIDE.md)

---

## Screenshots/UI Components

### Wallet Screen Features:
- Large balance card with gradient design
- "Add Funds" and "History" buttons
- Transaction list with icons (payments, refunds, deposits)
- Color-coded transactions (green for credits, red for debits)
- Real-time updates

### Transaction Types:
- 🟢 **Deposit** - Wallet recharge
- 🔴 **Payment** - Order payment (when SME approves)
- 🟢 **Refund** - Order refund (when admin rejects after payment)
- 🔴 **Withdrawal** - Cash withdrawal (future feature)

---

*Ready to use! Run the migration and start testing.* 🚀
