# Paint Roller - Project Context for Claude

## What is this?
An idle/clicker mobile game built with **Flutter** (Flame engine) + **Node.js** backend (Fastify + PostgreSQL). Players paint walls with a roller, earn cash, upgrade, and progress through infinite house tiers.

**Live:** https://liveserver-82b8.web.app
**Backend:** https://live-server-4c3n.onrender.com

## Project Structure
```
LiveServer/
  flutter_app/                  Flutter frontend
    lib/
      main.dart                 App entry, providers, username setup
      config/
        game_config.dart        All tunable constants (roller, economy, visuals)
      theme/
        app_colors.dart         Centralized color palette for the entire app
      game/
        paint_roller_game.dart  Flame game: tap-to-paint, roller + stripe logic
        game_state.dart         Round state: strokes, coverage interval-merge
        wall_pattern.dart       Procedural wall pattern generation
        components/
          roller_component.dart        Oscillating roller sprite, paint animation
          paint_stripe_component.dart  Bottom-to-top paint fill animation
          wall_component.dart          Wall bg with gradient + dirt spots
          wall_border_component.dart   Black border frame around wall
          wall_pattern_overlay.dart    Decorative pattern shapes on wall
          background_component.dart    Room background image rendering
          room_frame_component.dart    Crown molding + baseboard
          floating_coverage_text.dart  "+87%" text that floats up after painting
          paint_splat_particle.dart    Paint splat burst on each stroke
          perfect_shimmer_component.dart  Shimmer sweep at 90%+ coverage
      models/
        house.dart              7 house types (cycle infinitely), wall scale curve
        upgrade.dart            6 upgrade definitions, cost formulas
        player_progress.dart    Player data model, derived stats
        marketplace_item.dart   Item rarity/types (10 items, 5 rarities)
      services/
        game_service.dart       ChangeNotifier: progress, upgrades, idle income
        user_service.dart       Device ID, username, friend code, backend API
        audio_service.dart      BGM, SFX, haptic toggle (SharedPreferences)
        marketplace_service.dart  Inventory, listings, buy/sell/cancel
        event_service.dart      Live events, drop attempts, auto-refresh
        leaderboard_service.dart  Weekly leaderboard join/submit/fetch
        guild_service.dart      Guild create/join/leave, guild leaderboard
      screens/
        home_screen.dart        Gameplay: Flame game + HUD + payout animation
        upgrades_screen.dart    House level + roller level upgrade cards
        marketplace_screen.dart Shop (skins), auction, inventory, sell tabs
        social_screen.dart      Leaderboard, events, guilds, minigames hub
        event_screen.dart       Live events, daily lottery, leaderboard
        profile_screen.dart     Stats, inventory, badges, settings tabs
        minigame_speed_paint.dart   Tap-to-fill walls in 60s
        minigame_bullseye.dart      Stop-the-bar precision game (5 rounds)
        minigame_color_match.dart   Simon-says color memory game
      shells/
        survival_shell.dart     Bottom nav (5 tabs), idle income dialog, lifecycle
    assets/images/rollers/      Roller skin PNGs (600x600)
    web/                        Flutter web build target
    firebase.json               Firebase Hosting config (serves build/web)
    .firebaserc                 Firebase project: liveserver-82b8
  index.js                      Fastify backend (REST + WebSocket)
  package.json                  Node deps: fastify, pg, dotenv
```

## Core Game Mechanics

### Paint Loop
1. Roller oscillates left-right (sine wave, 2.2 rad/s * speed multiplier)
2. Player taps to paint -> roller sweeps up (0.3s anim), stripe grows bottom-to-top
3. Taps blocked while roller animation plays (`roller.isPainting`)
4. Stripe width = roller sprite contact line (1/3 of sprite at current draw size)
5. Coverage calculated via interval-merge on [0,1] wall range
6. Round ends when strokes exhausted -> payout = `baseCash * coverage^1.5 * coverageBonus * cashMultiplier`
7. Streak bonus added on top: `totalPayout = basePayout + (basePayout * streak * 0.05)`

### Coverage Bonuses
- **Perfect** (100%): 3.0x multiplier
- **Great** (95%+): 2.0x multiplier
- **Nice** (90%+): 1.5x multiplier
- Below 90%: 1.0x (no bonus)

### Streak System
- Max level: 10, +5% bonus per level
- Great/Perfect: advance streak (up to 10)
- Nice: advance streak (capped at 7)
- No bonus: reset to 0

### Roller Sprite Alignment
- 600x600 PNG, actual contact line spans x=200..400 (middle 1/3)
- `kRollerContactFraction = 1/3`
- Sprite size = `(rollerWidthFraction / contactFraction) * wallWidth`
- Paint stripe width and position derived from this, centered on `roller.pixelX`

### Progression (Infinite, No Resets)
- **Upgrades persist forever**, never reset
- **House level** and **roller level** are separate upgrade tracks
  - Max level difference: 10 (gated so they stay in sync)
- **7 house types** cycle infinitely with Roman numerals:
  - Dirt House (1.0x) -> Shack (1.15x) -> Cabin (1.3x) -> Cottage (1.5x) -> Townhouse (1.7x) -> Villa (1.95x) -> Mansion (2.2x) -> Dirt House II -> ...
