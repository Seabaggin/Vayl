-- Shared session history hardening (2026-07-15 two-sim campaign findings).
--
-- couple_session_records is the couple-shared record of completed sittings,
-- upserted by BOTH devices (keyed by the curated_sessions id). Three gaps:
--   1. No UPDATE policy — the second device's upsert-as-update was silently
--      rejected by RLS, so the row kept whichever device wrote FIRST.
--   2. No deck_id — a device that never wrote its own local row (or a fresh
--      install) cannot render the entry (deck name/category unknown).
--   3. Last-writer semantics would let a device with fewer local records
--      (joiner / resumed mid-session) shrink cards_discussed.
-- Fix: add deck_id, allow partner updates, and make updates ADDITIVE via a
-- merge trigger (greatest counts, earliest start, latest end) so write order
-- between the two devices can never change the record's meaning.

alter table "public"."couple_session_records"
    add column if not exists "deck_id" text;

create policy "Partners can update couple sessions"
    on "public"."couple_session_records" for update to "authenticated"
    using (("couple_id" in ( select "couples"."id"
        from "public"."couples"
        where (("couples"."user_a" in ( select "user_profiles"."id"
                 from "public"."user_profiles"
                 where ("user_profiles"."auth_id" = "auth"."uid"())))
            or ("couples"."user_b" in ( select "user_profiles"."id"
                 from "public"."user_profiles"
                 where ("user_profiles"."auth_id" = "auth"."uid"())))))))
    with check (("couple_id" in ( select "couples"."id"
        from "public"."couples"
        where (("couples"."user_a" in ( select "user_profiles"."id"
                 from "public"."user_profiles"
                 where ("user_profiles"."auth_id" = "auth"."uid"())))
            or ("couples"."user_b" in ( select "user_profiles"."id"
                 from "public"."user_profiles"
                 where ("user_profiles"."auth_id" = "auth"."uid"())))))));

create or replace function "public"."couple_session_records_merge"()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    -- Additive merge: two devices report the same sitting with different local
    -- views; the record keeps the most complete one regardless of write order.
    new.cards_discussed := greatest(coalesce(old.cards_discussed, 0),
                                    coalesce(new.cards_discussed, 0));
    new.started_at := least(coalesce(old.started_at, new.started_at),
                            coalesce(new.started_at, old.started_at));
    new.ended_at   := greatest(coalesce(old.ended_at, new.ended_at),
                               coalesce(new.ended_at, old.ended_at));
    new.deck_id    := coalesce(new.deck_id, old.deck_id);
    -- The couple key is immutable once written.
    new.couple_id  := old.couple_id;
    return new;
end;
$$;

drop trigger if exists "couple_session_records_merge" on "public"."couple_session_records";
create trigger "couple_session_records_merge"
    before update on "public"."couple_session_records"
    for each row execute function "public"."couple_session_records_merge"();
