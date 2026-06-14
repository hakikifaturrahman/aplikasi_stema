# DOKUMENTASI UI/UX & USER FLOW DIAGRAM

## A. Wireframe dan Layout Details

### A.1 Login Screen - Detailed Wireframe

```
┌─────────────────────────────────┐
│                                 │  Height: Full screen
│         SAFE AREA TOP           │  Padding: 16dp
├─────────────────────────────────┤
│                                 │
│          🏟️ LOGO               │  Size: 80x80dp
│   (Sistem Estimasi Stamina)     │  Color: #FFF000
│   STEMA v1.0.0                  │  Font: 20sp Bold
│                                 │  Margin-Top: 48dp
│      Real Madrid Football       │  Font: 14sp Regular
│                                 │
├─────────────────────────────────┤  Margin-Top: 64dp
│                                 │
│   📧 EMAIL ADDRESS              │  Label: 12sp
│   ┌─────────────────────────────┐  Height: 48dp
│   │ arbeloa@realfootball.com    │  Padding: 12dp
│   └─────────────────────────────┘  Border-Radius: 4dp
│                                 │  Background: #3D3A34
│                                 │  Margin-Bottom: 16dp
│
│   🔒 PASSWORD                   │  Label: 12sp
│   ┌─────────────────────────────┐  Height: 48dp
│   │ ••••••••••••••••••••        │  Padding: 12dp
│   │                        👁   │  Border-Radius: 4dp
│   └─────────────────────────────┘  Background: #3D3A34
│                                 │  Margin-Bottom: 24dp
│
│   ┌─────────────────────────────┐  
│   │    🔓 LOGIN                 │  Height: 52dp
│   │                             │  Font: 18sp Bold
│   │                             │  Background: #FFF000
│   └─────────────────────────────┘  Text Color: #000000
│                                 │  Border-Radius: 4dp
│                                 │  Margin-Bottom: 24dp
│
│   Belum punya akun? [DAFTAR]    │  Color: #FFF000
│   [Lupa Password?]              │  Font: 12sp
│                                 │  Margin-Bottom: 48dp
├─────────────────────────────────┤
│ [Privacy Policy] • [Terms Cond] │  Height: 32dp
│      Font: 10sp                 │  Margin: 16dp bottom
│ SAFE AREA BOTTOM                │
└─────────────────────────────────┘

RESPONSIVE RULES:
- Width: 100% screen width
- Max-width: 600dp (tablet mode)
- Portrait: Full height
- Landscape: Scroll if needed
```

---

### A.2 Dashboard Screen - Detailed Layout

```
┌─────────────────────────────────────────┐
│ ☰ MENU              [⚙] [🔔] [👤]      │  AppBar Height: 56dp
├─────────────────────────────────────────┤
│                                         │
│   STEMA Dashboard                       │  Title: 24sp Bold
│   Real Madrid Football                  │  Subtitle: 14sp
│                                         │  Padding: 16dp
├─────────────────────────────────────────┤
│                                         │  
│  ┌─────────────────────────────────┐   │  Card Height: 180dp
│  │  LIVE MATCH STATUS              │   │  Padding: 16dp
│  │                                 │   │  Margin: 16dp
│  │  Real Madrid vs Man. City       │   │
│  │  🏆 La Liga | 15 Dec 2024       │   │
│  │                                 │   │
│  │  Score: 2 - 1 (Live)            │   │
│  │  Time: 65' | Possession: 58%    │   │
│  │  Status: ▓▓▓▓▓▓░░░░░ 65%        │   │
│  │                                 │   │
│  │ [👁 LIHAT] [🎮 CONTROL]        │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│  QUICK ACCESS MENU                      │  Padding: 16dp
│                                         │
│  ┌──────────────┬──────────────┐       │
│  │              │              │       │  Grid 2 columns
│  │  👥 SKUAD    │  📊 MONITOR  │       │  Height per card: 120dp
│  │  MANAGEMENT  │  STAMINA     │       │  Padding: 8dp gap
│  │              │              │       │
│  └──────────────┴──────────────┘       │
│                                         │
│  ┌──────────────┬──────────────┐       │
│  │              │              │       │
│  │  ⚙️ RULE     │  📈 STAT     │       │
│  │  ENGINE      │  PERFORMA    │       │
│  │              │              │       │
│  └──────────────┴──────────────┘       │
│                                         │
│  ┌──────────────┬──────────────┐       │
│  │              │              │       │
│  │  🎮 SIMULASI │  📋 LAPORAN  │       │
│  │  PERTANDINGAN│  RIWAYAT     │       │
│  │              │              │       │
│  └──────────────┴──────────────┘       │
│                                         │
├─────────────────────────────────────────┤
│  STATISTIK RINGKAS                      │  Padding: 16dp
│                                         │
│  Pemain Aktif: 11/23 | Rata² Stamina: 72% │
│  ▓▓▓▓▓▓▓░░ 70%                          │
│                                         │
│  ⚠️ 2 pemain status cedera              │  Background: #3D3A34
│                                         │  Border-Radius: 8dp
│                                         │  Padding: 12dp
│                                         │
└─────────────────────────────────────────┘

CARD STYLING:
- Background: #2A2824
- Border: 1px #4A4740
- Border-Radius: 8dp
- Shadow: 0 2dp 8dp rgba(0,0,0,0.3)
- Elevation: 4
```