- **Wall scale** = `1.05^(houseLevel - 1)` (5% compounding per level)
- **Base cash** = `10 * (1 + 0.3 * (houseLevel - 1))` scales linearly
- **Visual house selection**: each round pulls from 7 most-recent tiers with weighted probabilities `[18, 17, 16, 14, 13, 12, 10]`
- Roller width divided by wallScale -> bigger houses = smaller roller = need more upgrades

### Upgrades
| Type | Base Cost | Multiplier | Max | Effect |
|------|-----------|-----------|-----|--------|
| Turbo Speed | 30 | 1.5x | uncapped | +10% cash / level |
| Steady Hand | 100 | 2.0x | uncapped | speed = 1/(1+0.15*level) |
| Auto-Painter | 150 | 2.0x | uncapped | +$2/sec idle / level |
| Extra Stroke | 500 | 3.0x | 3 | +1 stroke / level |
| Broker License | 300 | 2.5x | 3 | -1% marketplace fee |

Note: Wider Roller upgrade exists in code for save migration but is hidden from UI. Roller width is now controlled by the separate roller level system (+1.5% per level).

Cost formula: `baseCost * costMultiplier^currentLevel`

### House & Roller Upgrade Costs
- **House**: `40 * 1.35^level`
- **Roller**: `30 * 1.30^level`

### Currencies
- **Cash ($)**: earned from painting, spent on upgrades and skins
- **Gems**: secondary currency for marketplace trading

### Roller Skins (6 total)
| Skin | Price | Paint Color |
|------|-------|-------------|
| Default | Free | Red (#FF3B30) |
| Pudding | $500 | Orange (#FF9500) |
| Pancake | $2,000 | Purple (#8B5CF6) |
| Bunny | $8,000 | Cyan (#06B6D4) |
| Kitty | $25,000 | Pink (#F472B6) |
| Money | $80,000 | Gold (#FFD700) |

## Key Constants & Formulas
All tunable values live in `config/game_config.dart`. Key ones:
- Base roller width: **0.25** (raw), rendered as **0.15** after scaling
- Base strokes: **6** per wall
- Roller speed: **2.2 rad/s** base oscillation
- Paint animation: **0.3s** total (35% up, 65% down)
- Stripe animation: **0.105s** (matches upswing)
- Idle income cap: **8 hours**
- Coverage reward exponent: **1.5** (continuous, not step thresholds)

## Color System
All UI colors are centralized in `theme/app_colors.dart`. Key semantic groups:
- **Backgrounds**: beige (`E8D5B8`), card cream (`F5E6D0`)
- **Browns**: dark (`6B5038`) for text, mid (`8B7355`), light (`B89E7A`)
- **Accents**: primary orange (`E8734A`), secondary green (`4ADE80`), gold (`F5C842`), gem purple (`DA70D6`)
- **HUD**: dark (`2A2A2A`), border (`111111`)
- **Nav tabs**: trade sky-blue, social coral, paint gold, levelup green, profile purple

Change colors in `app_colors.dart` to re-theme the entire app.

## Deployment
```bash
# Build Flutter web
cd flutter_app && flutter build web --release

# Deploy to Firebase Hosting
cd flutter_app && npx firebase-tools deploy --only hosting

# Backend on Render (auto-deploys from main branch)
# Env vars: PORT, DATABASE_URL
```

## State Management
- **GameService** (ChangeNotifier + Provider): game state, saves to SharedPreferences
- **UserService** (ChangeNotifier + Provider): identity, backend sync
- **AudioService** (ChangeNotifier + Provider): music/SFX/haptic toggles
- **MarketplaceService** (ProxyProvider from UserService): inventory, listings
- **EventService** (ProxyProvider from UserService): live events, drops
- **LeaderboardService** (ProxyProvider from UserService): weekly rankings
- **GuildService** (ChangeNotifier + Provider): guild CRUD
- HomeScreen listens to GameService changes -> `updateRollerSettings()` applies upgrades live

## Backend API (index.js)
### User
- `POST /api/user` - create/update username
- `GET /api/user/:userId` - fetch user

### Progress
- `POST /api/progress/save` - save progress
- `GET /api/progress/:userId` - load progress + idle income

### Inventory
- `GET /api/inventory/:userId` - list player items

### Marketplace
- `GET /api/marketplace/listings` - browse active listings
- `GET /api/marketplace/index-prices` - average prices (last 10 trades)
- `POST /api/marketplace/list` - list item for sale
- `POST /api/marketplace/buy` - purchase item (gem transfer + fee)
- `POST /api/marketplace/cancel` - cancel listing

### Events
- `GET /api/events/active` - active/scheduled events
- `POST /api/events/:eventId/attempt` - attempt event drop

### Leaderboard
- `POST /api/leaderboard/join` - join current ISO week
- `POST /api/leaderboard/submit` - submit round stats (coverage, coins)
- `GET /api/leaderboard/current` - top 100 (3 categories), player stats, 10min cache
- `GET /api/leaderboard/status` - check if joined this week

### WebSocket
- `GET /ws/marketplace` - live marketplace broadcasts (new listings, sales)
