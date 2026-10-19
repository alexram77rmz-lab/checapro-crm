-- =============================================================================
-- ESQUEMA SQL MULTI-TENANT (SUPABASE / POSTGRESQL)
-- Producto: PyME OS México (Micro-CRM WhatsApp IA + Operaciones/Órdenes + Checador + CFDI)
-- =============================================================================

create extension if not exists "pgcrypto";

-- 1. TENANTS (Negocios / Empresas de cualquier giro)
create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  business_type text not null default 'general', -- 'taller', 'clinica', 'comercio', 'restaurante', 'servicios'
  rfc text,
  tax_regime text, -- Ej. '601', '626' (RESICO)
  facturapi_org_key text, -- Llave de organización en Facturapi (CSD cargado ahí, NUNCA CIEC/e.firma)
  whatsapp_phone_number_id text,
  whatsapp_waba_id text,
  plan_tier text not null default 'pro', -- 'starter' ($35 USD), 'pro' ($49 USD)
  subscription_status text not null default 'active',
  created_at timestamptz not null default now()
);

-- 2. SUCURSALES (Multi-sucursal por negocio)
create table public.branches (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  address text,
  shift_entry time not null default '09:00',
  shift_exit time not null default '18:00',
  tolerance_minutes int not null default 10,
  lunch_minutes int not null default 60,
  created_at timestamptz not null default now()
);

-- 3. MIEMBROS DEL EQUIPO / EMPLEADOS (Roles: owner, admin, staff)
create table public.employees (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  auth_user_id uuid, -- Referencia opcional a auth.users de Supabase
  full_name text not null,
  role text not null default 'staff', -- 'owner', 'admin', 'staff'
  job_title text,
  pin_code varchar(6) not null,
  whatsapp_phone text not null,
  shift_entry time not null default '09:00',
  shift_exit time not null default '18:00',
  tolerance_minutes int not null default 10,
  punctuality_bonus numeric(10,2) not null default 1200.00,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 4. RELOJ CHECADOR Y ALERTAS DE ASISTENCIA (Entrada, Comida, Regreso, Salida)
create table public.attendance_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  employee_id uuid not null references public.employees(id) on delete cascade,
  work_date date not null default current_date,
  entry_time time,
  lunch_out_time time,
  lunch_in_time time,
  exit_time time,
  special_event text, -- Ej. 'Comisión con cliente', 'Banco', 'Cita médica'
  check_method text not null default 'app_gps', -- 'app_gps', 'kiosk_pin', 'biometric_webhook'
  late_minutes int not null default 0,
  alert_sent boolean not null default false,
  employee_justification text,
  justification_status text default 'pending', -- 'pending', 'approved', 'rejected'
  created_at timestamptz not null default now(),
  unique(tenant_id, employee_id, work_date)
);

-- 5. CLIENTES DEL NEGOCIO (CRM)
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  full_name text not null,
  whatsapp_phone text not null,
  email text,
  rfc text,
  fiscal_regime text,
  postal_code varchar(10),
  asset_identifier text, -- Polimórfico según giro: Placa/Auto (Taller), Paciente (Clínica), Empresa (B2B)
  asset_details jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(tenant_id, whatsapp_phone)
);

-- 6. CATÁLOGO DE PRODUCTOS / SERVICIOS / MANO DE OBRA
create table public.catalog_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  sku text,
  name text not null,
  category text not null default 'servicio', -- 'servicio', 'refaccion', 'producto', 'consulta'
  unit_price numeric(12,2) not null default 0,
  sat_product_key varchar(12) default '01010101', -- ClaveProdServ SAT
  sat_unit_key varchar(8) default 'E48',          -- ClaveUnidad SAT (E48 = Unidad de servicio)
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 7. ÓRDENES DE SERVICIO / VENTAS Y TABLERO KANBAN
create table public.service_orders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  folio serial,
  customer_id uuid not null references public.customers(id) on delete restrict,
  assigned_employee_id uuid references public.employees(id) on delete set null,
  title text not null, -- Ej. 'Afinación Mayor + Frenos Mazda 3' o 'Instalación Aire Acondicionado'
  asset_label text,    -- Ej. 'Mazda 3 2021 • Placas JKL-902' o 'Sucursal Cliente Reforma'
  kanban_stage text not null default 'lead', -- 'lead', 'diagnosing', 'quoted', 'in_progress', 'ready', 'delivered'
  diagnosis_notes text,
  items jsonb not null default '[]'::jsonb,  -- [{name, qty, price, sat_key}]
  subtotal numeric(12,2) not null default 0,
  tax numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  payment_status text not null default 'pending', -- 'pending', 'partial', 'paid'
  payment_link_url text, -- Liga de Mercado Pago / Stripe
  cfdi_status text not null default 'unbilled', -- 'unbilled', 'issued', 'canceled'
  cfdi_uuid text,
  cfdi_pdf_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 8. BANDEJA COMPARTIDA DE WHATSAPP E INTERVENCIÓN DE IA
create table public.whatsapp_threads (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  customer_phone text not null,
  customer_name text,
  ai_mode_enabled boolean not null default true, -- true = responde IA, false = escalado a humano
  needs_human_attention boolean not null default false,
  last_message_preview text,
  last_message_at timestamptz not null default now()
);

create table public.whatsapp_messages (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  thread_id uuid not null references public.whatsapp_threads(id) on delete cascade,
  sender_type text not null, -- 'customer', 'ai_agent', 'staff_human', 'system_notification'
  body text not null,
  wa_message_id text,
  created_at timestamptz not null default now()
);

-- =============================================================================
-- AISLAMIENTO MULTI-TENANT (ROW LEVEL SECURITY)
-- =============================================================================
alter table public.tenants enable row level security;
alter table public.branches enable row level security;
alter table public.employees enable row level security;
alter table public.attendance_logs enable row level security;
alter table public.customers enable row level security;
alter table public.catalog_items enable row level security;
alter table public.service_orders enable row level security;
alter table public.whatsapp_threads enable row level security;
alter table public.whatsapp_messages enable row level security;

-- Política estándar por tenant_id desde el JWT de sesión (app_metadata.tenant_id)
create policy "tenant_isolation_service_orders" on public.service_orders
  for all using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

create policy "tenant_isolation_attendance" on public.attendance_logs
  for all using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

create policy "tenant_isolation_customers" on public.customers
  for all using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
