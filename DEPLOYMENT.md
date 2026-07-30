# Plated Deployment Guide

## Overview

Plated is a macro & supplement tracker built with:
- **Frontend**: Single-file vanilla JavaScript with Supabase JS SDK (no build step)
- **Backend**: Netlify serverless functions as API gateway
- **Database**: Supabase (PostgreSQL + Auth + Row Level Security)
- **AI**: Claude via Anthropic API for macro estimation from text & photos

## Prerequisites

1. **Supabase project** — for database, auth, and storage
2. **Netlify account** — for serverless functions
3. **Anthropic API key** — for food macro estimation

## Setup Steps

### 1. Supabase Database Setup

1. Create a new Supabase project at https://supabase.com
2. Copy your `Project URL` and `anon key` (find these in Project Settings → API)
3. Run the schema creation script in SQL Editor:
   - Open `reset-schema.sql` in your Supabase SQL Editor
   - Execute the entire script to create all 9 tables with RLS policies

**Tables created:**
- `profiles` — user metadata
- `goals` — daily macro targets (calories, protein_g, carbs_g, fat_g)
- `body_stats` — height, weight, age, gender for Mifflin-St Jeor calculator
- `food_logs` — daily food entries with macros
- `food_cache` — shared cache of estimated foods (text + photo)
- `favorites` — user's saved food items
- `weight_log` — weight tracking history
- `supplement_logs` — supplement usage
- `ai_usage` — daily API call counter (20 calls/day limit per user)

### 2. Netlify Functions Setup

1. Create a new Netlify site from Git (connect your repo)
2. Go to Site Settings → Build & Deploy → Environment
3. Add these environment variables:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=eyJhbGc...
   ANTHROPIC_API_KEY=sk-ant-...
   ```
4. Set Build Command to: `echo "Netlify Functions ready"`
5. Set Functions Directory to: `netlify/functions`

The functions deploy automatically on git push.

### 3. Update Frontend Configuration

Edit `/index.html` and replace the Supabase credentials:

```javascript
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGc...';
```

Deploy the frontend:
- For **Netlify**: Commit and push (auto-deploys)
- For **other hosting**: Run `npm install -g http-server && http-server`

## API Endpoints

### POST `/api/estimate-macros`

Estimate macros from a text description.

**Request:**
```json
{
  "description": "grilled chicken breast 6oz with brown rice"
}
```

**Response:**
```json
{
  "food_name": "Grilled chicken breast (6oz, cooked) with brown rice (1 cup)",
  "calories": 445,
  "protein_g": 58,
  "carbs_g": 45,
  "fat_g": 4,
  "confidence": "high",
  "remaining": 19,
  "cached": false
}
```

**Rate limit:** 20 calls per day per user (shared cache reduces usage)

### POST `/api/estimate-macros-photo`

Estimate macros from a food photo.

**Request:**
```json
{
  "imageBase64": "iVBORw0KG...",
  "mediaType": "image/jpeg",
  "note": "about 6oz chicken with rice"
}
```

**Response:** Same as `estimate-macros` + `cached` flag

**Cache:** Uses hash of image + note; same photo returns instantly

## Food Database

**373 foods** available for instant lookup (zero API calls):

- Poultry (12)
- Fish & Seafood (22)
- Beef & Pork (22)
- Eggs & Dairy (32)
- Alternative Proteins (10)
- Legumes & Beans (10)
- Grains & Starches (47)
- Vegetables (44)
- Potatoes & Tubers (9)
- Fruits (34)
- Nuts & Seeds (20)
- Nut Butters & Spreads (11)
- Healthy Fats & Oils (11)
- Beverages (13)
- Fast Food & Chains (23)
- Snacks & Bars (21)
- Soups & Broths (8)
- Condiments & Sauces (12)

**Lookup:** Exact match, case-insensitive, using Ctrl+F or search inputs

## Features

### Dashboard
- Ring-based progress toward daily goals (calories, protein, carbs, fat)
- Streak calculation (consecutive days hitting protein target)
- Quick add buttons for common meal times

### Log Food
1. **Common Foods** — Instant lookup (373 options)
2. **AI Text Estimate** — "grilled chicken breast 6oz" → auto-filled macros
3. **AI Photo Estimate** — Take a photo → estimate macros
4. **Manual Entry** — Type food name + macros directly
5. **Favorites** — Save frequently-logged foods

### History
- List of last 90 days of food logs
- Streak calculations
- CSV export for external analysis

### Weight Tracking
- Log weight daily
- SVG line chart (trend visualization)
- Compare to goal weight

### Supplements
- Log supplement usage
- 10-item guide (common vitamins, minerals, herbs)
- Dosage + timing notes

### Ask Your Data
- "How much protein have I logged this week?"
- Query your own logs (runs against your data only)

### Profile
- **Goal Calculator** — Mifflin-St Jeor TDEE calculator
  - Input: Height (ft/in), Weight (lb), Age, Gender
  - Output: Maintenance TDEE + surplus/deficit targets
  - Also set explicit goal weight for deficit/surplus calculation
- **Account Settings** — Change password, delete account

## Calorie & Macro Calculation

**Mifflin-St Jeor Formula:**

For men:
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
```

