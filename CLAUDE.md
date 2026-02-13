# Paint Roller - Project Context for Claude

## What is this?
An idle/clicker mobile game built with **Flutter** (Flame engine) + **Node.js** backend (Fastify + PostgreSQL). Players paint walls with a roller, earn cash, upgrade, and prestige through infinite house tiers.

**Live:** https://liveserver-82b8.web.app
**Backend:** https://live-server-4c3n.onrender.com

## Project Structure
```
LiveServer/
  flutter_app/                  Flutter frontend
    lib/
      main.dart                 App entry, navigation shell, currency bar
      game/
        paint_roller_game.dart  Flame game: tap-to-paint, roller + stripe logic
        game_state.dart         Round state: strokes, coverage interval-merge
        components/
          roller_component.dart Oscillating roller sprite, paint animation
          paint_stripe_component.dart  Bottom-to-top paint fill animation
          wall_component.dart   Wall bg with random dirt spots
      models/
        house.dart              5 house tiers (cycle infinitely), wall scale curve
        upgrade.dart            6 upgrade definitions, cost formulas
        player_progress.dart    Player data model, derived stats
        marketplace_item.dart   Item rarity/types (10 items, 4 rarities)
      services/
        game_service.dart       ChangeNotifier: progress, upgrades, prestige, idle income
        user_service.dart       Device ID, username, friend code, backend API
      screens/
        home_screen.dart        Gameplay: Flame game + HUD overlay
        upgrades_screen.dart    Upgrade shop + prestige card + progression
        marketplace_screen.dart Mock marketplace UI (backend ready)
        event_screen.dart       Mock event UI (backend ready)
        profile_screen.dart     Stats, username edit, friend code
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
6. Round ends when strokes exhausted -> payout = `baseCash * coverage^1.5 * starMultiplier * cashMultiplier`

### Roller Sprite Alignment
- 600x600 PNG, actual contact line spans x=200..400 (middle 1/3)
- `_rollerContactFraction = 1/3`
- Sprite size = `(rollerWidthFraction / _rollerContactFraction) * wallWidth`
- Paint stripe width and position derived from this, centered on `roller.pixelX`

### Progression (Infinite, No Resets)
- **Upgrades persist forever** across prestige, never reset
- **Prestige** = complete 5 rooms -> earn 1 star, advance to next house tier
- **Wall scale** = `1.0 + 0.04 * prestige^1.6` (exponential growth curve)
  - Prestige 0: 1.0x, Prestige 5: 1.48x, Prestige 10: 2.26x, Prestige 20: 4.83x
- **Base cash** = `10 * (1 + 0.5 * prestige)` scales linearly
- **Houses cycle** through 5 visual tiers with Roman numerals (Apartment II, III...)
- Roller width divided by wallScale -> bigger houses = smaller roller = need more upgrades

### Upgrades
| Type | Base Cost | Multiplier | Max | Effect |
|------|-----------|-----------|-----|--------|
| Wider Roller | 50 | 1.8x | uncapped | +2% roller width / level |
| Turbo Speed | 30 | 1.5x | uncapped | +10% cash / level |
| Steady Hand | 100 | 2.0x | uncapped | speed = 1/(1+0.15*level) |
| Auto-Painter | 150 | 2.0x | uncapped | +$2/sec idle / level |
| Extra Stroke | 500 | 3.0x | 3 | +1 stroke / level |
| Broker License | 300 | 2.5x | 3 | -1% marketplace fee |

Cost formula: `baseCost * costMultiplier^currentLevel`

### Currencies
- **Cash ($)**: earned from painting, spent on upgrades, persists across prestige
- **Stars**: earned 1 per prestige, provide permanent +10% cash multiplier each, used for marketplace

## Key Constants & Formulas
- Base roller width: **0.25** (25% of wall at scale 1.0)
- Base strokes: **6** per wall
- Roller speed: **2.2 rad/s** base oscillation
- Paint animation: **0.3s** total (35% up, 65% down)
- Stripe animation: **0.105s** (matches upswing)
- Idle income cap: **8 hours**
- Coverage reward: `coverage^1.5` (continuous, not step thresholds)

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
- **GameService** (ChangeNotifier + Provider): all game state, saves to SharedPreferences
- **UserService** (ChangeNotifier + Provider): identity, backend sync
- HomeScreen listens to GameService changes -> `updateRollerSettings()` applies upgrades live

## Backend API (index.js)
- `POST /api/user` - create/update username
- `GET /api/user/:userId` - fetch user
- `POST /api/progress/save` - save progress
- `GET /api/progress/:userId` - load progress + idle income
- `GET /api/marketplace/listings` - browse marketplace
- `POST /api/marketplace/list` - list item for sale
- `POST /api/marketplace/buy` - purchase item
- `GET /api/events/active` - active events
- `POST /api/events/:eventId/attempt` - attempt event drop
- `GET /ws/marketplace` - WebSocket for live updates

## Incomplete Features
- **Marketplace**: backend complete, frontend is mock UI only
- **Events**: backend has drop mechanics, frontend is placeholder
- **Roller Skins**: asset loading works, needs actual skin PNGs
- **WebSocket**: marketplace broadcasts coded but not consumed by frontend
