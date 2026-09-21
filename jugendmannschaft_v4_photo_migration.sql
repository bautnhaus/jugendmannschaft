-- Einmalig in Supabase unter SQL Editor ausführen.
-- Fügt das Spielerfoto zur bestehenden players-Tabelle hinzu.
alter table public.players
  add column if not exists photo_data text;
