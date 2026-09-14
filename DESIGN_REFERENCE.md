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

## Screen: 02 · FRIENDS

### Header (dark navy #10142A)
- "Friends" title large bold white
- Right side: QR code icon + add friend (person.badge.plus) icon (white)
- Search bar: rounded rect, white 10% opacity fill, magnifying glass + placeholder "Search friends"

### Content Area (white, rounded top corners)
- "All friends" header with count (· X) + Sort button (indigo, line.3.horizontal.decrease icon)
- Friend rows: avatar circle (44pt), name bold, phone subtitle, balance on right
  - Green "owes you" / red "you owe" with amount
  - "Settled" green outlined capsule badge when balance = 0
- Empty state: "No friends added yet" or "No results" for search

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

## Screen: 17 · SETTINGS · FREE USER

### Header (dark navy #10142A)
- "Account" title centered in white
- User avatar with dashed indigo border circle, QR badge bottom-left
- Name bold white, email muted below
- Edit (pencil) icon on right

### Upgrade Banner
- Indigo gradient background, rounded corners
- "Get SplitEZ Ad Free" bold white, "No ads · priority support · exports" subtitle
- Gold "₹99/mo" pill on right

### Content (white, rounded top corners)
- PREFERENCES section: Notifications, Security, Appearance, Currency & language (shows "INR · EN" value)
- HELP & SUPPORT section: Contact us (with envelope icon), Rate SplitEZ
- Red "Log out" button full width
- Footer: "An Adrevo Product" with indigo circle, "© 2026 SplitEZ · 1.0.0"

## Screen: 05 · MORE TAB

### Header (dark navy #10142A)
- "More" title large bold white

### Content (white, rounded top corners)
- MANAGE section: Groups (rectangle.3.group, indigo), Trips (paperplane, orange), Expenses (creditcard, teal)
- FINANCES section: Finances (chart.pie, green), Export (square.and.arrow.up, blue), Import (square.and.arrow.down, purple)
- ACCOUNT section: Notifications (bell, red), Settings (gearshape, gray)
- Each row: colored rounded-rect icon (36pt), label, chevron right
- Section labels: uppercase, caption weight, tertiary color

## Global Components

### Sponsored Banner (persistent above tab bar)
- Light gray background
- "AD" badge, "Sponsored" title, "Remove ads · ₹99/mo"
- "Go Plus" outlined button
- Shows on: Home, Friends, Activity, Settings, Groups, Trips, Expenses, Finances, Export/Import, Notifications
- NOT on: Add Expense sheet, Login/Auth screens

### Tab Bar (5 tabs) — DARK NAVY background (#10142A)
- Background: dark navy (SplitEZTheme.darkBg), NOT white
- Active tab: white text/icon
- Inactive tab: white at 45% opacity
- Home (house icon, filled when active)
- Friends (people icon, filled when active)
- Add (center, indigo circle with + icon, elevated above bar)
- Activity (branch/arrow icon)
- More (three dots icon)
