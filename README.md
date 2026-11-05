# SMS Edge Dashboard — independent copy

A separate copy of the SMS Edge campaign dashboard, with its own Supabase
database and its own Vercel deployment. It shares nothing with the original:
no database, keys, domain or Git history.

The app is a single static page (`index.html`): no server code, no logins, no
file storage. The browser talks to Supabase directly with the project's public
"anon" key.

## What's in here

| Path | What it is |
|---|---|
| `index.html` | The whole dashboard: layout, styles and logic |
| `styles.css`, `script.js` | Carried over from the original. The page doesn't load them, but they're deployed the same way |
| `scripts/build.js` | Build step: copies the site into `dist/` and writes `dist/config.js` from environment variables |
| `vercel.json` | Vercel settings: runs the build, serves `dist/`, sets security and cache headers |
| `.env.example` | The two environment variables the build needs |
| `config.example.js` | Template for opening `index.html` straight from disk without a build |
| `supabase/migrations/001_initial_schema.sql` | Creates every table, index, trigger and access policy |

Changes from the original:

- The Supabase URL and key are no longer hard-coded. They come from
  `SUPABASE_URL` and `SUPABASE_ANON_KEY` at build time. Without them the
  dashboard shows "Offline" in the header and can't save.
- It starts with no data. The original's built-in campaigns, content rows,
  registered lists, one-time NZ planner dates, and the hardcoded
  Break-Even Tracker and Benchmarks tables were removed. Everything fills in
  from your own CSV imports. Kept as settings: the active routes, SMS route
  pricing, and the industry benchmark ranges.

## Deploying it

You need: a Supabase account, a Vercel account, and (for the Git route) a
GitHub account. Use a **new** Supabase project and a **new** Vercel project —
don't reuse the original's.

### 1. Create the Supabase project

1. In Supabase, click **New project**. Pick a name, a database password (save
   it in your password manager) and a region close to your users.
2. Wait for it to finish setting up (a minute or two).
3. Open **SQL Editor → New query**, paste the whole of
   `supabase/migrations/001_initial_schema.sql`, and click **Run**. It should
   say "Success. No rows returned".
4. Check **Table Editor**: you should see 8 tables — `campaigns`,
   `content_rows`, `planned_sends`, `list_decisions`, `list_decision_history`,
   `list_sizes`, `active_routes`, `list_registry`.
5. Open **Project Settings → API** and copy two values:
   - **Project URL** (`https://<ref>.supabase.co`) → this is `SUPABASE_URL`
   - **anon / public** key → this is `SUPABASE_ANON_KEY`

   Do **not** use the `service_role` key anywhere in this app.

### 2. Put the code on GitHub

This copy lives at `https://github.com/MasterGroup1/External`. To set up a
fresh repository instead, create a **new, private** one, then in this folder:

```
git init
git add .
git commit -m "Initial copy of SMS Edge dashboard"
git branch -M main
git remote add origin https://github.com/<you-or-your-org>/<repo>.git
git push -u origin main
```

`.gitignore` keeps `.env`, `config.js` and `dist/` out of the repository.

### 3. Create the Vercel project

1. In Vercel, click **Add New → Project** and import the new repository.
2. Framework preset: **Other**. Leave Build Command and Output Directory
   empty — `vercel.json` sets them (`node scripts/build.js`, `dist`).
3. Under **Environment Variables**, add `SUPABASE_URL` and
   `SUPABASE_ANON_KEY` from step 1.5, for Production, Preview and
   Development.
4. Click **Deploy**. If either variable is missing, the build stops with a
   clear error instead of publishing a dashboard that can't save.
5. Open the deployment URL. The header should show a green **Live** dot.

**Custom domain:** Vercel → your project → **Settings → Domains → Add**, then
add the DNS record Vercel shows you at your domain registrar.

After this, every push to `main` redeploys automatically. If you change an
environment variable, redeploy (Deployments → ⋯ → Redeploy) for it to take
effect.

### 4. Check it works

- Header shows **Live** (green), not Offline.
- **Master List Planner**: set a List Size or a Send-or-Not decision, refresh
  — it's still there.
- **+ Add List**: add a test list such as `Roy Boy_IT_01012027_batch1`,
  refresh — it's still there, then delete it.
- Import a campaign CSV and check the numbers appear.

## Running it locally

- **Quickest:** copy `config.example.js` to `config.js`, fill in the two
  values, and open `index.html` in a browser.
- **With Node installed:** copy `.env.example` to `.env`, fill it in, run
  `npm run build`, and open `dist/index.html`.

## Troubleshooting

| What you see | Likely cause |
|---|---|
| Header says **Offline** on Vercel | Environment variables missing or wrong. Check them, then redeploy |
| Console: `Could not find the table ... in the schema cache` | The SQL in step 1.3 wasn't run (or failed), in *this* project |
| Console: `permission denied for table ...` | Re-run the SQL; its last section grants access |
| Only 1,000 rows show | Shouldn't happen — the dashboard pages through results. If it does, check Project Settings → API → Max Rows |

## Locking it down

Like the original, this dashboard has no login. The access policies let
anyone who has the site URL and the public key read and change the data.
That's how the original works, but if the URL could reach people outside
your team, consider:

- **Vercel → Settings → Deployment Protection** to put the site behind a
  Vercel login or password, or
- adding Supabase Auth and replacing the `to anon` policies in the SQL with
  `to authenticated`. That needs a login screen added to the app.

## Things that carry over from the original

- **Settings, not data:** on first load, the 37 active routes built into
  `index.html` are written to `active_routes`. Edit or delete them on the
  Routes tab. The Pricing tab's route prices and the Benchmarks tab's
  industry ranges are also built in.
- **Third-party services:** none besides Supabase. The page loads Chart.js
  and supabase-js from the jsDelivr CDN and the Inter font from Google Fonts,
  with no keys involved. The short links inside SMS copy (`*.click`, `*.sbs`)
  are message text, not integrations.
