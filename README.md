# primeTrack v1.2 — test build

## IMPORTANT: DO NOT DELETE YOUR EXISTING v1.1 PROJECT
This is a separate upgrade package. **Not yet production security-audited or end-to-end tested.**

### Install (Windows)
1. Extract this ZIP into a NEW folder; keep your working v1.1 folder unchanged.
2. Copy `.env.local` from your working v1.1 folder into the new project folder, beside `package.json`. **Never send or commit `.env.local`.**
3. In your existing Supabase project open SQL Editor. Make a database backup, then run **only** `supabase/upgrade_v1_2.sql` (v1.1 must already have been applied). Do **not** rerun `schema.sql`.
4. Open a terminal in this folder and run `npm.cmd install`, then `npm.cmd run dev`.
5. Open `http://localhost:3000` and sign in with your existing account. Test using a *new disposable routine* first.
6. If anything fails, keep using your original v1.1 code and send the exact error. The additive migration preserves old data, but the database schema remains upgraded.

### What this build includes
- Reusable named routines and multiple exercises per workout.
- The previous completed session for the **same routine** is shown beside **blank** inputs for today.
- Manual effective/back-off/warm-up selection and per-set notes.
- Save or edit sessions atomically through `save_training_session` database function.
- Per-user favorites and custom exercises; expanded built-in names (Smith incline, weighted dips, neck).
- Local device draft persistence (browser localStorage) scoped to signed-in account; not cross-device/offline sync.
- Exercise weight/reps/volume trend, estimated 1RM (Epley formula), in-session improvement and PR indicators.
- Weekly summary, training calendar, English/Spanish preference, mobile layout and PWA manifest/icon.
- Existing bodyweight and private photo sections retained.

### Known limitations and safety
- This build has not been tested against your live Supabase schema. A migration failure must be resolved before use.
- PWA manifest and icon enable **Add to Home Screen** after HTTPS deployment; this package does not implement offline service-worker caching.
- Existing workouts remain in History and can be edited, but older workouts are **not automatically linked to newly created routines**.
- The exercise list combines built-in names and your logged exercise names; the separate Supabase `exercise_catalog` table is not yet integrated in the UI.
- The progress chart covers the 200 most recent sessions and up to 1,000 sets per batch; older data may not be plotted. PR indicators use the loaded data and are preliminary, not a lifetime-guaranteed PR.
- Historical weekly-goal changes are not snapshotted, so changing the goal can change displayed past streaks.
- A draft is saved in localStorage on the current device; clear it when sharing a device. The current code doesn't guarantee preservation of unsaved work during browser storage clearing.
- A saved routine's exercise list is updated when you choose “Update routine template”. Changes to a single session alone do not modify the routine.
- Neck exercises should be performed conservatively; stop if pain occurs.
- **Do not deploy publicly yet:** check RLS, Storage policies, Supabase Security Advisor, auth redirect settings, npm audit and two-user isolation. Add privacy policy and account deletion before broad release.
- This is a test build, not a promise of zero bugs or commercial readiness.