---

### A.3 Monitoring Stamina Screen - Detailed Layout

```
┌──────────────────────────────────┐
│ ← MONITORING STAMINA    [👤]     │  AppBar Height: 56dp
├──────────────────────────────────┤
│                                  │  Scrollable Content
│  ┌────────────────────────────┐  │  Padding: 16dp
│  │  ╭─────────────────────╮   │  │
│  │  │  KYLIAN MBAPPE      │   │  │  Player Profile Card
│  │  │  [Photo Circle]     │   │  │  Height: 160dp
│  │  │  FW • No. 9 • Main  │   │  │  Padding: 16dp
│  │  │  Intensitas: [Med ▼]│   │  │
│  │  ╰─────────────────────╯   │  │
│  └────────────────────────────┘  │
│                                  │
├──────────────────────────────────┤
│  KONDISI FISIK TERKINI           │  Section Header: 14sp Bold
│                                  │  Margin-Top: 24dp
│  Stamina Saat Ini: 78%           │  Label: 12sp
│  ████████░░ 78%                  │  ProgressBar: 100% width
│  Speed: 85/100    Dribbling: 90  │  Secondary info: 11sp
│                                  │
│  Rating Performa: 8.2 / 10       │  Label: 12sp
│  ████████░░ 82%                  │  ProgressBar: 100% width
│  Passes: 98 | Shots: 5           │  Secondary info: 11sp
│                                  │
├──────────────────────────────────┤
│  TREND STAMINA (GRAFIK)          │  Section Height: 280dp
│                                  │  Using fl_chart LineChart
│  100%├───────────────────────    │
│      │    ╭─────────────         │
│   75%│   ╱ ╲                     │
│      │  ╱   ╲    ╱───            │
│   50%│ ╱     ╲  ╱                │
│      │╱       ╲╱                 │
│   25%├────────────────────       │
│      0' 15' 30' 45' 60' 75' 90'  │
│                                  │
│  📊 Tren: Stabil hingga menit 60 │
│     Turun signifikan saat 60-75' │
│                                  │
├──────────────────────────────────┤
│  INPUT MANUAL STAMINA            │  Section Margin-Top: 24dp
│                                  │
│  Stamina Awal: [85] %            │  Input Height: 48dp
│  Stamina Akhir: [60] %           │  Width: 100%
│  Jarak Lari: [8.5] km            │  Margin-Bottom: 12dp
│                                  │
│  ┌────────────────────────────┐  │
│  │ 💾 SIMPAN DATA             │  │  Button Height: 52dp
│  └────────────────────────────┘  │  Margin-Bottom: 32dp
│                                  │
└──────────────────────────────────┘

GRAPH STYLING:
- Line width: 2dp
- Dot size: 4dp (touch sensitive: 12dp radius)
- Background: Transparent
- Grid: 1px #4A4740 on 15-minute intervals
```

---

## B. User Flow Diagrams

### B.1 Main Authentication Flow

