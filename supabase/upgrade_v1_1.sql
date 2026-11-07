-- Run ONCE in the existing Supabase project. Preserves all existing records.
ALTER TABLE public.workout_sets ADD COLUMN IF NOT EXISTS set_type text NOT NULL DEFAULT 'effective';
ALTER TABLE public.workout_sets DROP CONSTRAINT IF EXISTS workout_sets_set_type_check;
ALTER TABLE public.workout_sets ADD CONSTRAINT workout_sets_set_type_check CHECK (set_type IN ('effective','backoff','warmup'));
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS weekly_goal integer NOT NULL DEFAULT 3;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_weekly_goal_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_weekly_goal_check CHECK (weekly_goal BETWEEN 1 AND 7);
-- Existing series default to 'effective' until users edit them.
