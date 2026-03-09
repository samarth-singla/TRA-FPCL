# Wallet and Payment System Implementation Guide

## Overview

This document describes the wallet and payment system implementation for the TRA FPCL application, including:
- Wallet management for users
- Order payment workflow with SME approval
- Automatic refunds when orders are rejected after payment
- Transaction history tracking

---

## Architecture

### New Components

1. **Database Tables** (`SUPABASE_WALLET_TABLES.sql`)
   - `wallets` — User wallet balances
   - `transactions` — Payment/refund transaction records
   - Order table extensions for payment tracking

2. **Services**
   - `lib/services/wallet_service.dart` — Wallet and transaction management
   - Updated `lib/services/admin_service.dart` — Admin reject with refund logic
   - Updated `lib/services/sme_service.dart` — SME order approval with payment

3. **UI Screens**
   - `lib/screens/wallet/wallet_screen.dart` — Wallet balance and transaction history

---

## Order and Payment Workflow

### Step 1: RAE Places Order
- RAE adds products to cart and places order
- Order created with `status = 'pending'` and `payment_status = 'pending'`
- No payment taken at this stage

### Step 2: FPCL Chooses Supplier
- FPCL admin can view pending orders
- Admin assigns a supplier to the order (optional)
- Order remains in `pending` status

### Step 3: District Advisor (SME) Approves Order
- **CRITICAL STEP**: This is when payment is processed
- SME reviews orders from their district
- On approval:
  1. Payment deducted from RAE's wallet using `WalletService.makePayment()`
  2. Order updated with:
     - `payment_status = 'paid'`
     - `sme_approved_by = <sme_uid>`
     - `sme_approved_at = <timestamp>`
     - `payment_transaction_id = <transaction_id>`
  3. Transaction record created in `transactions` table
  4. RAE notified about payment

**Code Location:** `lib/services/sme_service.dart` → `approveOrder()` method

### Step 4: FPCL Admin Final Review
- Admin can approve (set `status = 'confirmed'`) or reject orders
- **If Admin Rejects After SME Approval:**
  1. System checks if `payment_status = 'paid'` and `sme_approved_by` exists
  2. Automatic refund processed using `WalletService.refund()`
  3. Order updated with:
     - `status = 'cancelled'`
     - `payment_status = 'refunded'`
     - `refund_transaction_id = <transaction_id>`
  4. Refund transaction created
  5. RAE notified about refund

**Code Location:** `lib/services/admin_service.dart` → `rejectOrder()` method

---

## Database Schema

### Wallets Table
```sql
CREATE TABLE wallets (
  id UUID PRIMARY KEY,
  user_uid TEXT NOT NULL UNIQUE,
  balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  user_uid TEXT NOT NULL,
  type TEXT NOT NULL,  -- 'deposit', 'payment', 'refund', 'withdrawal'
  amount DECIMAL(10, 2) NOT NULL,
  balance_after DECIMAL(10, 2) NOT NULL,
  order_id UUID,
  reference_type TEXT,
  description TEXT NOT NULL,
  status TEXT DEFAULT 'completed',
  notes TEXT,
  created_at TIMESTAMP
);
```

### Orders Table Extensions
```sql
ALTER TABLE orders ADD COLUMN payment_status TEXT DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN payment_transaction_id UUID;
ALTER TABLE orders ADD COLUMN refund_transaction_id UUID;
ALTER TABLE orders ADD COLUMN sme_approved_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN sme_approved_by TEXT;
```

---

## Setup Instructions

### 1. Run Database Migrations

Execute the SQL script in Supabase SQL Editor:

```bash
# In Supabase Dashboard > SQL Editor
# Run: SUPABASE_WALLET_TABLES.sql
```

This creates:
- `wallets` and `transactions` tables
- Extends `orders` table with payment fields
- Sets up triggers for auto-wallet creation

### 2. Initialize Existing User Wallets (Optional)

For existing RAE users who don't have wallets yet:

```sql
INSERT INTO wallets (user_uid, balance)
SELECT uid, 0.00
FROM profiles
WHERE role = 'RAE'
AND uid NOT IN (SELECT user_uid FROM wallets)
ON CONFLICT (user_uid) DO NOTHING;
```

