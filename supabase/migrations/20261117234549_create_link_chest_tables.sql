create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  icon text not null default '📂',
  color text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_id_user_key unique (id, user_id)
);


create unique index categories_one_default_per_user
  on public.categories (user_id) where is_default;


create index categories_user_id_idx on public.categories (user_id);


create table public.links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  category_id uuid not null,
  status text not null default 'public',
  title text,
  url text,
  description text,
  ciphertext text,
  nonce text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint links_category_fk foreign key (category_id, user_id)
    references public.categories (id, user_id),
  constraint links_status_valid check (status in ('public', 'private')),
  constraint links_content_by_status check (
    (status = 'public'
      and url is not null
      and ciphertext is null
      and nonce is null)
    or
    (status = 'private'
      and ciphertext is not null
      and nonce is not null
      and title is null
      and url is null
      and description is null)
  )
);


create index links_user_id_idx on public.links (user_id);
create index links_category_id_idx on public.links (category_id);
