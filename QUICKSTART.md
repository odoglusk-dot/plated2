# Plated Quick Start

## For Users (Already Deployed)

Just visit your Plated URL and sign up:

1. **Sign up** with email + password
2. **Set your profile** (height, weight, age, gender, goal weight)
3. **Log food** — search common foods or use AI to estimate
4. **Check dashboard** — watch your rings fill up as you hit targets

That's it. Daily macro tracking is now live.

## For Developers (Self-Hosting)

### Prerequisites
- Supabase account (free tier works)
- Netlify account (free tier works)
- Anthropic API key (~$1-2/month for casual use)

### Deploy in 10 Minutes

1. **Create Supabase project**
   - Go to https://supabase.com and create a project
   - Copy Project URL and anon key

2. **Run schema in SQL Editor**
   - Paste the entire contents of `reset-schema.sql`
   - Execute

3. **Create Netlify site**
   - Connect your GitHub repo to Netlify
   - Add environment variables:
     - `SUPABASE_URL` = your Project URL
     - `SUPABASE_ANON_KEY` = your anon key
     - `ANTHROPIC_API_KEY` = your API key from https://console.anthropic.com
   - Deploy (auto-deploys on git push)

4. **Update frontend config**
   - Edit `index.html` line 240-241
   - Replace `SUPABASE_URL` and `SUPABASE_ANON_KEY` with your values
   - Commit and push

5. **Visit your site**
   - Netlify provides a URL (usually `your-site.netlify.app`)
   - Sign up and start tracking

## Key Features

| Feature | How to Use |
|---------|-----------|
| **Log food** | Dashboard → Log Food tab → Search or estimate |
| **View history** | History tab → See last 90 days |
| **Track weight** | Weight tab → Log daily |
| **Set goals** | Profile tab → Goal Calculator → Input stats |
| **View macros** | Dashboard → Rings show progress |
| **Export data** | History tab → Download CSV |

## Tips

- **Exact match search**: Type "Chicken breast (6oz, cooked)" from the database
- **AI estimation**: "chicken breast 6oz with rice" → auto-fills macros
- **Photo estimation**: Take a pic of your meal → get macros instantly
- **Daily limit**: 20 AI estimates per day (but cache hits are free!)
- **Streaks**: Hit your protein goal daily to build your streak

## Costs

**Free tier is fine for personal use:**
- Supabase: Free (includes 500MB storage, unlimited API calls)
- Netlify: Free (includes 125 function invocations/month)
- Anthropic: Pay-as-you-go (~$0.003 per food estimate)

If you log ~10 foods/day, that's ~$0.03/day in AI costs.

## Troubleshooting

**"Sign in required" but I'm signed in**
→ Clear browser cache and try again

**Photos not estimating**
→ Check you have remaining API calls (shown on Log tab)

**Foods not in search**
→ Must match exactly — "Chicken breast (6oz, cooked)" not "chicken"

**Can't find food in database**
→ Use AI estimate: "steak with potatoes" → done

## Need Help?

- **Schema issues**: Check `SCHEMA-REFERENCE.md`
- **Deployment**: Check `DEPLOYMENT.md`
- **Food database**: Check `COMMON_FOODS_DATABASE_CURRENT.md`

