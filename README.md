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

## 3. Deploy to Vercel
1. In Vercel, choose **Add New > Project** and import this GitHub repo.
2. Set **Framework Preset** to **Other**. Leave the build command empty and the output directory as the
   repo root. There's no build step; Vercel serves `index.html` as is, over HTTPS (phone cameras require it).
3. Click **Deploy**. Every push to the main branch redeploys automatically.

All data (connectors, photos, fingerprints and trained classifiers) lives in Supabase, not on the host,
so moving hosts doesn't touch it.

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

## Image cleanup
Every training photo and every scan is cropped the same way before fingerprinting. Colours are
never changed.
1. The 3D-printed plate is found as the large single-colour area around the middle of the photo.
2. Everything outside the plate (bench, tools) is ignored.
3. The connector is found as whatever sits on the plate but isn't plate-coloured.
4. The image is cropped to the connector with a margin and padded to a square.

Settings live in the CONFIG block of index.html:
- CROP_TO: 'connector' zooms to the part (default); 'plate' keeps the whole plate, which
  preserves the connector's real size relative to the plate.
- FG_THRESHOLD: how different from the plate colour a pixel must be to count as connector.
- CROP_MARGIN: space left around the connector.

Each cropped image (`.c2.jpg`) is stored next to its uncropped original (`.orig.jpg`), so if the
cropping method changes later, photos can be reprocessed from the original. If you change these
settings, rename PROCESSED_TAG (for example to '.c3.jpg') and the Train tab will offer to update
every photo. Photos from the earlier colour-correcting version (`.p.jpg`) can't be repaired and
the Train tab offers to delete them.

## Equipment tab
Step-by-step animated guides for lab tools, drawn as hand-inked isometric figures. Everything lives in
`index.html` in the `EQUIPMENT GUIDES` section of the script; there's nothing to set up in Supabase.

Each tool is one object in `EQ_TOOLS`:
- `base`: the figure's starting state (numbers such as how open the handles are, where the wire is).
- `steps`: each step has a `title`, `body`, optional `caution`, the labels to show (`tags`, with `hot` ones
  highlighted in amber), a duration `dur` in ms, and `keys`. Keys are `[time 0–1, { state values }]`;
  values tween from wherever the previous step finished, so a step only lists what changes.
- `flashes`: optional `[time, 'Click']` pop-ups during a step.
- `draw(state)`: returns the SVG for that state plus label positions.

To change the wording of a procedure, edit the `steps` text only. To add a new tool, copy the crimper's
structure; the drawing helpers (`prism`, `tube`, `strip`, `plate`, `shadow`) build parts from 2D outlines.

People who have asked their device to reduce motion see each step's end position without the animation.

## Colours and theme
Colours match the Stockroom (stock and orders) app: paper and card surfaces, an amber accent, pine for
success and rust for errors. Dark mode is the default; the button in the header switches to light and the
choice is remembered in that browser.