```
                    ┌─────────────┐
                    │   START     │
                    └──────┬──────┘
                           │
                    ┌──────▼─────────┐
                    │  Open App      │
                    └──────┬─────────┘
                           │
                    ┌──────▼──────────────────┐
                    │  Has Session Token?     │
                    └──────┬──────────┬───────┘
                           │          │
                        YES│          │NO
                           │          │
                    ┌──────▼┐    ┌────▼──────────┐
                    │Show   │    │Show Login     │
                    │Dash   │    │Screen         │
                    │board  │    └────┬──────┬───┘
                    │       │         │      │
                    │       │    [LOGIN]  [REGISTER]
                    │       │         │      │
                    │       │    ┌────▼┐   ┌▼─────────────┐
                    │       │    │Verify   │Show Register │
                    │       │    │Pass     │Form          │
                    │       │    │word     └──┬──────┬────┘
                    │       │    │   │         │      │
                    │       │    │   │    [INPUT]  [CANCEL]
                    │       │    │   │      │         │
                    │       │    │   │   ┌──▼───┐    │
                    │       │    │   │   │Create│────┤
                    │       │    │   │   │Account   │
                    │       │    │   │   └─┬────┘    │
                    │       │    │   │     │         │
                    │       │    │   └─────┴─────────┘
                    │       │    │
           ┌────────▼───────▼────▼┐
           │   SUCCESS?           │
           └────┬──────────────┬──┘
                │              │
             YES│              │NO
                │              │
           ┌────▼──┐      ┌────▼──────┐
           │Dashboard    │Show Error  │
           │Screen       │Alert       │
           │(Home)       └──────┬─────┘
           │                   │
           │                ┌──▼──┐
           │                │RETRY│
           │                └──┬──┘
           │                   │
           │              ┌────▼─────────┐
           │              │Back to Login  │
           │              │              │
           │         ┌────▼──────────────┘
           │         │
           └────┬────┘
                │
           ┌────▼──────┐
           │   EXIT     │
           └────────────┘
```

---

### B.2 Match Monitoring Flow

```
┌─────────────────────┐
│   Dashboard         │
│  [Simulasi Match]   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────┐
│  Pertandingan Setup Screen       │
│  - Input tim, formasi, tanggal   │
│  - Select Starting XI (11)       │
│  [MULAI SIMULASI]               │
└──────────┬──────────────────────┘
           │
           ▼
    ┌─────────────────┐
    │ Server Creates  │
    │ Match Session   │
    │ liveData init   │
    └────────┬────────┘
             │
             ▼
┌───────────────────────────────┐
│  Match Live Control Screen     │
│  - Real-time Score Board       │
│  - Minute Counter              │
│  - Stamina Chart               │
│  - Player Substitution Menu    │
│                                │
│  Actions:                      │
│  [⚽ SCORE] [👥 SUBST]         │
│  [⏸ PAUSE]  [🏁 FINISH]        │
└────┬──────────────┬────────────┘
     │              │
     │              └─────────────────────┐
     │                                    │
  NO │ Match End?                    YES  │
     │                                    │
     │ ┌──────────────┐             ┌─────▼────────┐
     │ │ Continue     │             │ Finish Match │
     │ │ Broadcasting │             │ Event        │
     │ └──────────────┘             └─────┬────────┘
     │       │                            │
     └───┬───┘                            │
         │                                │
         │                                ▼
         │                    ┌─────────────────────────┐
         │                    │ Generate Match Report   │
         │                    │ - Calculate stats       │
         │                    │ - Rate performances     │
         │                    │ - Save to riwayatMatches│
         │                    └────────┬────────────────┘
         │                            │
         │                            ▼
         │                    ┌──────────────────────────┐
         │                    │ Show Match Summary       │
         │                    │ - Score, Stats           │
         │                    │ - Top Performers         │
         │                    │ - Recommendations        │
         │                    │ [LAPORAN DETAIL]         │
         │                    └────────┬─────────────────┘
         │                            │
         └────────┬───────────────────┘
                  │
                  ▼
         ┌──────────────────┐
         │ Back to Dashboard│
         └──────────────────┘
```

---

### B.3 Rule Engine Trigger Flow

