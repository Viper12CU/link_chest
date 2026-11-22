alter table public.categories add column deleted_at timestamptz;
alter table public.links add column deleted_at timestamptz;

-- el servidor fija updated_at también al insertar, para que el cursor de descarga sea fiable
drop trigger categories_set_updated_at on public.categories;
create trigger categories_set_updated_at
  before insert or update on public.categories
  for each row execute function public.set_updated_at();

drop trigger links_set_updated_at on public.links;
create trigger links_set_updated_at
  before insert or update on public.links
  for each row execute function public.set_updated_at();

-- índices para la descarga paginada; reemplazan a los de user_id solo
create index categories_user_updated_idx on public.categories (user_id, updated_at, id);
create index links_user_updated_idx on public.links (user_id, updated_at, id);
drop index public.categories_user_id_idx;
drop index public.links_user_id_idx;
