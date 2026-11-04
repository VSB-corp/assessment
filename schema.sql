-- Jalankan pada proyek Supabase khusus assessment setelah memilih proyek.
create table public.assessment_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.assessment_admins enable row level security;
grant select on public.assessment_admins to authenticated;
create policy "admin can read own membership" on public.assessment_admins for select to authenticated using (user_id = (select auth.uid()));

create table public.assessment_responses (
 id uuid primary key,
 created_at timestamptz not null default now(),
 respondent_type text not null check (respondent_type in ('Nakes','Non-Nakes')),
 unit text not null,
 name text not null,
 phone text not null,
 answers jsonb not null,
 feedback text not null
);
alter table public.assessment_responses enable row level security;
grant select on public.assessment_responses to authenticated;
create policy "only designated admins read responses" on public.assessment_responses for select to authenticated using (exists (select 1 from public.assessment_admins a where a.user_id = (select auth.uid())));

create table public.assessment_settings (id boolean primary key default true check (id), is_open boolean not null default true);
insert into public.assessment_settings (id) values (true);
alter table public.assessment_settings enable row level security;
grant select, update on public.assessment_settings to authenticated;
create policy "admins read settings" on public.assessment_settings for select to authenticated using (exists (select 1 from public.assessment_admins a where a.user_id = (select auth.uid())));
create policy "admins change settings" on public.assessment_settings for update to authenticated using (exists (select 1 from public.assessment_admins a where a.user_id = (select auth.uid()))) with check (exists (select 1 from public.assessment_admins a where a.user_id = (select auth.uid())));

-- Fungsi penulis disimpan di skema yang tidak diekspos oleh Data API.
create schema assessment_private;
revoke all on schema assessment_private from public;
grant usage on schema assessment_private to anon, authenticated;
create function assessment_private.submit_assessment(payload jsonb) returns void language plpgsql security definer set search_path = '' as $$
declare item jsonb; response_id uuid; response_unit text;
begin
 if not (select is_open from public.assessment_settings where id) then raise exception 'Survei ditutup'; end if;
 response_id := (payload->>'id')::uuid;
 if payload->>'type' not in ('Nakes','Non-Nakes') or payload->>'type' is null then raise exception 'Jenis tidak valid'; end if;
 response_unit := case when payload->>'unit' = 'Lainnya' then trim(payload->>'other') else trim(payload->>'unit') end;
 if coalesce(length(response_unit),0) not between 1 and 200 or coalesce(length(trim(payload->>'name')),0) not between 1 and 200 or coalesce(length(trim(payload->>'phone')),0) not between 1 and 50 or coalesce(length(trim(payload->>'feedback')),0) not between 1 and 5000 then raise exception 'Data tidak lengkap'; end if;
 if jsonb_typeof(payload->'answers') <> 'array' or jsonb_array_length(payload->'answers') <> 15 then raise exception 'Jawaban tidak lengkap'; end if;
 for item in select value from jsonb_array_elements(payload->'answers') loop
  if jsonb_typeof(item->'h') <> 'number' or jsonb_typeof(item->'k') <> 'number' or coalesce(item->>'h','') not in ('1','2','3','4','5') or coalesce(item->>'k','') not in ('1','2','3','4','5') then raise exception 'Jawaban tidak valid'; end if;
 end loop;
 insert into public.assessment_responses(id,respondent_type,unit,name,phone,answers,feedback) values(response_id,payload->>'type',response_unit,trim(payload->>'name'),trim(payload->>'phone'),payload->'answers',trim(payload->>'feedback')) on conflict(id) do nothing;
end $$;
revoke all on function assessment_private.submit_assessment(jsonb) from public;
grant execute on function assessment_private.submit_assessment(jsonb) to anon, authenticated;
create function public.submit_assessment(payload jsonb) returns void language sql security invoker set search_path = '' as $$
 select assessment_private.submit_assessment(payload);
$$;
revoke all on function public.submit_assessment(jsonb) from public;
grant execute on function public.submit_assessment(jsonb) to anon, authenticated;
