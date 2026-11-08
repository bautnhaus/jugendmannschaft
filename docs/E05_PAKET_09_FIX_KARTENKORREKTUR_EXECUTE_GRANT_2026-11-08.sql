-- Supabase migration: 20261108213211 / e05_package_09_fix_card_correction_authenticated_grant
-- E05 Paket 9 – Korrekturmigration 9.2
-- Stellt den vorgesehenen EXECUTE-Zugriff für authentifizierte App-Nutzer wieder her.
begin;
revoke all on function public.correct_training_behavior_event(uuid, text, text)
from public, anon, authenticated, service_role;
grant execute on function public.correct_training_behavior_event(uuid, text, text)
to authenticated;
commit;
