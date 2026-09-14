# SplitEZ Home Screen Design Reference

## Screen: 01 · HOME · FILTERS + BANNER AD

### Logo (Split Coin)
- Two halves of a circle, shifted apart with a visible gap
- Left half: light indigo #818CF8
- Right half: deep indigo #4338CA
- Nearly vertical cut (~3°)
- Rules: light indigo always left, deep indigo always right
- Minimum size 20px on screen

### Header (dark navy #10142A)
- Logo + "SplitEZ" (Split in white, EZ in light indigo #818CF8)
- Right side: search icon + settings icon (white)
- "Overall, you are owed" in muted text
- Large balance amount in green (₹1,220) with INR dropdown

### Content Area (white, rounded top corners)
- Filter pills: All (filled dark), Owed, You owe, Hide settled
- "Groups & trips" section header with "See all" link
  - Rows with icon circle, name, subtitle (X people · Group/Trip), balance on right
  - Red for "you owe", green for "owes you"
- "Friends" section header with "See all" link
  - Rows with avatar (letter circle), name, phone number, balance or "Settled" badge

### Sponsored Banner (bottom of content)
- Light gray background, rounded corners
- "AD" badge, "Sponsored" title, "Remove ads · SplitEZ Plus ₹99/mo"
- "Go Plus" button with border

## Screen: 04 · ACTIVITY · SORTABLE

### Header (dark navy #10142A)
- "Activity" title in large bold white text
- Right side: search icon + download/export icon (white)
- Sort pills: Date ↓ (active, indigo filled), Name, Type, Amount (inactive, white 12% opacity)
- Active sort pill shows down arrow

### Content Area (white, rounded top corners)
- Grouped by day: TODAY, YESTERDAY, older dates (section labels in indigo, uppercase, caption weight)
- Each row: colored icon circle (44pt), bold name + action text, subtitle, amount or time on right
- Icon colors by type:
  - Settlement/paid back: green checkmark on green tint
  - Expense added: amber fork.knife on amber tint
  - Group/trip: indigo house/paperplane on indigo tint
  - Reminder: red clock on red tint
- Amounts: green for incoming (+ ₹450), red for outgoing (– ₹800)
- Dividers between rows within same day group (indented past icon)

### Tab Bar (5 tabs) — DARK NAVY background (#10142A)
- Background: dark navy (SplitEZTheme.darkBg), NOT white
- Active tab: white text/icon
- Inactive tab: white at 45% opacity
- Home (house icon, filled when active)
- Friends (people icon, filled when active)
- Add (center, indigo circle with + icon, elevated above bar)
- Activity (branch/arrow icon)
- More (three dots icon)
