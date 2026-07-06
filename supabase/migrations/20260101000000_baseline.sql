


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."is_couple_member"("p_couple_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from couples c
    join user_profiles up on up.id in (c.user_a, c.user_b)
    where c.id = p_couple_id and up.auth_id = auth.uid()
  );
$$;


ALTER FUNCTION "public"."is_couple_member"("p_couple_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_curated_sessions_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin new.updated_at = now(); return new; end;
$$;


ALTER FUNCTION "public"."set_curated_sessions_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."assessment_responses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "question_key" "text" NOT NULL,
    "answer" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."assessment_responses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."assessment_results" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "result_key" "text" NOT NULL,
    "result_value" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."assessment_results" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."card_progress" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "couple_id" "uuid" NOT NULL,
    "card_id" "text" NOT NULL,
    "status" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."card_progress" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."couple_session_records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "couple_id" "uuid" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"(),
    "ended_at" timestamp with time zone,
    "cards_discussed" integer DEFAULT 0
);


ALTER TABLE "public"."couple_session_records" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."couples" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_a" "uuid",
    "user_b" "uuid",
    "shared_safe_word" "text" DEFAULT 'red'::"text",
    "matches_revealed" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."couples" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."curated_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "couple_id" "uuid" NOT NULL,
    "initiator_id" "uuid" NOT NULL,
    "deck_id" "text" NOT NULL,
    "deck_variant" "text",
    "card_ids" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "per_card_timer" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "global_timer_seconds" integer,
    "status" "text" DEFAULT 'lobby'::"text" NOT NULL,
    "current_index" integer DEFAULT 0 NOT NULL,
    "a_present" boolean DEFAULT false NOT NULL,
    "b_present" boolean DEFAULT false NOT NULL,
    "a_bandwidth" real,
    "b_bandwidth" real,
    "a_consented" boolean DEFAULT false NOT NULL,
    "b_consented" boolean DEFAULT false NOT NULL,
    "timer_started_at" timestamp with time zone,
    "reveal_state" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "safe_word_used" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "curated_sessions_status_check" CHECK (("status" = ANY (ARRAY['lobby'::"text", 'airlock'::"text", 'active'::"text", 'paused'::"text", 'complete'::"text", 'abandoned'::"text"])))
);

ALTER TABLE ONLY "public"."curated_sessions" REPLICA IDENTITY FULL;


ALTER TABLE "public"."curated_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."desire_matches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "couple_id" "uuid" NOT NULL,
    "desire_item_id" "text" NOT NULL,
    "alignment_level" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "partner_a_value" "text",
    "partner_b_value" "text",
    "gap_size" integer,
    "bridge_card_id" "text"
);


ALTER TABLE "public"."desire_matches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."desire_ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "desire_item_id" "text" NOT NULL,
    "rating" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "kink_ratings_rating_check" CHECK (("rating" = ANY (ARRAY['love'::"text", 'curious'::"text", 'neutral'::"text", 'hardNo'::"text"])))
);


ALTER TABLE "public"."desire_ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pairing_codes" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '24:00:00'::interval) NOT NULL,
    "claimed_by" "uuid",
    "claimed_at" timestamp with time zone,
    "couple_id" "uuid"
);


ALTER TABLE "public"."pairing_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "auth_id" "uuid" NOT NULL,
    "name" "text",
    "pronouns" "text" DEFAULT 'they/them'::"text",
    "sexual_orientation" "text" DEFAULT 'prefer not to say'::"text",
    "role_preference" "text" DEFAULT 'not sure'::"text",
    "user_mode" "text" DEFAULT 'solo'::"text",
    "experience_level" "text" DEFAULT 'new'::"text",
    "default_difficulty" "text" DEFAULT 'warm'::"text",
    "curiosity_selections" "jsonb" DEFAULT '[]'::"jsonb",
    "surprise_me_enabled" boolean DEFAULT false,
    "myth_buster_complete" boolean DEFAULT false,
    "myth_buster_skipped" boolean DEFAULT false,
    "nm_flavor" "text",
    "pairing_code" "text",
    "is_linked" boolean DEFAULT false,
    "partner_label" "text",
    "has_completed_onboarding" boolean DEFAULT false,
    "has_completed_assessment" boolean DEFAULT false,
    "onboarding_dropoff_screen" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "couple_id" "uuid",
    "linked_at" timestamp with time zone,
    "display_name" "text",
    "nm_card_response" "text",
    "ground_rules_accepted_at" timestamp with time zone,
    "onboarding_completed_at" timestamp with time zone,
    "app_mode" "text",
    "nm_stage" "text"
);