For women:
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
```

Then multiply by activity factor:
- **Maintenance** (1.0) — BMR × 1.55 (assuming light activity)
- **Surplus** (+500 kcal) — for muscle gain
- **Deficit** (-500 kcal) — for weight loss

Or if goal weight is set: calculate deficit/surplus based on weight difference.

## Daily AI Budget

**20 API calls per day per user** (shared cache):

- Estimate from text = 1 call
- Estimate from photo = 1 call
- If food already cached (previous estimate) = 0 calls ✓

Example:
- Day 1: User A logs "chicken" → 1 call, cached
- Day 1: User B logs "chicken" → 0 calls (User A's cache hit) ✓

## Security

**Row Level Security (RLS):**
- Users only see/modify their own data
- Verified via Supabase JWT token
- No manual SQL queries in frontend

**Authentication:**
- Supabase Auth (email + password)
- Session stored in browser localStorage
- Auto-logout on sign-out

**Credentials:**
- No API keys in frontend (only anon key, which is safe)
- Anthropic API key stored in Netlify env vars (never exposed)
- Supabase JWT tokens verified server-side

## Monitoring

### Check API Usage
In Supabase SQL Editor:
```sql
SELECT user_id, usage_date, count 
FROM ai_usage 
WHERE usage_date = current_date 
ORDER BY count DESC;
```

### Check Food Cache Hits
```sql
SELECT description_key, food_name, created_at 
FROM food_cache 
ORDER BY created_at DESC 
LIMIT 20;
```

### Check Error Logs
- Netlify: Logs → Functions
- Browser console: Open DevTools (F12)

## Troubleshooting

### "Sign in required" but logged in
- Check browser localStorage for `sb-auth-token`
- Try signing out and back in
- Clear browser cache (Ctrl+Shift+Delete)

### "Could not estimate macros"
- Check remaining API calls (shown on Log tab)
- Check Netlify function logs for errors
- Verify Anthropic API key is set in Netlify env vars

### Macros not syncing to database
- Open browser DevTools (F12) → Network tab
- Check response from POST `/api/` calls
- Verify Supabase auth RLS policies are correct

### Foods not appearing in search
- Exact match only — type full name from database
- Example: "Chicken breast (6oz, cooked)" not "chicken"
- Use browser Find (Ctrl+F) to see all options

## Future Enhancements

- [ ] Fuzzy search for food lookup
- [ ] Barcode scanning (UPC → nutrition database)
- [ ] Social features (share meals, compete on streaks)
- [ ] Custom meal templates (pre-built combos)
- [ ] Export to Apple Health / Google Fit
- [ ] Mobile native app (React Native)

