// Edge Function: delete-account
//
// Elimina la cuenta de Supabase del usuario autenticado que llama la función.
//
// El cliente móvil no puede usar `auth.admin.deleteUser` (requiere la clave
// service_role), así que la app invoca esta función con su JWT. La clave
// service_role se inyecta automáticamente en el runtime de las Edge Functions
// (`SUPABASE_SECRET_KEYS` / `SUPABASE_SERVICE_ROLE_KEY`) y nunca sale del
// servidor.
//
// La gateway ya valida el JWT (`verify_jwt: true`), pero aquí se vuelve a
// validar contra el servidor para no depender solo de la gateway.

import { createClient } from 'npm:@supabase/supabase-js@2'

const jsonHeaders = { 'Content-Type': 'application/json' }

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders })
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405)
  }

  const authorization = req.headers.get('Authorization')
  if (!authorization) {
    return json({ error: 'missing_authorization' }, 401)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const secretKeys = Deno.env.get('SUPABASE_SECRET_KEYS')
  const serviceRoleKey =
    (secretKeys ? JSON.parse(secretKeys).default : undefined) ??
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

  if (!supabaseUrl || !serviceRoleKey) {
    console.error('[delete-account] faltan SUPABASE_URL o la clave de servicio')
    return json({ error: 'server_misconfigured' }, 500)
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  const jwt = authorization.replace(/^Bearer\s+/i, '')

  const { data, error: userError } = await admin.auth.getUser(jwt)
  if (userError || !data?.user) {
    console.error('[delete-account] JWT inválido:', userError?.message)
    return json({ error: 'invalid_token' }, 401)
  }

  const userId = data.user.id

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId)
  if (deleteError) {
    console.error('[delete-account] no se pudo borrar:', deleteError.message)
    return json({ error: 'delete_failed' }, 400)
  }

  console.log('[delete-account] cuenta eliminada:', userId)
  return json({ ok: true }, 200)
})
