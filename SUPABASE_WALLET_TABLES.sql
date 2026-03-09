-- ============================================================
-- Wallet and Payment System Tables
-- Run these SQL commands in Supabase SQL Editor
-- ============================================================

-- 1. Wallets Table
-- Stores wallet balance for each user (primarily RAEs)
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uid TEXT NOT NULL UNIQUE REFERENCES profiles(uid) ON DELETE CASCADE,
  balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_user_uid ON wallets(user_uid);

-- 2. Transactions Table
-- Records all wallet transactions (deposits, payments, refunds)
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  
  -- Transaction Type
  type TEXT NOT NULL CHECK (type IN ('deposit', 'payment', 'refund', 'withdrawal')),
  
  -- Amount (positive for credits, stored as absolute value)
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  
  -- Balance after transaction
  balance_after DECIMAL(10, 2) NOT NULL,
  
  -- Reference to related entities
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  reference_type TEXT, -- 'order_payment', 'order_refund', 'manual_deposit', etc.
  reference_id TEXT,
  
  -- Description
  description TEXT NOT NULL,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
  
  -- Metadata
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_uid ON transactions(user_uid);
CREATE INDEX IF NOT EXISTS idx_transactions_order_id ON transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);

-- 3. Order Payment Status Tracking
-- Add new columns to orders table for payment tracking
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending' 
  CHECK (payment_status IN ('pending', 'awaiting_sme_approval', 'paid', 'refunded'));
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_transaction_id UUID REFERENCES transactions(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS refund_transaction_id UUID REFERENCES transactions(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS sme_approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS sme_approved_by TEXT REFERENCES profiles(uid);

-- 4. Disable Row Level Security (using Firebase Auth)
ALTER TABLE wallets DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;

-- 5. Enable Realtime Subscriptions
ALTER PUBLICATION supabase_realtime ADD TABLE wallets;
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;

-- 6. Function to initialize wallet for new users
CREATE OR REPLACE FUNCTION initialize_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create wallet for RAE and SUPPLIER roles
  IF NEW.role IN ('RAE', 'SUPPLIER') THEN
    INSERT INTO wallets (user_uid, balance)
    VALUES (NEW.uid, 0.00)
    ON CONFLICT (user_uid) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger to auto-create wallet on user profile creation
DROP TRIGGER IF EXISTS trigger_initialize_wallet ON profiles;
CREATE TRIGGER trigger_initialize_wallet
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION initialize_wallet_for_user();

-- 8. Function to update wallet updated_at timestamp
CREATE OR REPLACE FUNCTION update_wallet_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_wallet_timestamp ON wallets;
CREATE TRIGGER trigger_update_wallet_timestamp
  BEFORE UPDATE ON wallets
  FOR EACH ROW
  EXECUTE FUNCTION update_wallet_timestamp();
