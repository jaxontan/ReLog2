-- ReLog2 Schema v1 — run in Supabase SQL Editor (https://pzciufzihblwdsotttao.supabase.co)
-- ponytail: snake_case columns, Supabase PostgREST conventions.

-- 1. Albums
create table if not exists albums (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  creator_id uuid not null references auth.users(id),
  invite_code text not null unique,
  status text not null default 'active',
  photo_count int not null default 0,
  members_count int not null default 1,
  created_at timestamptz not null default now(),
  ended_at timestamptz
);

-- 2. Members (join table: album <-> user)
create table if not exists members (
  id uuid default gen_random_uuid() primary key,
  album_id uuid not null references albums(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  unique(album_id, user_id)
);

-- 3. Memories
create table if not exists memories (
  id uuid default gen_random_uuid() primary key,
  album_id uuid not null references albums(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  type text not null check (type in ('photo','video','voice','note')),
  note_phase text check (note_phase in ('before','mid','confession','after')),
  storage_path text,
  text_body text,
  lat double precision,
  lng double precision,
  captured_at timestamptz not null default now(),
  is_confession_locked boolean not null default false
);

-- 4. Votes (Tier 2)
create table if not exists votes (
  id uuid default gen_random_uuid() primary key,
  album_id uuid not null references albums(id) on delete cascade,
  memory_id uuid not null references memories(id) on delete cascade,
  voter_id uuid not null references auth.users(id),
  category text not null,
  unique(memory_id, voter_id)
);

-- 5. Storage bucket for media
insert into storage.buckets (id, name, public) values ('album-media', 'album-media', true)
on conflict (id) do nothing;

-- ponytail: RLS policies. Authenticated = full CRUD on own data, read all albums/members.
alter table albums enable row level security;
alter table members enable row level security;
alter table memories enable row level security;

create policy "albums_select" on albums for select to authenticated using (true);
create policy "albums_insert" on albums for insert to authenticated with check (true);
create policy "albums_update" on albums for update to authenticated using (auth.uid() = creator_id);

create policy "members_select" on members for select to authenticated using (true);
create policy "members_insert" on members for insert to authenticated with check (true);
create policy "members_delete" on members for delete to authenticated using (auth.uid() = (select creator_id from albums where id = album_id));

create policy "memories_select" on memories for select to authenticated using (true);
create policy "memories_insert" on memories for insert to authenticated with check (auth.uid() = user_id);
create policy "memories_update" on memories for update to authenticated using (auth.uid() = user_id);
create policy "memories_delete" on memories for delete to authenticated using (auth.uid() = user_id);
