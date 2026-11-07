-- primeTrack v1.2. Execute in the SAME Supabase project after v1.1.
-- Additive migration: preserves existing workouts, sets, body logs and photos.
BEGIN;
CREATE TABLE IF NOT EXISTS public.routine_templates (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 100),
 exercises jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(exercises) = 'array'),
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS routine_templates_user_idx ON public.routine_templates(user_id,updated_at DESC);
ALTER TABLE public.routine_templates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "routine owner" ON public.routine_templates;
CREATE POLICY "routine owner" ON public.routine_templates FOR ALL TO authenticated
 USING (user_id = (select auth.uid())) WITH CHECK (user_id = (select auth.uid()));

ALTER TABLE public.workouts ADD COLUMN IF NOT EXISTS routine_id uuid REFERENCES public.routine_templates(id) ON DELETE SET NULL;
ALTER TABLE public.workouts ADD COLUMN IF NOT EXISTS notes text NOT NULL DEFAULT '';
CREATE INDEX IF NOT EXISTS workouts_routine_idx ON public.workouts(user_id,routine_id,performed_at DESC);
ALTER TABLE public.workout_sets ADD COLUMN IF NOT EXISTS note text NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS public.exercise_favorites (
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 exercise text NOT NULL CHECK (length(trim(exercise)) BETWEEN 0 AND 120),
 PRIMARY KEY (user_id,exercise)
);
ALTER TABLE public.exercise_favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "favorites owner" ON public.exercise_favorites;
CREATE POLICY "favorites owner" ON public.exercise_favorites FOR ALL TO authenticated
 USING (user_id = (select auth.uid())) WITH CHECK (user_id = (select auth.uid()));

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS preferred_language text NOT NULL DEFAULT 'en';
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_preferred_language_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_preferred_language_check CHECK (preferred_language IN ('en','es'));
COMMIT;
-- Existing workouts intentionally have routine_id=NULL. They remain in History.
-- IMPORTANT: Verify all RLS policies and storage bucket policies in Supabase before deployment.

-- Atomic save/edit: if any set fails, the whole database operation rolls back.
CREATE OR REPLACE FUNCTION public.save_training_session(
 p_workout_id uuid, p_routine_id uuid, p_title text, p_notes text, p_sets jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE v_uid uuid := (select auth.uid()); v_id uuid; v_item jsonb; v_pos integer := 0;
BEGIN
 IF v_uid IS NULL THEN RAISE EXCEPTION 'Sign in required'; END IF;
 IF length(trim(coalesce(p_title,''))) NOT BETWEEN 1 AND 100 THEN RAISE EXCEPTION 'Invalid title'; END IF;
 IF jsonb_typeof(p_sets) IS DISTINCT FROM 'array' OR jsonb_array_length(p_sets) NOT BETWEEN 1 AND 300 THEN
   RAISE EXCEPTION 'A session must contain between 1 and 300 sets';
 END IF;
 IF p_routine_id IS NOT NULL AND NOT EXISTS
  (SELECT 1 FROM public.routine_templates WHERE id=p_routine_id AND user_id=v_uid) THEN
   RAISE EXCEPTION 'Routine not found';
 END IF;
 IF p_workout_id IS NULL THEN
   INSERT INTO public.workouts(user_id,title,notes,routine_id)
   VALUES(v_uid,trim(p_title),coalesce(p_notes,''),p_routine_id) RETURNING id INTO v_id;
 ELSE
   UPDATE public.workouts SET title=trim(p_title),notes=coalesce(p_notes,''),routine_id=p_routine_id
   WHERE id=p_workout_id AND user_id=v_uid RETURNING id INTO v_id;
   IF v_id IS NULL THEN RAISE EXCEPTION 'Workout not found'; END IF;
   DELETE FROM public.workout_sets WHERE workout_id=v_id AND user_id=v_uid;
 END IF;
 FOR v_item IN SELECT value FROM jsonb_array_elements(p_sets) LOOP
   v_pos := v_pos + 1;
   IF length(trim(coalesce(v_item->>'exercise',''))) NOT BETWEEN 1 AND 120 THEN RAISE EXCEPTION 'Invalid exercise'; END IF;
   IF (v_item->>'set_type') NOT IN ('effective','backoff','warmup') THEN RAISE EXCEPTION 'Invalid set type'; END IF;
   INSERT INTO public.workout_sets(workout_id,user_id,exercise,position,weight_kg,reps,set_type,note)
   VALUES(v_id,v_uid,trim(v_item->>'exercise'),v_pos,(v_item->>'weight_kg')::numeric,(v_item->>'reps')::integer,v_item->>'set_type',left(coalesce(v_item->>'note',''),1000));
 END LOOP;
 RETURN v_id;
END; $$;
REVOKE ALL ON FUNCTION public.save_training_session(uuid,uuid,text,text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.save_training_session(uuid,uuid,text,text,jsonb) TO authenticated;
