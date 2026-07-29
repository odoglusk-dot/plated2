# Plated Schema Reference — Complete Column Listing

**Last Updated:** 2026-07-29  
**Status:** All tables consistent with `protein_g`, `carbs_g`, `fat_g` naming

---

## Complete Table Schemas

### `profiles` — User identity & physical stats
```sql
id                uuid primary key
display_name      text
age               int
sex               text ('male' | 'female')
height_cm         numeric
activity_level    text ('sedentary' | 'light' | 'moderate' | 'active' | 'very_active')
created_at        timestamptz
```
**Frontend reads/writes:** `id, display_name, age, sex, height_cm, activity_level`

---

### `goals` — Daily nutrition targets
```sql
user_id     uuid primary key
calories    int (default: 2200)
protein_g   int (default: 150)       ← WITH _g suffix
carbs_g     int (default: 250)       ← WITH _g suffix
fat_g       int (default: 70)        ← WITH _g suffix
updated_at  timestamptz
```
**Frontend reads/writes:** `user_id, calories, protein_g, carbs_g, fat_g, updated_at`  
⚠️ **CRITICAL:** All macros use `_g` suffix. If your DB has `protein`, `carbs`, `fat` (without `_g`), goals won't display properly.

---

### `body_stats` — Current weight for goal calculator
```sql
user_id     uuid primary key
weight_kg   numeric
updated_at  timestamptz
```
**Frontend reads/writes:** `user_id, weight_kg, updated_at`

---

### `food_logs` — Daily food log entries
```sql
id          uuid primary key
user_id     uuid
food_name   text
calories    numeric
protein_g   numeric         ← WITH _g suffix
carbs_g     numeric         ← WITH _g suffix
fat_g       numeric         ← WITH _g suffix
source      text ('manual' | 'ai_text' | 'ai_photo' | 'favorite' | 'common')
logged_at   timestamptz (indexed)
created_at  timestamptz
```
**Frontend reads:** `logged_at, (all other columns via select(*))`, ordered by `logged_at desc`  
**Frontend writes:** `user_id, food_name, calories, protein_g, carbs_g, fat_g, source`

---

### `food_cache` — Shared nutrition data (all users)
```sql
description_key   text primary key
food_name         text
calories          numeric
protein_g         numeric       ← WITH _g suffix
carbs_g           numeric       ← WITH _g suffix
fat_g             numeric       ← WITH _g suffix
created_at        timestamptz
```
**Frontend reads/writes:** `food_name, calories, protein_g, carbs_g, fat_g`

---

### `favorites` — Saved foods for quick logging
```sql
id          uuid primary key
user_id     uuid
food_name   text
calories    numeric
protein_g   numeric       ← WITH _g suffix
carbs_g     numeric       ← WITH _g suffix
fat_g       numeric       ← WITH _g suffix
created_at  timestamptz
```
**Frontend reads:** `id, food_name, calories, protein_g, carbs_g, fat_g`  
**Frontend writes:** `user_id, food_name, calories, protein_g, carbs_g, fat_g`

---

### `weight_log` — Weight tracking history
```sql
id          uuid primary key
user_id     uuid
logged_date date (indexed)
weight_lb   numeric
note        text (optional)
created_at  timestamptz
```
**Frontend reads:** `logged_date, weight_lb, note` (via select(*), order by `logged_date desc`)  
**Frontend writes:** `user_id, logged_date, weight_lb, note`

---

### `supplement_logs` — Supplement intake tracking
```sql
id               uuid primary key
user_id          uuid
supplement_name  text
dose             text (optional)
logged_at        timestamptz (indexed)
created_at       timestamptz
```
**Frontend reads:** `supplement_name, dose, logged_at` (via select(*), order by `logged_at desc`)  
**Frontend writes:** `user_id, supplement_name, dose`

---

### `ai_usage` — Daily AI call rate limiting
```sql
user_id      uuid
usage_date   date
count        int (default: 0)
primary key  (user_id, usage_date)
```
**Backend reads/writes:** `user_id, usage_date, count`  
(Frontend never touches this table directly)

---

## Naming Rules — CONSISTENT across ALL tables

| Type | Naming | Example | Notes |
|------|--------|---------|-------|
| **Macros** | `_g` suffix | `protein_g`, `carbs_g`, `fat_g` | All tables use this |
| **User ID** | `user_id` | (uuid) | Every personal table has this |
| **Primary ID** | `id` | (uuid) | Except goals & body_stats which use `user_id` as PK |
| **Dates (tracking)** | `logged_date` or `logged_at` | food_logs: `logged_at`, weight_log: `logged_date` | Consistent within table |
| **Updated/Created** | `updated_at`, `created_at` | (timestamptz) | Standard naming |

---

## How to Fix Mismatches

### If you see "protein", "carbs", "fat" (without _g) in your database:

1. **Use the reset script:**
   ```
   Run reset-schema.sql in Supabase SQL editor
   ```
   This drops and recreates ALL tables with correct naming.

2. **Or manually fix goals table:**
   ```sql
   -- If your goals table has wrong column names, recreate it:
   drop table goals cascade;
   
   create table goals (
     user_id uuid primary key references auth.users(id) on delete cascade,
     calories int not null default 2200,
     protein_g int not null default 150,  -- Note: _g suffix
     carbs_g int not null default 250,    -- Note: _g suffix
     fat_g int not null default 70,       -- Note: _g suffix
     updated_at timestamptz not null default now()
   );
   
   alter table goals enable row level security;
   create policy "goals: select own" on goals for select using (auth.uid() = user_id);
   create policy "goals: insert own" on goals for insert with check (auth.uid() = user_id);
   create policy "goals: update own" on goals for update using (auth.uid() = user_id);
   ```

### Why goals shows blank for protein/carbs/fat:

The app tries to read from `protein_g`, `carbs_g`, `fat_g` but your database has `protein`, `carbs`, `fat`. Supabase returns `null` for missing columns, so they display as blank.

---

## Verification Checklist

Run this in Supabase SQL editor to verify your schema is correct:

```sql
-- Check goals has correct column names
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'goals' AND column_name LIKE '%protein%';
-- Should return: protein_g

-- Check food_logs has correct column names
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'food_logs' AND column_name LIKE '%carbs%';
-- Should return: carbs_g

-- Check all _g columns exist
SELECT table_name, column_name FROM information_schema.columns 
WHERE column_name IN ('protein_g', 'carbs_g', 'fat_g') 
ORDER BY table_name;
-- Should show these columns in: goals, food_logs, food_cache, favorites
```

---

## Files to Run (in order)

1. **`reset-schema.sql`** — Complete reset (drops all, recreates fresh)
2. OR manually run the two incremental schemas:
   - `supabase-schema.sql` → creates core tables
   - `supabase-schema-additions.sql` → creates features

Pick **one approach**: either reset-schema.sql (easiest), or the two incremental files if you prefer to keep data and fix columns one at a time (harder, more error-prone).
