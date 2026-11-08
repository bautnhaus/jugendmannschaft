-- E05 Paket 7 – Korrektur: Audit-Lesezugriff im ausgewählten Teamkontext
-- Supabase DEV only; no PROD changes.
begin;

drop policy if exists team_season_closure_audit_select_team
on public.team_season_closure_audit;

create policy team_season_closure_audit_select_team
on public.team_season_closure_audit
for select to authenticated
using (
  public.is_team_member(team_id)
  or public.has_selected_team_context(team_id)
);

commit;