### 3. Add Demo Balance for Testing

```sql
-- Add ₹10,000 to a test RAE's wallet
UPDATE wallets
SET balance = 10000.00
WHERE user_uid = '<your_test_rae_uid>';
```

---

## Integration Guide

### Access Wallet Screen from RAE Dashboard

Add a wallet button to the RAE dashboard header:

```dart
// In lib/screens/dashboard/rae_dashboard.dart
import '../wallet/wallet_screen.dart';

// Add to header actions
IconButton(
  icon: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 26),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WalletScreen()),
  ),
)
```

### Display Wallet Balance in Cart

Show available balance before checkout in shopping cart:

```dart
// In lib/screens/catalog/shopping_cart_screen.dart
import '../../services/wallet_service.dart';

// Add before proceed to checkout button
FutureBuilder<double>(
  future: WalletService().getBalance(_userUid),
  builder: (context, snapshot) {
    final balance = snapshot.data ?? 0.0;
    final canPay = balance >= cartService.total;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Wallet Balance:', style: TextStyle(fontSize: 14)),
            Text(
              '₹${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: canPay ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!canPay)
          Text(
            'Insufficient balance in wallet',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
      ],
    );
  },
)
```

### SME Dashboard - Order Approval Section

Add order approval section to SME dashboard:

```dart
// In lib/screens/dashboard/sme_dashboard.dart
import '../../services/sme_service.dart';

FutureBuilder<List<Map<String, dynamic>>>(
  future: _smeService.getPendingOrdersForDistrict(_smeUid),
  builder: (context, snapshot) {
    final orders = snapshot.data ?? [];
    if (orders.isEmpty) {
      return Text('No pending orders in your district');
    }
    
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return ListTile(
          title: Text('Order #${order['id']}'),
          subtitle: Text(
            '${order['rae_name']} - ₹${order['total_amount']}'
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  await _smeService.approveOrder(
                    orderId: order['id'],
                    smeUid: _smeUid,
                    smeName: _smeName,
                  );
                  setState(() {});
                },
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  await _smeService.rejectOrder(
                    orderId: order['id'],
                    smeUid: _smeUid,
                    reason: 'Rejected by district advisor',
                  );
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  },
)
```

---

## API Reference

### WalletService

#### getWallet(String userUid)
Returns wallet info for user. Creates wallet if doesn't exist.

```dart
final wallet = await WalletService().getWallet(raeUid);
print('Balance: ₹${wallet.balance}');
```

#### getBalance(String userUid)
Quick method to get just the balance amount.

```dart
final balance = await WalletService().getBalance(raeUid);
```

#### deposit()
Add funds to wallet.

```dart
await WalletService().deposit(
  userUid: raeUid,
  amount: 5000.00,
  description: 'Wallet recharge',
  notes: 'Manual credit',
);
```

#### makePayment()
Deduct funds for order payment. Throws error if insufficient balance.

```dart
try {
  final txn = await WalletService().makePayment(
    userUid: raeUid,
    amount: orderTotal,
    orderId: orderId,
    description: 'Payment for order',
  );
  print('Payment ID: ${txn.id}');
} catch (e) {
  print('Payment failed: $e');
}
```

#### refund()
Return funds to wallet.

```dart
final txn = await WalletService().refund(
  userUid: raeUid,
  amount: orderTotal,
  orderId: orderId,
  description: 'Refund for cancelled order',
);
```

#### getTransactions()
Get transaction history.

```dart
final txns = await WalletService().getTransactions(
  userUid: raeUid,
  limit: 50,
  type: 'payment', // optional filter
);
```

#### walletStream() / transactionsStream()
Real-time streams for reactive UI.

```dart
StreamBuilder<WalletInfo>(
  stream: WalletService().walletStream(raeUid),
  builder: (context, snapshot) {
    final balance = snapshot.data?.balance ?? 0.0;
    return Text('₹$balance');
  },
)
```

### SmeService

#### approveOrder()
Approve order and process payment.

```dart
await SmeService().approveOrder(
  orderId: orderId,
  smeUid: smeUid,
  smeName: 'District Advisor Name',
);
```

#### rejectOrder()
Reject order (no payment if not yet approved).

