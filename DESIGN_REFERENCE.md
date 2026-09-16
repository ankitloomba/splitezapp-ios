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

## Screen: 02/16 · FRIENDS (with Pending Requests)

### Header (dark navy #10142A)
- "Friends" title large bold white
- Right side: QR code icon + add friend (person.badge.plus) icon (white)
- Search bar: rounded rect, white 10% opacity fill, magnifying glass + placeholder "Search friends"

### Content Area (white, rounded top corners)
- **Pending requests section** (shown when requests exist):
  - "Pending requests" header with red count badge (capsule, white text on negative red)
  - Request rows: avatar (44pt), name bold, source/email subtitle
  - Accept button: green checkmark in green-tinted circle
  - Reject button: gray X in gray circle
  - Divider separates from All friends section
- "All friends" header with count (· X) + Sort button (indigo, line.3.horizontal.decrease icon)
- Friend rows: avatar circle (44pt), name bold, subtitle "X groups · last active Xd ago"
  - Falls back to phone number if no group/activity data
  - Green "owes you" / red "you owe" with ₹ amount
  - "settled up ₹0" (green) when balance = 0
  - Dividers between rows (indented past avatar, 76pt leading)
- Empty state: "No friends added yet" or "No results" for search

## Screen: 02B · INDIVIDUAL LEDGER (Friend Detail)

### Header (dark navy #10142A)
- Back chevron left, sparkles icon + ellipsis (three dots) icon right (white)
- Avatar circle (56pt) with initials, name bold white, phone muted below
- Balance: "Owes you" / "You owe" muted + large amount (32pt bold, green/red)
- Two action buttons: "Send reminder" (indigo filled) + "Settle up" (white filled), 24pt rounded

### Content Area (white, rounded top corners)
- "Shared expenses" header with Sort button (indigo, line.3.horizontal.decrease)
- Grouped by date: uppercase date labels (indigo, caption weight, tracked)
- Expense rows: category icon circle (40pt, colored tint), bold description, subtitle "Payer paid ₹X · split N ways"
  - Right side: "owes you" / "you owe" caption + amount (green/red bold)
  - Icon colors: food=orange fork.knife, transport=indigo car.fill, shopping=pink bag
- Settlement rows: green arrow.up circle, "[Name] paid you back", "UPI · settled partly"
  - Right side: "received" caption + "– ₹X" amount (muted)
- Net balance row at bottom: bold "Net balance" + colored amount, separated by divider

## Screen: 03 · TRIP SHEET · MULTI-CURRENCY

### Header (dark navy #10142A)
- Back chevron left, download + sparkles + ellipsis icons right (white)
- Eyebrow: "TRIP · 22–29 AUG" (white 50%, uppercase, tracked)
- Trip name large bold white (28pt)
- Members: "You · Rahul · Ankit · Priya" (white 50%, caption)
- Financial summary row (3 columns):
  - Total spend: label muted + amount white bold
  - Your share: label muted + amount white bold
  - You are owed: label muted + amount green bold
- Multi-currency note (green 80%): "Includes $120 converted at ₹83.40 · 29 Aug rate"
- Two action buttons: "Remind all" (indigo filled) + "Export" (white filled), 24pt rounded

### Content Area (white, rounded top corners)
- SPEND BY CATEGORY section (indigo label):
  - Stacked horizontal bar chart (10pt height, rounded segments, 2px gaps)
  - Color-coded: Stay=green, Food=indigo, Travel=teal, Other=gray
  - Labels below: "Stay 36%  Food 28%  Travel 21%  Other 15%"
- "Expenses" header with Filter button (indigo)
- Expense rows: category icon circle (44pt, colored tint), bold description
  - Subtitle: "date · payer paid ₹X · ÷N"
  - Right side: "owed to you" / "you owe" caption + ₹ amount (green/red bold)
  - Icons: house.fill (stay), fork.knife (food), car.fill (transport)

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

## Screen: 17/18 · SETTINGS (FREE / AD-FREE USER)

### Header (dark navy #10142A)
- Back chevron left, "Account" centered title (white)
- Avatar (56pt) with dashed indigo border circle (68pt), initial letter, QR badge (bottom-left, indigo circle)
- Name bold white, email muted below
- Edit (pencil) icon on right side

### Upgrade Banner (indigo gradient, rounded 16pt)
- FREE: "Get SplitEZ Ad Free", "No ads · priority support · exports", orange "₹99/mo" capsule
- AD-FREE: green checkmark, "SplitEZ Ad Free", "Renews on 15 Oct 2026", translucent "Manage" capsule