```
                    ┌──────────────────┐
                    │ Match Running    │
                    │ (liveData active)│
                    └────────┬─────────┘
                             │
                             ▼
                 ┌─────────────────────────┐
                 │ Monitor Player Data     │
                 │ - Stamina              │
                 │ - Performance Rating    │
                 │ - Minute Elapsed       │
                 │ - Match Status         │
                 └────────┬────────────────┘
                          │
                          ▼
            ┌──────────────────────────────┐
            │ For Each Active Rule:         │
            │ Check IF condition            │
            └──────────┬────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌─────────────────┐         ┌──────────────────┐
│ Rule Triggered? │         │ Rule Not Triggered│
└────┬────────────┘         │ Continue Monitoring
     │                       └──────────────────┘
    YES
     │
     ▼
┌───────────────────────────────┐
│ Execute THEN Action:          │
│ 1. Generate Recommendation    │
│ 2. Send Alert to UI           │
│ 3. Log Trigger Event          │
│ 4. Update rulesData.triggered │
└────┬────────────────────────┬─┘
     │                        │
     │               ┌────────▼─────────┐
     │               │ Broadcast to All │
     │               │ Clients via      │
     │               │ Socket.IO        │
     │               └──────────────────┘
     │
     ▼
┌──────────────────┐
│ Show Alert/      │
│ Recommendation   │
│ on Client UI     │
└──────────────────┘
     │
     ▼
┌──────────────────────────┐
│ Match Continues?         │
│ [YES] / [ACKNOWLEDGE]    │
└──────────────────────────┘
     │
     ▼
┌──────────────────┐
│ Back to          │
│ Monitoring       │
│ (Next Update)    │
└──────────────────┘
```

---

## C. Component State Diagrams

### C.1 Player Stamina State Machine

```
               ┌────────────────┐
               │  INITIALIZATION│
               │  Stamina: 100% │
               └────────┬───────┘
                        │
                        ▼
               ┌────────────────┐
               │    ACTIVE      │ ◄─────────┐
               │ Stamina: 60-99%│          │
               └────┬───────┬───┘          │
                    │       │             │
         ┌──────────┘       └──────┐      │
         │                         │      │
    INTENSIVE              LIGHT   │      │
    ACTIVITY              ACTIVITY │      │
    (-5-10% per            (-1-2%  │      │
    minute)               per min) │      │
         │                         │      │
         ▼                         ▼      │
    ┌──────────┐          ┌─────────────┐
    │ FATIGUED │ ┌───────→│  RECOVERING │
    │50-59%    │ │        │ Stamina +5% │
    └──────────┘ │        │ (per 2 min) │
         │       │        └─────────────┘
         │       │             ▲
         │       │             │
    CONTINUE   SUBSTITUTE/    REST
    HEAVY      REST           PERIOD
    ACTIVITY   (3+ mins)
    (-8-12%)
         │
         ▼
    ┌──────────┐
    │ CRITICAL │ ◄──────┐
    │<50%      │        │
    │⚠️ALERT   │        │
    └──────────┘        │
         │              │
         │ MUST         │
         │ SUBSTITUTE   │
         │ OR RISK      │
         │ INJURY       │
         │              │
    ┌────▼──────────────┐
    │  SUBSTITUTED      │
    │  Stamina Reset    │
    │  or back to RECO  │
    └──────────────────┘
```

---

## D. Color & Typography Specifications

### D.1 Color Palette

**Primary Colors:**
```
#FFF000 - Bright Yellow (Primary Action)
  └─ Used for: Buttons, Icons, Highlights
  └─ Text: Dark text (#000000) on this background
  └─ Hover: #E8D700 (10% darker)
  └─ Active: #D4B500 (20% darker)

#242217 - Dark Brown (Primary Background)
  └─ Used for: Main app background, Cards
  └─ Contrast ratio: 15.8:1 (WCAG AAA)

#3D3A34 - Medium Brown (Secondary Background)
  └─ Used for: Input fields, Sections
  └─ Slightly lighter than primary

#2A2824 - Darker Brown (Elevated Surfaces)
  └─ Used for: Cards, Containers
```

**Status Colors:**
```
#00C853 - Success Green (Positive status)
  └─ Match Won, Player Fit

#FF6B6B - Alert Red (Negative/Critical)
  └─ Stamina Critical, Injury Risk

#FFA726 - Warning Orange (Caution)
  └─ Stamina Low, Performance Warning

#42A5F5 - Info Blue (Information)
  └─ Updates, Status Messages
```

**Text Colors:**
```
#FFFFFF - Primary Text (on dark background)
  └─ Opacity: 100% for active content

#CCCCCC - Secondary Text
  └─ Opacity: 80% for inactive/helper text

#999999 - Disabled Text
  └─ Opacity: 60% for disabled fields

#888888 - Hint/Placeholder
  └─ Opacity: 50% for input placeholders
```

### D.2 Typography Scale