```dart
await SmeService().rejectOrder(
  orderId: orderId,
  smeUid: smeUid,
  reason: 'Insufficient documentation',
);
```

#### getPendingOrdersForDistrict()
Get all pending orders for SME's district.

```dart
final orders = await SmeService().getPendingOrdersForDistrict(smeUid);
```

### AdminService

#### rejectOrder() — Updated with Auto-Refund
Rejects order. Automatically refunds if payment was made.

```dart
await AdminService().rejectOrder(orderId, 'Quality issue');
// Checks payment_status and processes refund if needed
```

---

## Testing Checklist

### Prerequisites
- [ ] Run `SUPABASE_WALLET_TABLES.sql` migration
- [ ] Create test RAE account
- [ ] Add test balance to RAE wallet
- [ ] Create test SME account
- [ ] Create test Admin account

### Test Scenarios

#### Scenario 1: Normal Order Flow
1. [ ] RAE places order (payment pending)
2. [ ] Admin assigns supplier
3. [ ] SME approves order → Payment deducted
4. [ ] Check RAE wallet balance decreased
5. [ ] Check transaction created with type='payment'
6. [ ] Admin approves order → Order confirmed
7. [ ] No refund triggered

#### Scenario 2: Reject Before SME Approval
1. [ ] RAE places order
2. [ ] Admin rejects immediately
3. [ ] Order cancelled, no payment made
4. [ ] RAE wallet balance unchanged

#### Scenario 3: Reject After SME Approval (Refund)
1. [ ] RAE places order
2. [ ] SME approves → Payment deducted
3. [ ] Admin rejects order
4. [ ] **System auto-refunds to wallet**
5. [ ] Check RAE wallet balance restored
6. [ ] Check refund transaction created
7. [ ] Check order status = 'cancelled', payment_status = 'refunded'
8. [ ] Verify RAE received refund notification

#### Scenario 4: Insufficient Balance
1. [ ] RAE with ₹0 wallet tries to place order
2. [ ] SME approves
3. [ ] Payment fails with "Insufficient balance" error
4. [ ] Order remains unpaid
5. [ ] RAE prompted to add funds

#### Scenario 5: Wallet UI
1. [ ] Navigate to Wallet screen
2. [ ] Check balance displays correctly
3. [ ] Check transaction history shows all records
4. [ ] Add funds using dialog
5. [ ] Verify balance updates in real-time
6. [ ] Check credits show in green, debits in red

---

## Troubleshooting

### Payment Not Deducted When SME Approves
- Check SME service `approveOrder()` method is being called
- Verify wallet service is imported correctly
- Check console for error messages
- Ensure RAE has sufficient balance

### Refund Not Processed on Admin Reject
- Verify order has `payment_status = 'paid'`
- Check `sme_approved_by` field is not null
- Look for error in admin service `rejectOrder()` method
- Check wallet service `refund()` for exceptions

### Wallet Balance Not Updating
- Check if `wallets` table has RLS disabled
- Verify Supabase realtime is enabled for `wallets` table
- Check if wallet was created for user (run wallet initialization SQL)

### Transactions Not Showing
- Verify `transactions` table exists and RLS is disabled
- Check if transaction records are being created (query Supabase directly)
- Ensure realtime subscription is active

---

## Security Considerations

1. **Balance Validation**: Always validate sufficient balance before payment
2. **Transaction Atomicity**: Each payment/refund is atomic (single transaction)
3. **Duplicate Prevention**: Check order payment_status before processing
4. **Audit Trail**: All transactions logged with timestamps and references
5. **RLS Disabled**: Using Firebase Auth, not Supabase Auth (RLS would block)

---

## Future Enhancements

- [ ] Payment gateway integration (Razorpay, Stripe)
- [ ] Wallet top-up via UPI
- [ ] Withdrawal to bank account
- [ ] Transaction export to PDF
- [ ] Admin wallet management dashboard
- [ ] Automated reconciliation reports
- [ ] Multi-currency support
- [ ] Wallet freeze/unfreeze functionality
- [ ] Transaction dispute resolution

---

## Support

For issues or questions:
1. Check console logs for detailed error messages
2. Verify database schema is up to date
3. Review this documentation
4. Test with demo data first

---

*Last Updated: March 9, 2026*