### Content Area (white, rounded top corners)
- PREFERENCES section (muted uppercase):
  - Notifications → NotificationSettingsView
  - Security → SecuritySettingsView
  - Appearance → AppearanceSettingsView
  - Currency & language: value "INR · EN" + chevron
- HELP & SUPPORT section (muted uppercase):
  - Contact us: envelope icon + chevron
  - Rate SplitEZ: chevron
- "Log out" red outlined full-width button (24pt rounded)
- Footer: Adrevo logo + "An Adrevo Product" + "© 2026 SplitEZ · 1.0.0"

## Screen: 19 · NOTIFICATIONS

### Header: dark nav bar with "Notifications" centered title
### Content (white, rounded top corners):
- Push notifications: subtitle "Reminders, settlements & activity", indigo toggle
- Email notifications: subtitle "Weekly summary & receipts", indigo toggle
- NOTIFY ME ABOUT section (muted uppercase):
  - New expenses added: toggle ON
  - Payment received: toggle ON
  - Friend requests: toggle ON
  - Reminders sent to you: toggle ON
  - Group updates: toggle OFF
  - Promotional offers: toggle OFF

## Screen: 20 · SECURITY

### Header: dark nav bar with "Security" centered title
### Content (white, rounded top corners):
- Change password: lock icon, "Last changed 3 months ago" subtitle, chevron
- Biometric login: shield icon, "Face ID / fingerprint" subtitle, indigo toggle
- App lock: rectangle icon, "Require PIN on every open" subtitle, toggle OFF
- SESSIONS section (muted uppercase):
  - Current device: iPhone icon, "iPhone 15 Pro", "Active now · this device" green, green dot
  - Other session: desktop icon, "Chrome · Windows", "Last active 2 days ago", red "Revoke" text
  - "Log out all other devices" red outlined button
- ACCOUNT section (muted uppercase):
  - Delete account: trash icon, green text (destructive), chevron

## Screen: 11 · PROFILE & PREFERENCES (Legacy)

### Header (dark navy #10142A)
- Back chevron left, "Edit" text link right (white)
- Avatar circle (72pt) with camera badge (bottom-left, dark circle with white camera icon)
- Name bold white, email · phone muted below
- "Add profile photo" link in indigo

### Upgrade Banner
- Outlined rounded rect (subtle border), NOT filled
- "SplitEZ Plus · ad-free" semibold, "7 days free, then ₹99/month" caption
- "Start trial" dark navy capsule button on right

### Content (white, rounded top corners)
- PREFERENCES section label in indigo
  - Dark mode: moon icon, label + "Follow system · On · Off" subtitle, toggle switch (indigo tint)
  - Default currency: ? icon, label, "INR ₹" value in indigo + chevron
  - Notifications: bell icon, label, chevron
  - Language: globe icon, label, "English" value in indigo + chevron
  - Dividers indented past icons (56pt leading)
- ACCOUNT section label in indigo
  - Payment methods · UPI: label, chevron
  - Export all data: label, chevron
- "Log out" text in red (not a button, just text aligned left)
- Footer: "SplitEZ 2.4.0 · Made in India" caption centered

## Screen: 12 · GROUP MANAGER · DUPLICATE & ARCHIVE

### Header (gradient: dark navy → indigo → teal, left to right)
- Back chevron left, "Change banner" capsule button right (camera icon + text, white on translucent)
- "GROUP MANAGER" eyebrow label (white 70%, uppercase, tracked)
- Group name large bold white (e.g. "Flat 402")
- "3 members · created 12 Jan 2026" caption (white 60%)
- Two action buttons: "Invite member" (indigo filled) + "Share sheet" (white filled)

### Content (white, rounded top corners)
- Members row: overlapping avatar circles (3 shown), "3 members" + "You are the owner", chevron
- GROUP SETTINGS section (tertiary uppercase label):
  - Categories: value "6 in use" + chevron
  - Default split: value "Evenly" in indigo + chevron
  - Group buy: label + "Curated rates for this group" subtitle, "4 offers" green pill
  - Simplify debts: label + toggle (indigo tint)
- MANAGE section (tertiary uppercase label):
  - Duplicate group: doc.on.doc icon, "Copies members, categories, split rules" subtitle
  - Archive group: archivebox icon, "Hidden from Home, ledger kept" subtitle
  - Delete group: trash icon, red text

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
