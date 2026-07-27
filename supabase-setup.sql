-- ============================================
-- 探店工作台 Supabase 建表脚本
-- 使用方法：登录 supabase.com → 左侧 SQL Editor → 新建查询 → 粘贴以下全部内容 → Run
-- ============================================

-- ===== 1. 建表 =====

-- 订单表
create table if not exists public.orders (
  id            text primary key,
  room_id       text not null,
  store         text,
  platform      text,
  format        text,
  price_type    text,
  amount        numeric default 0,
  has_transport text default 'no',
  transport_fee numeric default 0,
  status        text default 'unpaid',
  order_date    text,
  shoot_time    text,
  publish_due   text,
  publish_date  text,
  due_date      text,
  pay_date      text,
  note          text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- 报价表（按月）
create table if not exists public.pricing (
  id            text primary key,
  room_id       text not null,
  month         text not null,
  img_surface   numeric default 0,
  img_underwater numeric default 0,
  vid_surface   numeric default 0,
  vid_underwater numeric default 0,
  note          text,
  updated_at    timestamptz default now(),
  unique (room_id, month)
);

-- 待办事项表
create table if not exists public.todos (
  id         text primary key,
  room_id    text not null,
  text       text not null,
  done       boolean default false,
  created    text
);

-- ===== 2. 索引 =====
create index if not exists idx_orders_room on public.orders(room_id);
create index if not exists idx_pricing_room on public.pricing(room_id);
create index if not exists idx_todos_room on public.todos(room_id);

-- ===== 3. RLS 辅助函数（从请求头读取 room_id）=====
create or replace function public.current_room_id()
returns text language sql stable security definer as $$
  select nullif(
    current_setting('request.headers', true)::json->>'x-room-id',
    ''
  )
$$;

-- ===== 4. 启用 RLS =====
alter table public.orders  enable row level security;
alter table public.pricing enable row level security;
alter table public.todos   enable row level security;

-- ===== 5. RLS 策略 =====

-- orders
create policy "orders_select" on public.orders for select to anon using (room_id = public.current_room_id());
create policy "orders_insert" on public.orders for insert to anon with check (room_id = public.current_room_id());
create policy "orders_update" on public.orders for update to anon using (room_id = public.current_room_id()) with check (room_id = public.current_room_id());
create policy "orders_delete" on public.orders for delete to anon using (room_id = public.current_room_id());

-- pricing
create policy "pricing_select" on public.pricing for select to anon using (room_id = public.current_room_id());
create policy "pricing_insert" on public.pricing for insert to anon with check (room_id = public.current_room_id());
create policy "pricing_update" on public.pricing for update to anon using (room_id = public.current_room_id()) with check (room_id = public.current_room_id());
create policy "pricing_delete" on public.pricing for delete to anon using (room_id = public.current_room_id());

-- todos
create policy "todos_select" on public.todos for select to anon using (room_id = public.current_room_id());
create policy "todos_insert" on public.todos for insert to anon with check (room_id = public.current_room_id());
create policy "todos_update" on public.todos for update to anon using (room_id = public.current_room_id()) with check (room_id = public.current_room_id());
create policy "todos_delete" on public.todos for delete to anon using (room_id = public.current_room_id());

-- ===== 6. 启用 Realtime =====
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.pricing;
alter publication supabase_realtime add table public.todos;

alter table public.orders  replica identity full;
alter table public.pricing replica identity full;
alter table public.todos   replica identity full;
