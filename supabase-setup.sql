-- Connector Recognizer: Supabase setup
-- Run this once in Supabase: Dashboard > SQL Editor > New query > paste > Run.

-- 1. Vector support (stores the "fingerprint" of each photo)
create extension if not exists vector;

-- 2. Connector types
create table if not exists public.connectors (
  id           uuid primary key default gen_random_uuid(),
  name         text not null unique,
  part_number  text,
  description  text,
  created_at   timestamptz not null default now()
);

-- 3. Training photos. MobileNet V2 produces a 1280-number embedding per image.
create table if not exists public.training_images (
  id            uuid primary key default gen_random_uuid(),
  connector_id  uuid not null references public.connectors(id) on delete cascade,
  storage_path  text not null,
  source        text not null default 'upload' check (source in ('camera', 'upload')),
  embedding     vector(1280) not null,
  created_at    timestamptz not null default now()
);

create index if not exists training_images_connector_idx
  on public.training_images (connector_id);

create index if not exists training_images_embedding_idx
  on public.training_images using hnsw (embedding vector_cosine_ops);

-- 4. Matching function, used later by the "Recognize" tab.
--    Returns the closest training photos to a query embedding.
create or replace function public.match_connectors(
  query_embedding vector(1280),
  match_count int default 10
)
returns table (
  connector_id uuid,
  name         text,
  part_number  text,
  similarity   float
)
language sql stable
as $$
  select c.id, c.name, c.part_number,
         1 - (t.embedding <=> query_embedding) as similarity
  from public.training_images t
  join public.connectors c on c.id = t.connector_id
  order by t.embedding <=> query_embedding
  limit match_count;
$$;

-- 5. Row level security.
--    These policies let anyone with your site URL read, add and delete data.
--    Fine for a prototype on an internal link; add Supabase Auth before sharing widely.
alter table public.connectors      enable row level security;
alter table public.training_images enable row level security;

drop policy if exists "anon read connectors"   on public.connectors;
drop policy if exists "anon insert connectors" on public.connectors;
drop policy if exists "anon delete connectors" on public.connectors;
create policy "anon read connectors"   on public.connectors for select to anon using (true);
create policy "anon insert connectors" on public.connectors for insert to anon with check (true);
create policy "anon delete connectors" on public.connectors for delete to anon using (true);

drop policy if exists "anon read images"   on public.training_images;
drop policy if exists "anon insert images" on public.training_images;
drop policy if exists "anon delete images" on public.training_images;
create policy "anon read images"   on public.training_images for select to anon using (true);
create policy "anon insert images" on public.training_images for insert to anon with check (true);
create policy "anon delete images" on public.training_images for delete to anon using (true);

-- 6. Storage bucket for the photos (public so thumbnails can be shown)
insert into storage.buckets (id, name, public)
values ('connector-images', 'connector-images', true)
on conflict (id) do nothing;

drop policy if exists "anon read connector images"   on storage.objects;
drop policy if exists "anon upload connector images" on storage.objects;
drop policy if exists "anon delete connector images" on storage.objects;
create policy "anon read connector images"   on storage.objects for select to anon using (bucket_id = 'connector-images');
create policy "anon upload connector images" on storage.objects for insert to anon with check (bucket_id = 'connector-images');
create policy "anon delete connector images" on storage.objects for delete to anon using (bucket_id = 'connector-images');
