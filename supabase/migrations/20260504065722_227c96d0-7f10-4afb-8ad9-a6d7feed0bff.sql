
-- ============= EXTENSIONS / HELPERS =============
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

-- ============= APP SETTINGS =============
CREATE TABLE public.app_settings (
  id text PRIMARY KEY DEFAULT 'main',
  active_theme text DEFAULT 'default',
  active_template text DEFAULT 'classic',
  platform_name text DEFAULT 'الوكيل',
  invoice_name text DEFAULT 'الوكيل',
  master_password text DEFAULT '01278006248',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "settings public read" ON public.app_settings FOR SELECT USING (true);
CREATE POLICY "settings public write" ON public.app_settings FOR ALL USING (true) WITH CHECK (true);
INSERT INTO public.app_settings(id, platform_name, invoice_name, master_password)
VALUES ('main','الوكيل','الوكيل','01278006248')
ON CONFLICT (id) DO UPDATE SET platform_name='الوكيل', invoice_name='الوكيل', master_password='01278006248', updated_at=now();

-- ============= SYSTEM PASSWORDS =============
CREATE TABLE public.system_passwords (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  password_type text UNIQUE NOT NULL,
  password text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.system_passwords ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sp public" ON public.system_passwords FOR ALL USING (true) WITH CHECK (true);
INSERT INTO public.system_passwords(password_type, password) VALUES
  ('master','01278006248'),
  ('payment','01278006248'),
  ('admin_delete','01278006248'),
  ('treasury','01278006248');

-- ============= ADMIN USERS / PERMISSIONS =============
CREATE TABLE public.admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text UNIQUE NOT NULL,
  password text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  is_owner boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "au public" ON public.admin_users FOR ALL USING (true) WITH CHECK (true);

CREATE TABLE public.admin_user_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.admin_users(id) ON DELETE CASCADE,
  permission text NOT NULL,
  permission_type text NOT NULL DEFAULT 'view',
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_user_permissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "aup public" ON public.admin_user_permissions FOR ALL USING (true) WITH CHECK (true);

-- Owner user with all permissions
INSERT INTO public.admin_users(username, password, is_owner) VALUES ('owner','01278006248', true);
INSERT INTO public.admin_user_permissions(user_id, permission, permission_type)
SELECT id, p, 'edit' FROM public.admin_users, unnest(ARRAY[
  'dashboard','products','categories','orders','all_orders','customers','agents','agent_orders',
  'cashbox','treasury','statistics','invoices','governorates','offices','appearance','user_management',
  'activity_logs','reset_data'
]) p WHERE username='owner';

-- ============= ACTIVITY LOGS =============
CREATE TABLE public.activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  username text,
  action text NOT NULL,
  section text,
  details jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "al public" ON public.activity_logs FOR ALL USING (true) WITH CHECK (true);

-- ============= CATEGORIES =============
CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  image_url text,
  display_order int DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cat public" ON public.categories FOR ALL USING (true) WITH CHECK (true);

-- ============= PRODUCTS =============
CREATE TABLE public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  details text,
  price numeric NOT NULL DEFAULT 0,
  offer_price numeric,
  is_offer boolean NOT NULL DEFAULT false,
  stock int NOT NULL DEFAULT 0,
  image_url text,
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  size_options text[],
  color_options text[],
  quantity_pricing jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prod public" ON public.products FOR ALL USING (true) WITH CHECK (true);

CREATE TABLE public.product_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  display_order int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pi public" ON public.product_images FOR ALL USING (true) WITH CHECK (true);

CREATE TABLE public.product_color_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  color text NOT NULL,
  image_url text,
  stock int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.product_color_variants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pcv public" ON public.product_color_variants FOR ALL USING (true) WITH CHECK (true);

-- ============= GOVERNORATES =============
CREATE TABLE public.governorates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  shipping_cost numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.governorates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gov public" ON public.governorates FOR ALL USING (true) WITH CHECK (true);

-- ============= OFFICES =============
CREATE TABLE public.offices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  logo_url text,
  watermark_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.offices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "off public" ON public.offices FOR ALL USING (true) WITH CHECK (true);

-- ============= CUSTOMERS =============
CREATE TABLE public.customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phone text NOT NULL,
  phone2 text,
  address text,
  governorate text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX customers_phone_unique ON public.customers(phone) WHERE phone <> 'غير متوفر';
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cust public" ON public.customers FOR ALL USING (true) WITH CHECK (true);

-- ============= DELIVERY AGENTS =============
CREATE TABLE public.delivery_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phone text,
  total_owed numeric NOT NULL DEFAULT 0,
  total_paid numeric NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.delivery_agents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "da public" ON public.delivery_agents FOR ALL USING (true) WITH CHECK (true);

-- ============= ORDERS =============
CREATE SEQUENCE IF NOT EXISTS public.orders_order_number_seq START 1;
CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number bigint UNIQUE DEFAULT nextval('public.orders_order_number_seq'),
  customer_id uuid REFERENCES public.customers(id) ON DELETE SET NULL,
  delivery_agent_id uuid REFERENCES public.delivery_agents(id) ON DELETE SET NULL,
  governorate_id uuid REFERENCES public.governorates(id) ON DELETE SET NULL,
  total_amount numeric NOT NULL DEFAULT 0,
  shipping_cost numeric NOT NULL DEFAULT 0,
  agent_shipping_cost numeric NOT NULL DEFAULT 0,
  discount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  notes text,
  order_details text,
  assigned_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ord public" ON public.orders FOR ALL USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.reset_order_sequence()
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path=public AS $$
  SELECT setval('public.orders_order_number_seq', 1, false);
$$;

-- Auto-clear agent when reverted to pending/processing
CREATE OR REPLACE FUNCTION public.clear_agent_on_revert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IN ('pending','processing') AND OLD.status NOT IN ('pending','processing') THEN
    NEW.delivery_agent_id := NULL;
    NEW.assigned_at := NULL;
  END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER trg_clear_agent_revert BEFORE UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.clear_agent_on_revert();

-- ============= ORDER ITEMS =============
CREATE TABLE public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  quantity int NOT NULL DEFAULT 1,
  price numeric NOT NULL DEFAULT 0,
  size text,
  color text,
  product_details text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "oi public" ON public.order_items FOR ALL USING (true) WITH CHECK (true);

-- ============= AGENT PAYMENTS =============
CREATE TABLE public.agent_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_agent_id uuid REFERENCES public.delivery_agents(id) ON DELETE SET NULL,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  amount numeric NOT NULL DEFAULT 0,
  payment_type text NOT NULL DEFAULT 'payment',
  payment_date date,
  payment_method text DEFAULT 'cash',
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.agent_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ap public" ON public.agent_payments FOR ALL USING (true) WITH CHECK (true);

-- ============= AGENT DAILY CLOSINGS =============
CREATE TABLE public.agent_daily_closings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_agent_id uuid REFERENCES public.delivery_agents(id) ON DELETE CASCADE,
  closing_date date NOT NULL,
  total_collected numeric DEFAULT 0,
  total_returns numeric DEFAULT 0,
  net_amount numeric DEFAULT 0,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(delivery_agent_id, closing_date)
);
ALTER TABLE public.agent_daily_closings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "adc public" ON public.agent_daily_closings FOR ALL USING (true) WITH CHECK (true);

-- ============= RETURNS =============
CREATE TABLE public.returns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES public.orders(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES public.customers(id) ON DELETE SET NULL,
  delivery_agent_id uuid REFERENCES public.delivery_agents(id) ON DELETE SET NULL,
  return_amount numeric NOT NULL DEFAULT 0,
  returned_items jsonb,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.returns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ret public" ON public.returns FOR ALL USING (true) WITH CHECK (true);

-- ============= CASHBOX =============
CREATE TABLE public.cashbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  opening_balance numeric NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.cashbox ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cb public" ON public.cashbox FOR ALL USING (true) WITH CHECK (true);

CREATE TABLE public.cashbox_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cashbox_id uuid REFERENCES public.cashbox(id) ON DELETE CASCADE,
  type text NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  reason text,
  description text,
  payment_method text DEFAULT 'cash',
  user_id uuid,
  username text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.cashbox_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cbt public" ON public.cashbox_transactions FOR ALL USING (true) WITH CHECK (true);

-- ============= TREASURY =============
CREATE TABLE public.treasury (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  description text,
  category text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.treasury ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tr public" ON public.treasury FOR ALL USING (true) WITH CHECK (true);

-- ============= STATISTICS =============
CREATE TABLE public.statistics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  total_sales numeric DEFAULT 0,
  total_orders int DEFAULT 0,
  last_reset timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.statistics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "st public" ON public.statistics FOR ALL USING (true) WITH CHECK (true);
INSERT INTO public.statistics(total_sales, total_orders) VALUES (0,0);

-- ============= ANALYTICS EVENTS =============
CREATE TABLE public.analytics_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  session_id text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ae public" ON public.analytics_events FOR ALL USING (true) WITH CHECK (true);

-- ============= TRIGGERS: updated_at =============
DO $$ DECLARE t text; BEGIN
  FOR t IN SELECT unnest(ARRAY['app_settings','system_passwords','admin_users','categories','products',
    'governorates','offices','customers','delivery_agents','orders'])
  LOOP
    EXECUTE format('CREATE TRIGGER trg_%s_upd BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();', t, t);
  END LOOP;
END $$;

-- ============= STORAGE: products bucket =============
INSERT INTO storage.buckets (id, name, public) VALUES ('products','products', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "products bucket read" ON storage.objects FOR SELECT USING (bucket_id='products');
CREATE POLICY "products bucket write" ON storage.objects FOR INSERT WITH CHECK (bucket_id='products');
CREATE POLICY "products bucket update" ON storage.objects FOR UPDATE USING (bucket_id='products');
CREATE POLICY "products bucket delete" ON storage.objects FOR DELETE USING (bucket_id='products');
