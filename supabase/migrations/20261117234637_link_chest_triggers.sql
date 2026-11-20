create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


create trigger categories_set_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();


create trigger links_set_updated_at
  before update on public.links
  for each row execute function public.set_updated_at();


create function public.create_default_category()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.categories (user_id, title, icon, color, is_default)
  values (new.id, 'Sin categoría', '📂', '#ff253745', true);
  return new;
end;
$$;


create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.create_default_category();


revoke execute on function public.create_default_category() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;


-- Relleno: usuarios de prueba existentes antes del disparador también
-- reciben su categoría por defecto.
insert into public.categories (user_id, title, icon, color, is_default)
select u.id, 'Sin categoría', '📂', '#ff253745', true
from auth.users u
where not exists (
  select 1 from public.categories c
  where c.user_id = u.id and c.is_default
);
