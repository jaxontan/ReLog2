-- ReLog2 Chat/Messages Schema v1
-- Run in Supabase SQL Editor: https://supabase.com/dashboard/project/pzciufzihblwdsotttao/sql

-- 1. Messages table
create table if not exists messages (
  id uuid default gen_random_uuid() primary key,
  album_id uuid not null references albums(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  content text not null,
  type text not null default 'text' check (type in ('text', 'image', 'voice', 'location', 'system')),
  metadata jsonb default '{}'::jsonb, -- for image URLs, voice duration, location coords, etc.
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

-- 2. Indexes for common queries
create index if not exists idx_messages_album_created on messages(album_id, created_at desc);
create index if not exists idx_messages_user on messages(user_id);

-- 3. Enable RLS
alter table messages enable row level security;

-- 4. Policies
create policy "messages_select" on messages
  for select to authenticated
  using (
    exists (
      select 1 from members
      where album_id = messages.album_id
        and user_id = auth.uid()
    )
  );

create policy "messages_insert" on messages
  for insert to authenticated
  with check (
    exists (
      select 1 from members
      where album_id = messages.album_id
        and user_id = auth.uid()
    )
  );

create policy "messages_update" on messages
  for update to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from members
      where album_id = messages.album_id
        and user_id = auth.uid()
        and role = 'creator'
    )
  );

create policy "messages_delete" on messages
  for delete to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from members
      where album_id = messages.album_id
        and user_id = auth.uid()
        and role = 'creator'
    )
  );

-- 5. Enable realtime
alter publication supabase_realtime add table messages;

-- 6. Trigger for updated_at
create or replace function update_messages_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger messages_updated_at
  before update on messages
  for each row execute function update_messages_updated_at();

-- 7. Optional: System messages for events (join, leave, trip ended)
-- These can be inserted by the app when events occur
-- Example system message types:
-- 'member_joined', 'member_left', 'trip_ended', 'confession_unlocked'