```
HEADING STYLES:
├─ Heading 1: 28sp, Bold (700), Letter-spacing: 0.5dp
│  └─ Usage: Screen titles, Main headers
│
├─ Heading 2: 24sp, Bold (700), Letter-spacing: 0.2dp
│  └─ Usage: Dashboard title, Section headers
│
├─ Heading 3: 20sp, SemiBold (600), Letter-spacing: 0.1dp
│  └─ Usage: Card titles, Form titles
│
└─ Heading 4: 16sp, SemiBold (600)
   └─ Usage: Sub-section titles

BODY STYLES:
├─ Body Large: 16sp, Regular (400), Line-height: 1.5
│  └─ Usage: Important body text
│
├─ Body Regular: 14sp, Regular (400), Line-height: 1.5
│  └─ Usage: Main content, Descriptions
│
├─ Body Small: 12sp, Regular (400), Line-height: 1.5
│  └─ Usage: Secondary text, Captions
│
└─ Body Tiny: 11sp, Regular (400), Line-height: 1.4
   └─ Usage: Micro text, Timestamps

SPECIAL STYLES:
├─ Button Text: 16sp, SemiBold (600), ALL CAPS
│
├─ Label: 12sp, Medium (500)
│
├─ Mono (Numbers): 14sp, Regular, Font: "Roboto Mono"
│  └─ For statistics, scores, timestamps
│
└─ Accent: 12sp, Bold (700), Color: #FFF000
   └─ For alerts, highlights
```

---

## E. Interaction & Animation Specs

### E.1 Standard Interactions

```
BUTTON INTERACTIONS:
├─ Tap Feedback: 150ms scale animation (1.0 → 0.95)
├─ Release: 200ms spring animation back to 1.0
├─ Ripple Effect: Circular ripple from tap point
├─ Disabled State: 50% opacity, no interaction

TAB TRANSITIONS:
├─ Switch animation: 300ms fade + slide
├─ Previous tab slides out left
├─ New tab slides in from right
├─ Opacity fade: 0 → 1

LIST ITEM ANIMATIONS:
├─ Initial load: Staggered fade-in (100ms between items)
├─ Add item: Scale + fade in (200ms)
├─ Delete item: Slide out + fade (200ms)
├─ Reorder: Smooth transition (300ms)

CHART ANIMATIONS:
├─ Initial draw: Line drawn from left to right (800ms)
├─ Data update: Smooth curve transition (500ms)
├─ Tap point: Scale + glow effect (200ms)
```

### E.2 Transition Curves

```
CURVE DEFINITIONS:
├─ Quick: cubic-bezier(0.4, 0.0, 0.2, 1.0) - Fast start
├─ Smooth: cubic-bezier(0.25, 0.46, 0.45, 0.94) - Natural ease
├─ Bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55) - Bouncy spring
├─ Linear: linear - Constant speed
└─ Decelerate: cubic-bezier(0.0, 0.0, 0.2, 1.0) - Slow finish

USAGE:
├─ Buttons: Quick (150ms)
├─ Screen transitions: Smooth (300ms)
├─ Loading indicators: Linear (infinite)
└─ Chart animations: Smooth (800ms)
```

---

## F. Accessibility Guidelines

### F.1 WCAG 2.1 Compliance

```
CONTRAST REQUIREMENTS:
├─ Normal text: 4.5:1 minimum (AA standard)
├─ Large text (18sp+): 3:1 minimum (AA standard)
├─ UI components: 3:1 minimum
└─ Current design: Meets AAA (7:1+) on all text

INTERACTIVE ELEMENTS:
├─ Minimum touch target: 48x48dp
├─ Button minimum height: 48dp
├─ Input field minimum height: 48dp
├─ Spacing between targets: 16dp minimum

SCREEN READER SUPPORT:
├─ All icons have contentDescription
├─ Form fields have semantic labels
├─ Dynamic content updates announced
├─ Focus order: Logical, left-to-right, top-to-bottom

COLOR BLINDNESS:
├─ Don't rely on color alone for information
├─ Use icons + labels + colors
├─ Status indicated by: Icon + Color + Text
└─ Test with: Protanopia, Deuteranopia, Tritanopia filters
```

---

**Dokumentasi UI/UX & User Flow - SELESAI**

*File ini melengkapi BAB 3 Perancangan Fisik dengan detail wireframe, user flows, dan interaction specifications.*
