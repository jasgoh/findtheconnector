# Connector Recognizer: setup

## 1. Supabase (about 5 minutes)
1. Create a project at supabase.com.
2. Open **SQL Editor > New query**, paste the contents of `supabase-setup.sql`, and click **Run**.
   This creates the tables, the photo storage bucket, and the matching function for the future Recognize tab.
3. Go to **Project Settings > API** and copy the **Project URL** and the **anon public** key.

## 2. Connect the site
Open `index.html`, find the CONFIG block near the bottom, and paste in your values:

```js
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'eyJ...';
```

The anon key is designed to be public; access is controlled by the policies in the SQL file.

## 3. Deploy to Netlify
Drag the `connector-recognizer` folder onto app.netlify.com/drop, or connect it to a Git repo.
No build step is needed. Netlify serves it over HTTPS, which phone cameras require.

## How training works
Each saved photo is run through MobileNet in the browser, which turns it into 1,280 numbers
describing what it looks like. That "fingerprint" is stored in Supabase alongside the photo.
Recognition will compare a new photo's fingerprint against all stored ones, so adding a
connector never requires retraining.

## Security note
The included policies let anyone with the site URL add or delete data. That's fine for an
internal prototype. Before sharing widely, add Supabase Auth and restrict the insert/delete
policies to signed-in users.

## Known limits
- iPhone HEIC files uploaded from a computer are skipped; photos taken through the
  "Take photo" button arrive as JPEG automatically.
- Photos are resized to 512 px on the longest side before upload to save storage.

## LCSC quick add
The Train tab can pull official product photos from LCSC using an LCSC part number (C######).
This uses the Netlify Function in `netlify/functions/lcsc.mjs`, which Netlify detects and
deploys automatically. It must stay at exactly that path in the repo. No API key is needed.

The lookup uses the same public data endpoint as LCSC's own product pages. It isn't an official,
documented API, so it could change without notice; if lookups start failing, that's the first place
to check. It only works on the deployed site, not when opening index.html directly from your computer.

## Image cleanup
Every training photo and every scan is cropped the same way before fingerprinting: the plate
colour is detected from the photo's edges, the connector is found as whatever differs from it,
and the image is cropped to the connector with a margin and padded to a square. Colours are
not changed. Settings live in the CONFIG block of index.html (PREPROCESS, FG_THRESHOLD,
CROP_MARGIN). Cropped files end in `.c.jpg`; the Train tab offers to crop older photos and to
delete photos saved by the earlier colour-correcting version (`.p.jpg`), which can't be repaired.