ALTER TABLE "public"."user_profiles" OWNER TO "postgres";


ALTER TABLE ONLY "public"."assessment_responses"
    ADD CONSTRAINT "assessment_responses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."assessment_results"
    ADD CONSTRAINT "assessment_results_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."card_progress"
    ADD CONSTRAINT "card_progress_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."couple_session_records"
    ADD CONSTRAINT "couple_session_records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."couples"
    ADD CONSTRAINT "couples_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."curated_sessions"
    ADD CONSTRAINT "curated_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."desire_matches"
    ADD CONSTRAINT "kink_matches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."desire_ratings"
    ADD CONSTRAINT "kink_ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."desire_ratings"
    ADD CONSTRAINT "kink_ratings_user_id_kink_key_key" UNIQUE ("user_id", "desire_item_id");



ALTER TABLE ONLY "public"."pairing_codes"
    ADD CONSTRAINT "pairing_codes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."pairing_codes"
    ADD CONSTRAINT "pairing_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_pairing_code_key" UNIQUE ("pairing_code");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id");



CREATE UNIQUE INDEX "curated_sessions_one_open_per_couple" ON "public"."curated_sessions" USING "btree" ("couple_id") WHERE ("status" = ANY (ARRAY['lobby'::"text", 'airlock'::"text", 'active'::"text", 'paused'::"text"]));



CREATE UNIQUE INDEX "user_profiles_auth_id_key" ON "public"."user_profiles" USING "btree" ("auth_id");



CREATE OR REPLACE TRIGGER "trg_curated_sessions_updated_at" BEFORE UPDATE ON "public"."curated_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."set_curated_sessions_updated_at"();



ALTER TABLE ONLY "public"."assessment_responses"
    ADD CONSTRAINT "assessment_responses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assessment_results"
    ADD CONSTRAINT "assessment_results_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."card_progress"
    ADD CONSTRAINT "card_progress_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "public"."couples"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."couple_session_records"
    ADD CONSTRAINT "couple_session_records_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "public"."couples"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."couples"
    ADD CONSTRAINT "couples_user_a_fkey" FOREIGN KEY ("user_a") REFERENCES "public"."user_profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."couples"
    ADD CONSTRAINT "couples_user_b_fkey" FOREIGN KEY ("user_b") REFERENCES "public"."user_profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."curated_sessions"
    ADD CONSTRAINT "curated_sessions_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "public"."couples"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."desire_matches"
    ADD CONSTRAINT "kink_matches_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "public"."couples"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."desire_ratings"
    ADD CONSTRAINT "kink_ratings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pairing_codes"
    ADD CONSTRAINT "pairing_codes_claimed_by_fkey" FOREIGN KEY ("claimed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."pairing_codes"
    ADD CONSTRAINT "pairing_codes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_auth_id_fkey" FOREIGN KEY ("auth_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Claimer can claim code" ON "public"."pairing_codes" FOR UPDATE TO "authenticated" USING (("auth"."uid"() <> "created_by")) WITH CHECK (("auth"."uid"() = "claimed_by"));



CREATE POLICY "Creator can delete own row" ON "public"."pairing_codes" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Creator can insert" ON "public"."pairing_codes" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Creator can read own row" ON "public"."pairing_codes" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Partners can insert couple sessions" ON "public"."couple_session_records" FOR INSERT TO "authenticated" WITH CHECK (("couple_id" IN ( SELECT "couples"."id"
   FROM "public"."couples"
  WHERE (("couples"."user_a" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"()))) OR ("couples"."user_b" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"())))))));



CREATE POLICY "Partners can update card progress" ON "public"."card_progress" FOR INSERT TO "authenticated" WITH CHECK (("couple_id" IN ( SELECT "couples"."id"
   FROM "public"."couples"
  WHERE (("couples"."user_a" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"()))) OR ("couples"."user_b" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"())))))));



CREATE POLICY "Partners can view card progress" ON "public"."card_progress" FOR SELECT TO "authenticated" USING (("couple_id" IN ( SELECT "couples"."id"
   FROM "public"."couples"
  WHERE (("couples"."user_a" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"()))) OR ("couples"."user_b" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"())))))));



