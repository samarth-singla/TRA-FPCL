-- Supabase Tables for TRA FPCL Application
-- Run these SQL commands in Supabase SQL Editor

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
  uid TEXT PRIMARY KEY,
  phone TEXT,
  role TEXT DEFAULT 'RAE',
  name TEXT,
  email TEXT,
  district TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Products Table
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  unit TEXT NOT NULL,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);

-- 3. Orders Table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rae_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  sme_uid TEXT REFERENCES profiles(uid) ON DELETE SET NULL,
  supplier_uid TEXT REFERENCES profiles(uid) ON DELETE SET NULL,
  
  -- Order Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  
  -- Pricing
  subtotal DECIMAL(10, 2) NOT NULL,
  gst_amount DECIMAL(10, 2) NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  
  -- Additional Details
  delivery_address TEXT,
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_orders_rae_uid ON orders(rae_uid);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- 4. Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price_per_unit DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- 5. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  
  -- Notification Content
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success')),
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  
  -- Optional Reference
  reference_type TEXT, -- e.g., 'order', 'advisory', 'payment'
  reference_id UUID,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_uid ON notifications(user_uid);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- 6. Disable Row Level Security on all tables
-- This app uses Firebase Auth (not Supabase Auth), so auth.uid() is always
-- NULL. RLS with auth.uid() checks would block ALL reads/writes silently.
-- Security is handled by Firebase Auth on the client side.
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- 11. Realtime Subscriptions for core tables
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_items;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================================
-- SME (District Advisor) Tables
-- ============================================================

-- SME Conversations Table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rae_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  sme_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  rae_name TEXT NOT NULL DEFAULT '',
  rae_code TEXT NOT NULL DEFAULT '',
  last_message TEXT NOT NULL DEFAULT '',
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  unread_count INTEGER NOT NULL DEFAULT 0,
  is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversations_sme_uid ON conversations(sme_uid);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON conversations(last_message_at DESC);

-- SME Issues / Complaints Table
CREATE TABLE IF NOT EXISTS issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rae_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  sme_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  rae_name TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_issues_sme_uid ON issues(sme_uid);
CREATE INDEX IF NOT EXISTS idx_issues_status ON issues(status);
CREATE INDEX IF NOT EXISTS idx_issues_created_at ON issues(created_at DESC);

-- SME Performance Metrics Table
CREATE TABLE IF NOT EXISTS sme_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sme_uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  active_raes INTEGER NOT NULL DEFAULT 0,
  total_raes INTEGER NOT NULL DEFAULT 50,
  villages_covered INTEGER NOT NULL DEFAULT 0,
  farmers_served INTEGER NOT NULL DEFAULT 0,
  district TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sme_metrics_sme_uid ON sme_metrics(sme_uid);

-- Disable RLS on SME tables (same reason: Firebase Auth, not Supabase Auth)
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE issues DISABLE ROW LEVEL SECURITY;
ALTER TABLE sme_metrics DISABLE ROW LEVEL SECURITY;

-- Realtime Subscriptions for SME tables
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE issues;

-- Sample seed data for SME (replace 'REPLACE_WITH_SME_UID' with actual uid)
-- INSERT INTO conversations (rae_uid, sme_uid, rae_name, rae_code, last_message, unread_count)
-- VALUES ('rae_uid_here', 'sme_uid_here', 'Ramesh Kumar', 'RAE-HYD-001', 'Need advice on cotton seeds', 2);

-- 12. Sample Data for Testing (Optional)
-- Insert sample products
INSERT INTO products (name, description, category, price, unit, stock_quantity, is_active)
VALUES 
  ('Organic Fertilizer NPK 10-26-26', 'Premium organic fertilizer for better crop yield', 'Fertilizers', 850.00, 'kg', 1000, true),
  ('Urea (46% N)', 'Nitrogen fertilizer for leafy growth', 'Fertilizers', 320.00, 'kg', 2000, true),
  ('DAP (18-46-0)', 'Di-Ammonium Phosphate for root development', 'Fertilizers', 1250.00, 'kg', 1500, true),
  ('Wheat Seeds - HD 2967', 'High-yielding wheat variety', 'Seeds', 35.00, 'kg', 500, true),
  ('Paddy Seeds - Pusa Basmati 1121', 'Premium basmati rice seeds', 'Seeds', 120.00, 'kg', 300, true),
  ('Corn Seeds - Hybrid 900M', 'Hybrid corn seeds for high productivity', 'Seeds', 280.00, 'kg', 400, true),
  ('Neem Oil Pesticide', 'Organic pest control solution', 'Pesticides', 450.00, 'liter', 200, true),
  ('Chlorpyrifos 20% EC', 'Effective insecticide for various pests', 'Pesticides', 320.00, 'liter', 150, true),
  ('NPK Spray (19-19-19)', 'Foliar fertilizer spray', 'Fertilizers', 540.00, 'kg', 800, true),
  ('Bio Fungicide', 'Organic fungal disease control', 'Pesticides', 680.00, 'liter', 100, true)
ON CONFLICT DO NOTHING;

-- Insert sample notifications
-- INSERT INTO notifications (user_uid, title, message, type)
-- VALUES 
--   ('your-user-uid-here', 'Welcome!', 'Welcome to TRA FPCL. Your account is now active.', 'success'),
--   ('your-user-uid-here', 'New Advisory', 'Check out the latest farming advisory for this season.', 'info'),
--   ('your-user-uid-here', 'Order Update', 'Your recent order has been confirmed.', 'success');

-- Insert sample orders
-- INSERT INTO orders (rae_uid, product_name, quantity, unit, status)
-- VALUES 
--   ('your-user-uid-here', 'Organic Fertilizer', 50, 'kg', 'active'),
--   ('your-user-uid-here', 'Seeds - Wheat', 10, 'kg', 'processing');
