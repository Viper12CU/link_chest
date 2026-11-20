alter table public.categories enable row level security;
alter table public.links enable row level security;


-- Categorías: la categoría por defecto (is_default) se puede leer,
-- pero el usuario no puede crearla, editarla ni borrarla.
create policy categories_select_own on public.categories
  for select to authenticated
  using ((select auth.uid()) = user_id);


create policy categories_insert_own on public.categories
  for insert to authenticated
  with check ((select auth.uid()) = user_id and not is_default);


create policy categories_update_own on public.categories
  for update to authenticated
  using ((select auth.uid()) = user_id and not is_default)
  with check ((select auth.uid()) = user_id and not is_default);


create policy categories_delete_own on public.categories
  for delete to authenticated
  using ((select auth.uid()) = user_id and not is_default);


-- Links: el usuario gestiona solo los suyos.
create policy links_own_all on public.links
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
