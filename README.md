# Tool Room: setup

Equipment guides and a connector scanner for the lab.

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

To change the wording of a procedure, edit the `steps` text only. To add a new tool, copy the PAD-11's
structure (the PAD-11 is Fig. 02). Drawing helpers (`prism`, `tube`) build parts from 2D outlines;
a tool can set its own camera (`EQ.setView`), shading (`look: 'real'` plus gradient `defs`) and a `zoom` state for close-ups.

People who have asked their device to reduce motion see each step's end position without the animation.

## Equipment guides
The tab has an Electrical / Mechanical switch; every tool sets `cat` ('electrical' if left out).

Mechanical:
- Fig. 01, Power drill (Makita cordless drill, from the supplied CAD model): tasks for the battery, fitting a drill bit, and torque and speed.
  The drill is drawn from the CAD model at the same angle as the manual's picture. The parts that move (battery, release button, trigger, reversing
  lever, speed lever, chuck sleeve, adjusting ring) are separate layers cut from the model, so the steps animate the real parts. The ring numbers
  (1 2 4 6 ... 18 and a dash), the logo, the red indicator, the check lamps and the drill bit are drawn over it. The text follows Makita's instruction manual.
- Fig. 02, Centre punch: marking out with rule and scriber, finding the crossing, tapping and deepening the mark.
- Fig. 03, Vernier caliper (0.05 mm): reading the scale, and outside, inside, depth and step measurements.
- Fig. 04, Tap and die: tapping a hole and threading a rod, M3–M8 (tap drill ≈ diameter − pitch).

Electrical:

- Fig. 01, Wire stripper (Engineer PA-06): 7 steps. The Wire size box picks the stripping hole from Engineer's chart
  (0.4 to 1.45 mm holes for AWG 30-18 stranded and AWG 28-16 solid).
- Fig. 02, Engineer PAD-11 micro crimper: 11 steps, with the terminal picker below.
- Fig. 03, Lug crimper (VCELINK GJ707): 7 steps, following VCELINK's operation instruction. Red, blue and yellow
  nests for insulated terminals (22-18, 16-14 and 12-10 AWG); the Wire size box picks the nest.
- Fig. 06, Multimeter (Fluke 115): leads and safety, DC voltage, resistance, continuity, diode test and current,
  following the Fluke 114/115/117 user manual (COM / V Ω / 10 A FUSED terminals, continuity beep below ~20 Ω).
- Fig. 05, Soldering iron: five tasks (now including heat-set inserts in 3D-printed parts); chosen in the Task box (tinning wires, splicing wires with a lap splice
  (both ends fluxed and tinned, laid together, fluxed and soldered), XT30/XT60/XT90 solder cups, soldering a wire to a pad). Acceptance points follow IPC J-STD-001,
  IPC-A-610 and IPC/WHMA-A-620; iron temperatures are typical values, not IPC requirements.
- Fig. 04, Ferrule crimper (VCELINK GJ709): 7 steps, following VCELINK's operation instruction, including the
  tension test. Self-adjusting, 0.25-6 mm²; the Wire size box picks the ferrule (collar colours per DIN 46228-4).

## PAD-11 terminal picker
Seven lab terminals are built in as quick picks, each with its own model and the lab's die sizes:
Molex Micro-Fit 3.0 43030-0007 (1.6/1.6), Molex Nano-Fit 105300-1100 (1.3/1.6), Hirose DF11-2428SCF
(1.3/1.6), Molex PicoBlade 50079-8000 (1.0/1.0), JST GH SSHL-002T-P0.2 (1.0/1.0), JST SH SSH-003T-P0.2-H
(1.0/1.0) and JST RCY SYF-001T-P0.6 (1.6/1.9), listed as conductor/insulation die in mm. They're in
`PAD11_PRESETS`; their shapes are in `TERM_SPECS` (approximate, from datasheet outline sizes and wire ranges).

The Equipment tab's PAD-11 guide also has a search box listing every terminal Engineer rates for the PAD-11
(279 part numbers from Engineer's JST, Molex, TE, Hirose and JAE compatibility tables). Engineer doesn't
publish which die each terminal uses, so the lab records it: pick a terminal, choose the conductor and
insulation dies, and save. The animation, labels and step text then use those dies.

To share recorded die sizes with everyone, run `add-pad11-dies.sql` once in Supabase (SQL Editor > New
query > paste > Run). Without it, die sizes only last until the page is reloaded.

## Colours and theme
Colours match the Stockroom (stock and orders) app: paper and card surfaces, an amber accent, pine for
success and rust for errors. Dark mode is the default; the button in the header switches to light and the
choice is remembered in that browser.

## Basics tab
Reference guides shown with the same step viewer as Equipment (`makeGuideUI` builds both; the Basics tab uses
the `bs` element-id prefix). Topics live in the `BASICS` array and use the same shape as equipment tools.

Mechanical: Screws (anatomy, head styles, measuring e.g. M3 × 10, drive types) and Drill bits (anatomy, measuring).
Electrical: Connectors (interactive 3D crimp terminals, below), Wire (finding the gauge, gauge for the current, insulation and housing materials), Solder (leaded vs
lead-free, flux types) and Resistor colour codes. Ampacity figures are the common chassis-wiring guide values for a
single wire in open air; derate for bundling, enclosure, temperature and length.

### Connectors (3D)
Basics → Electrical → Connectors shows each crimp terminal as an interactive 3D model (three.js r128, loaded from
cdnjs only when the topic opens). Drag to rotate, scroll or pinch to zoom; buttons for 3D / Side / Top / Mating end
views, a Wire overlay, and Actual size (1:1 on screen after a one-time bank-card calibration, saved in
localStorage as `cn-pxmm`). Families: Micro-Fit 3.0, Nano-Fit, Dupont 2.54 mm, JST GH, JST PH (the linked C111515
is SPH-002T-P0.5S, a PH terminal), JST RCY/SM and Mega-Fit, male and female where both were linked.
Series, wire range, insulation OD and plating come from the LCSC listings. The Micro-Fit male (43031) and female
(43030-0007) are the real Molex STEP models, triangulated and embedded (`MF_MESH`, quantised). Every other
terminal is that real mesh reshaped section by section (insulation wings, conductor wings, transition/barrel,
contact) to its family's size (`sec` in `CONN_PARTS`); those sizes are approximate and the manufacturer's sales
drawing is the reference. The RCY/SM female keeps the real rear half with a modelled slit tube socket.
The JST PH female (SPH-002T-P0.5S) is a real STEP model, tessellated from the manufacturer file and embedded as `MF_MESH.ph` (`real: 'ph'` in `CONN_PARTS`).