CREATE POLICY "Partners can view couple sessions" ON "public"."couple_session_records" FOR SELECT TO "authenticated" USING (("couple_id" IN ( SELECT "couples"."id"
   FROM "public"."couples"
  WHERE (("couples"."user_a" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"()))) OR ("couples"."user_b" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"())))))));



CREATE POLICY "Partners can view kink matches" ON "public"."desire_matches" FOR SELECT TO "authenticated" USING (("couple_id" IN ( SELECT "couples"."id"
   FROM "public"."couples"
  WHERE (("couples"."user_a" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"()))) OR ("couples"."user_b" IN ( SELECT "user_profiles"."id"
           FROM "public"."user_profiles"
          WHERE ("user_profiles"."auth_id" = "auth"."uid"())))))));



CREATE POLICY "Partners can view their couple" ON "public"."couples" FOR SELECT TO "authenticated" USING ((("user_a" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))) OR ("user_b" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"())))));



CREATE POLICY "Users can insert own assessments" ON "public"."assessment_responses" FOR INSERT TO "authenticated" WITH CHECK (("user_id" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))));



CREATE POLICY "Users can insert own kink ratings" ON "public"."desire_ratings" FOR INSERT TO "authenticated" WITH CHECK (("user_id" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))));



CREATE POLICY "Users can insert own profile" ON "public"."user_profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth_id" = "auth"."uid"()));



CREATE POLICY "Users can insert own results" ON "public"."assessment_results" FOR INSERT TO "authenticated" WITH CHECK (("user_id" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))));



CREATE POLICY "Users can update own kink ratings" ON "public"."desire_ratings" FOR UPDATE TO "authenticated" USING (("user_id" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))));



CREATE POLICY "Users can update own profile" ON "public"."user_profiles" FOR UPDATE TO "authenticated" USING (("auth_id" = "auth"."uid"()));



CREATE POLICY "Users can view own assessments" ON "public"."assessment_responses" FOR SELECT TO "authenticated" USING (("user_id" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))));



CREATE POLICY "Users can view own kink ratings" ON "public"."desire_ratings" FOR SELECT TO "authenticated" USING (("user_id" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))));



CREATE POLICY "Users can view own profile" ON "public"."user_profiles" FOR SELECT TO "authenticated" USING (("auth_id" = "auth"."uid"()));



CREATE POLICY "Users can view own results" ON "public"."assessment_results" FOR SELECT TO "authenticated" USING (("user_id" IN ( SELECT "user_profiles"."id"
   FROM "public"."user_profiles"
  WHERE ("user_profiles"."auth_id" = "auth"."uid"()))));



ALTER TABLE "public"."assessment_responses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."assessment_results" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."card_progress" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "couple members manage their curated session" ON "public"."curated_sessions" TO "authenticated" USING ("public"."is_couple_member"("couple_id")) WITH CHECK ("public"."is_couple_member"("couple_id"));



ALTER TABLE "public"."couple_session_records" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."couples" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."curated_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."desire_matches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."desire_ratings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pairing_codes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_profiles" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."curated_sessions";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";














































































































































































REVOKE ALL ON FUNCTION "public"."is_couple_member"("p_couple_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_couple_member"("p_couple_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_couple_member"("p_couple_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_curated_sessions_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_curated_sessions_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_curated_sessions_updated_at"() TO "service_role";
























GRANT ALL ON TABLE "public"."assessment_responses" TO "authenticated";
GRANT ALL ON TABLE "public"."assessment_responses" TO "service_role";



GRANT ALL ON TABLE "public"."assessment_results" TO "authenticated";
GRANT ALL ON TABLE "public"."assessment_results" TO "service_role";



GRANT ALL ON TABLE "public"."card_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."card_progress" TO "service_role";



GRANT ALL ON TABLE "public"."couple_session_records" TO "authenticated";
GRANT ALL ON TABLE "public"."couple_session_records" TO "service_role";



GRANT ALL ON TABLE "public"."couples" TO "authenticated";
GRANT ALL ON TABLE "public"."couples" TO "service_role";



GRANT ALL ON TABLE "public"."curated_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."curated_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."desire_matches" TO "authenticated";
GRANT ALL ON TABLE "public"."desire_matches" TO "service_role";



GRANT ALL ON TABLE "public"."desire_ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."desire_ratings" TO "service_role";



GRANT ALL ON TABLE "public"."pairing_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."pairing_codes" TO "service_role";



GRANT ALL ON TABLE "public"."user_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profiles" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































