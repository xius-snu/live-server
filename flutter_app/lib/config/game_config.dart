/// Centralized game configuration constants.
/// All tunable magic numbers live here for easy balancing and tweaking.
library;

import 'dart:math';

// ═══════════════════════════════════════════════════════════════════════════
// ROLLER
// ═══════════════════════════════════════════════════════════════════════════

/// Base roller width as fraction of wall (before upgrades/scaling).
const double kRollerBaseWidthFraction = 0.15;

/// Base oscillation speed in rad/s.
const double kRollerBaseSpeed = 2.2;

/// Base strokes per wall (before Extra Stroke upgrades).
const int kRollerBaseStrokes = 6;

/// Roller sprite contact fraction (middle 1/3 of 600px sprite = 200..400).
const double kRollerContactFraction = (400 - 200) / 600; // 1/3

/// Minimum roller draw size in pixels.
const double kRollerMinSize = 70.0;

/// Maximum roller draw size in pixels.
const double kRollerMaxSize = 400.0;

/// Y offset below wall bottom for roller resting position.
const double kRollerYOffset = 2.0;

/// How far above the wall top the roller rises during paint stroke (fraction of roller size).
const double kRollerPaintEndOffsetFraction = 0.35;

// ═══════════════════════════════════════════════════════════════════════════
// ROLLER PAINT ANIMATION
// ═══════════════════════════════════════════════════════════════════════════

/// Total duration of the paint stroke animation in seconds.
const double kPaintAnimDuration = 0.3;

/// Fraction of animation spent on the upswing (0.35 = 35%).
const double kPaintAnimUpswingFraction = 0.35;

/// Fraction of animation spent on the downswing (0.65 = 65%).
double get kPaintAnimDownswingFraction => 1.0 - kPaintAnimUpswingFraction;

// ═══════════════════════════════════════════════════════════════════════════
// PAINT STRIPE
// ═══════════════════════════════════════════════════════════════════════════

/// Duration of the stripe fill animation (matches roller upswing).
const double kStripeFillDuration = 0.105;

/// Duration of the wet-edge glow effect.
const double kStripeWetDuration = 0.3;

/// Minimum rendered height in pixels before stripe is drawn.
const double kStripeMinRenderHeight = 1.0;

/// Wet-edge glow max opacity multiplier.
const double kStripeGlowOpacityMultiplier = 0.35;

/// Wet-edge glow width as fraction of stripe width.
const double kStripeGlowWidthFraction = 0.3;

/// Top shimmer height as fraction of stripe height.
const double kStripeTopShimmerHeightFraction = 0.08;

/// Top shimmer opacity relative to the glow.
const double kStripeTopShimmerOpacityMultiplier = 0.6;

// ═══════════════════════════════════════════════════════════════════════════
// WALL LAYOUT (in PaintRollerGame)
// ═══════════════════════════════════════════════════════════════════════════

/// Reference width for difficulty scaling (pixels).
const double kWallReferenceWidth = 400.0;

/// Wall width clamp factor relative to background wall rect.
const double kWallWidthClampFactor = 0.90;

/// Minimum wall width in pixels.
const double kWallMinWidth = 80.0;

/// Wall height clamp factor relative to background wall rect.
const double kWallHeightClampFactor = 0.88;

/// Minimum wall height in pixels.
const double kWallMinHeight = 80.0;

/// Maximum wall height in pixels.
const double kWallMaxHeight = 2000.0;

/// Wall top offset as fraction of container height.
const double kWallTopOffsetFraction = 0.03;

// ═══════════════════════════════════════════════════════════════════════════
// WALL VISUALS
// ═══════════════════════════════════════════════════════════════════════════

/// Wall border stroke width.
const double kWallBorderStrokeWidth = 4.0;

// ── Dirt blobs ──

/// Base number of dirt blobs (before house tier reduction).
const int kDirtBlobBaseCount = 12;

/// Minimum dirt blobs regardless of tier.
const int kDirtBlobMinCount = 3;

/// Dirt blob reduction per house tier.
const int kDirtBlobReductionPerTier = 2;

/// Dirt blob margin from wall edges.
const double kDirtBlobMargin = 12.0;

/// Minimum dirt blob radius.
const double kDirtBlobMinRadius = 8.0;

/// Maximum additional dirt blob radius (random variance).
const double kDirtBlobRadiusVariance = 18.0;

/// Minimum dirt blob opacity.
const double kDirtBlobMinOpacity = 0.06;

/// Dirt blob opacity random variance.
const double kDirtBlobOpacityVariance = 0.10;

/// Dirt blob blur radius.
const double kDirtBlobBlurRadius = 8.0;

// ── Wall gradient ──

/// Top gradient white overlay opacity.
const double kWallGradientTopOpacity = 0.06;

/// Bottom gradient dark overlay opacity.
const double kWallGradientBottomOpacity = 0.04;

/// Gradient color stops [top, mid, bottom].
const List<double> kWallGradientStops = [0.0, 0.4, 1.0];

// ── Wall light highlight ──

/// Light highlight center alignment.
const double kWallLightCenterX = -0.6;
const double kWallLightCenterY = -0.5;

/// Light highlight radius.
const double kWallLightRadius = 1.3;

/// Light highlight opacity.
const double kWallLightOpacity = 0.08;

// ── Pattern shapes ──

/// Maximum placement retry attempts for pattern shapes.
const int kPatternMaxRetries = 6;

/// Scale shrink factor per retry (15% smaller each attempt).
const double kPatternShrinkFactor = 0.85;

/// Diamond bounding-box factor (sqrt(0.5)).
const double kPatternDiamondBboxFactor = 0.707;

/// Jitter factor for pattern placement (fraction of cell size).
const double kPatternJitterFactor = 0.8;

/// Overlap gap threshold for pattern placement.
const double kPatternOverlapGap = 4.0;

/// Pattern fill opacity (semi-transparent black).
const double kPatternFillOpacity = 0.12;

// ═══════════════════════════════════════════════════════════════════════════
// BACKGROUND IMAGE
// ═══════════════════════════════════════════════════════════════════════════

/// Background image dimensions (homebackground.png).
const double kBgImageWidth = 1080.0;
const double kBgImageHeight = 2340.0;

/// Wall region in the background image (fraction of image height).
const double kBgWallTopFraction = 0.32;
const double kBgWallBottomFraction = 0.72;

/// Wall area left/right margins (fraction of image width).
const double kBgWallLeftFraction = 0.0;
const double kBgWallRightFraction = 1.0;

/// Fallback background color when image fails to load.
const int kBgFallbackColor = 0xFF2A2A4A;

// ═══════════════════════════════════════════════════════════════════════════
// FLOATING COVERAGE TEXT
// ═══════════════════════════════════════════════════════════════════════════

/// Total lifetime of the floating text in seconds.
const double kCoverageTextLifetime = 1.0;

/// Rise speed of the floating text (pixels/second).
const double kCoverageTextRiseSpeed = 60.0;

/// Scale at high combo (5+).
const double kCoverageTextHighComboScale = 1.25;

/// Scale at medium combo (3+).
const double kCoverageTextMedComboScale = 1.12;

/// Gold tint blend factor at high combo (5+).
const double kCoverageTextHighComboTint = 0.7;

/// Orange tint blend factor at medium combo (3+).
const double kCoverageTextMedComboTint = 0.4;

// ── Text animation phases ──

/// Bounce-in phase duration (fraction of lifetime).
const double kCoverageTextBounceInPhase = 0.15;

/// Idle phase end (fraction of lifetime).
const double kCoverageTextIdlePhaseEnd = 0.55;

/// Idle phase oscillation duration (fraction within idle).
const double kCoverageTextIdleOscillation = 0.4;

/// Fade-out duration (fraction of lifetime).
const double kCoverageTextFadeOutDuration = 0.45;

/// Scale-down amount during fade-out.
const double kCoverageTextFadeScaleDown = 0.15;

// ═══════════════════════════════════════════════════════════════════════════
// PAINT SPLAT PARTICLES
// ═══════════════════════════════════════════════════════════════════════════

/// Gravity acceleration (pixels/second^2).
const double kSplatGravity = 500.0;

/// Velocity damping per frame.
const double kSplatVelocityDamping = 0.97;

/// Default burst count.
const int kSplatDefaultCount = 14;

/// High combo (5+) splat count.
const int kSplatHighComboCount = 24;

/// Medium combo (3+) splat count.
const int kSplatMedComboCount = 18;

/// Number of particles that are "blobs" (first N).
const int kSplatBlobThreshold = 3;

/// Splat angle range (radians). Particles go upward in a cone.
const double kSplatAngleStart = -0.15 * pi;
const double kSplatAngleRange = -0.7 * pi;

/// Blob minimum speed.
const double kSplatBlobMinSpeed = 60.0;

/// Blob speed variance.
const double kSplatBlobSpeedVariance = 100.0;

/// Small particle minimum speed.
const double kSplatSmallMinSpeed = 100.0;

/// Small particle speed variance.
const double kSplatSmallSpeedVariance = 250.0;

/// Blob minimum lifetime.
const double kSplatBlobMinLife = 0.4;

/// Blob lifetime variance.
const double kSplatBlobLifeVariance = 0.3;

/// Small particle minimum lifetime.
const double kSplatSmallMinLife = 0.2;

/// Small particle lifetime variance.
const double kSplatSmallLifeVariance = 0.35;

/// Minimum blob radius.
const double kSplatBlobMinRadius = 4.0;

/// Blob radius variance.
const double kSplatBlobRadiusVariance = 4.0;

/// Minimum small particle radius.
const double kSplatSmallMinRadius = 1.5;

/// Small particle radius variance.
const double kSplatSmallRadiusVariance = 3.0;

// ── Splat rendering ──

/// Blob growth factor during lifetime.
const double kSplatBlobGrowth = 0.3;

/// Small particle shrink factor during lifetime.
const double kSplatSmallShrink = 0.5;

/// Main paint opacity for splat particles.
const double kSplatMainOpacity = 0.85;

/// Highlight opacity for splat particles.
const double kSplatHighlightOpacity = 0.3;

/// Highlight minimum radius threshold.
const double kSplatHighlightMinRadius = 3.0;

/// Highlight X offset (fraction of radius, negative = left).
const double kSplatHighlightOffsetX = -0.25;

/// Highlight Y offset (fraction of radius, negative = up).
const double kSplatHighlightOffsetY = -0.25;

/// Highlight radius factor (fraction of particle radius).
const double kSplatHighlightRadiusFactor = 0.35;

/// Splat spread width multiplier (relative to contact width).
const double kSplatSpreadWidthFactor = 0.8;

/// Splat origin Y position (fraction down the wall height).
const double kSplatOriginYFraction = 0.82;

// ═══════════════════════════════════════════════════════════════════════════
// PERFECT SHIMMER
// ═══════════════════════════════════════════════════════════════════════════

/// Shimmer sweep duration in seconds.
const double kShimmerDuration = 0.65;

/// Shimmer band width as fraction of diagonal.
const double kShimmerBandWidth = 0.3;

/// Shimmer rotation angle (~45 degrees).
const double kShimmerAngle = 0.785;

/// Shimmer fade-in phase (fraction of duration).
const double kShimmerFadeInPhase = 0.15;

/// Shimmer fade-out start (fraction of duration).
const double kShimmerFadeOutStart = 0.7;

/// Shimmer fade-out duration (fraction of remaining).
const double kShimmerFadeOutDuration = 0.3;

/// Base shimmer opacity.
const double kShimmerBaseOpacity = 0.4;

/// Shimmer gradient stops.
const List<double> kShimmerGradientStops = [0.0, 0.25, 0.5, 0.75, 1.0];

// ═══════════════════════════════════════════════════════════════════════════
// RENDER PRIORITIES (z-order layers)
// ═══════════════════════════════════════════════════════════════════════════

/// Pattern overlay priority (above paint stripes, below roller).
const int kPriorityPatternOverlay = 15;

/// Roller priority (above paint stripes).
const int kPriorityRoller = 20;

/// Splat particle priority (above stripes, below border).
const int kPrioritySplatParticle = 25;

/// Perfect shimmer priority (above stripes, below border).
const int kPriorityShimmer = 28;

/// Wall border priority (above roller and paint stripes).
const int kPriorityWallBorder = 30;

/// Coverage text priority (above everything).
const int kPriorityCoverageText = 35;

// ═══════════════════════════════════════════════════════════════════════════
// GAME HUD / TAP AREA
// ═══════════════════════════════════════════════════════════════════════════

/// Coverage text X offset from roller center.
const double kCoverageTextXOffset = 70.0;

/// Coverage text Y position (fraction down the wall).
const double kCoverageTextYFraction = 0.25;

/// Minimum coverage percent to trigger shimmer effect.
const int kShimmerCoverageThreshold = 90;

// ═══════════════════════════════════════════════════════════════════════════
// ECONOMY: COVERAGE BONUSES
// ═══════════════════════════════════════════════════════════════════════════

/// Perfect coverage (100%) bonus multiplier.
const double kCoverageBonusPerfect = 3.0;

/// Great coverage (95%+) bonus multiplier.
const double kCoverageBonusGreat = 2.0;

/// Nice coverage (90%+) bonus multiplier.
const double kCoverageBonusNice = 1.5;

/// Coverage reward exponent (coverage^N in payout formula).
const double kCoverageRewardExponent = 1.5;

// ═══════════════════════════════════════════════════════════════════════════
// ECONOMY: STREAK
// ═══════════════════════════════════════════════════════════════════════════

/// Streak bonus multiplier per level (5% per streak).
const double kStreakBonusPerLevel = 0.05;

/// Maximum streak level.
const int kStreakMaxLevel = 10;

/// Streak cap for NICE bonus.
const int kStreakNiceCap = 7;

// ═══════════════════════════════════════════════════════════════════════════
// ECONOMY: IDLE INCOME
// ═══════════════════════════════════════════════════════════════════════════

/// Maximum idle income accumulation in hours.
const int kIdleIncomeCapHours = 8;

/// Maximum idle income accumulation in seconds.
int get kIdleIncomeCapSeconds => kIdleIncomeCapHours * 3600;

// ═══════════════════════════════════════════════════════════════════════════
// ECONOMY: HOUSE PROGRESSION
// ═══════════════════════════════════════════════════════════════════════════

/// Wall scale growth multiplier per house level (compounding).
const double kHouseWallScaleGrowth = 1.05;

/// Base cash per wall at house level 1.
const double kHouseBaseCash = 10.0;

/// Cash growth per house level.
const double kHouseCashGrowthPerLevel = 0.3;

/// House upgrade base cost.
const double kHouseUpgradeBaseCost = 40.0;

/// House upgrade cost multiplier per level.
const double kHouseUpgradeCostMultiplier = 1.35;

/// Roller upgrade base cost.
const double kRollerUpgradeBaseCost = 30.0;

/// Roller upgrade cost multiplier per level.
const double kRollerUpgradeCostMultiplier = 1.30;

/// Maximum level difference between house and roller.
const int kMaxHouseRollerLevelDiff = 10;

/// Wall scale per cycle level within a house type.
const double kHouseWallScalePerCycle = 0.12;

// ═══════════════════════════════════════════════════════════════════════════
// ECONOMY: ROLLER WIDTH
// ═══════════════════════════════════════════════════════════════════════════

/// Base roller raw width fraction.
const double kRollerRawBaseWidth = 0.25;

/// Roller width increase per roller level.
const double kRollerWidthPerLevel = 0.015;

/// Minimum roller width fraction.
const double kRollerMinWidthFraction = 0.05;

/// Maximum roller width fraction.
const double kRollerMaxWidthFraction = 0.95;

// ═══════════════════════════════════════════════════════════════════════════
// ECONOMY: ABSOLUTE SIZE DISPLAY
// ═══════════════════════════════════════════════════════════════════════════

/// Base wall width in meters at scale 1.0.
const double kBaseWallWidthMeters = 3.2;

/// Base wall height in meters at scale 1.0.
const double kBaseWallHeightMeters = 3.0;

// ═══════════════════════════════════════════════════════════════════════════
// ECONOMY: TIER WEIGHTS (for random house selection)
// ═══════════════════════════════════════════════════════════════════════════

/// Weights for up to 7 most-recent tiers.
/// Index 0 = most recently unlocked (highest prob), index 6 = 7th back.
const List<int> kTierWeights = [18, 17, 16, 14, 13, 12, 10];

// ═══════════════════════════════════════════════════════════════════════════
// UPGRADES: EFFECT PER LEVEL
// ═══════════════════════════════════════════════════════════════════════════

/// Wider Roller: width increase per level (%).
const int kUpgradeWiderRollerPerLevel = 2;

/// Turbo Speed: cash increase per level (%).
const int kUpgradeTurboSpeedPerLevel = 10;

/// Steady Hand: speed reduction per level (%).
const int kUpgradeSteadyHandPerLevel = 7;

/// Steady Hand: max speed reduction (%).
const int kUpgradeSteadyHandMaxReduction = 70;

/// Steady Hand: speed multiplier formula factor.
const double kUpgradeSteadyHandFactor = 0.15;

/// Auto-Painter: income per level per second.
const double kUpgradeAutoPainterPerLevel = 2.0;

/// Broker License: base fee percent.
const int kUpgradeBrokerBaseFee = 5;

/// Broker License: minimum fee percent.
const double kUpgradeBrokerMinFee = 2.0;

/// Broker License: maximum fee percent.
const double kUpgradeBrokerMaxFee = 5.0;

/// Turbo Speed: cash multiplier per level.
const double kUpgradeTurboSpeedMultiplier = 0.10;

// ═══════════════════════════════════════════════════════════════════════════
// SKIN PRICES
// ═══════════════════════════════════════════════════════════════════════════

const double kSkinPriceDefault = 100;
const double kSkinPricePudding = 300;
const double kSkinPricePancake = 800;
const double kSkinPriceBunny = 2000;
const double kSkinPriceKitty = 5000;
const double kSkinPriceMoney = 15000;

// ═══════════════════════════════════════════════════════════════════════════
// PAINT COLOR TIERS
// ═══════════════════════════════════════════════════════════════════════════

enum ColorTier { common, uncommon, rare, epic, legendary, mythic }

class PaintColorDef {
  final String id;
  final String name;
  final int hex;
  final ColorTier tier;

  const PaintColorDef({
    required this.id,
    required this.name,
    required this.hex,
    required this.tier,
  });
}

/// Drop rate weights per tier (sum=100).
/// Common ~40%, Uncommon ~25%, Rare ~18%, Epic ~10%, Legendary ~5%, Mythic ~2%
const Map<ColorTier, double> kColorTierDropWeights = {
  ColorTier.common: 40.0,
  ColorTier.uncommon: 25.0,
  ColorTier.rare: 18.0,
  ColorTier.epic: 10.0,
  ColorTier.legendary: 5.0,
  ColorTier.mythic: 2.0,
};

const List<PaintColorDef> kPaintColors = [
  // ── Common (~40%) ──
  PaintColorDef(id: 'cherry_red', name: 'Cherry Red', hex: 0xFFFF3B30, tier: ColorTier.common),
  PaintColorDef(id: 'sky_blue', name: 'Sky Blue', hex: 0xFF87CEEB, tier: ColorTier.common),
  PaintColorDef(id: 'forest_green', name: 'Forest Green', hex: 0xFF228B22, tier: ColorTier.common),
  PaintColorDef(id: 'sunset_orange', name: 'Sunset Orange', hex: 0xFFFF8C42, tier: ColorTier.common),
  PaintColorDef(id: 'lavender', name: 'Lavender', hex: 0xFFB57EDC, tier: ColorTier.common),
  PaintColorDef(id: 'daisy_yellow', name: 'Daisy Yellow', hex: 0xFFFDD835, tier: ColorTier.common),
  // ── Uncommon (~25%) ──
  PaintColorDef(id: 'teal', name: 'Teal', hex: 0xFF009688, tier: ColorTier.uncommon),
  PaintColorDef(id: 'coral', name: 'Coral', hex: 0xFFFF6F61, tier: ColorTier.uncommon),
  PaintColorDef(id: 'slate_blue', name: 'Slate Blue', hex: 0xFF6A5ACD, tier: ColorTier.uncommon),
  PaintColorDef(id: 'olive', name: 'Olive', hex: 0xFF808000, tier: ColorTier.uncommon),
  PaintColorDef(id: 'dusty_rose', name: 'Dusty Rose', hex: 0xFFDCAE96, tier: ColorTier.uncommon),
  // ── Rare (~18%) ──
  PaintColorDef(id: 'royal_purple', name: 'Royal Purple', hex: 0xFF7B2D8E, tier: ColorTier.rare),
  PaintColorDef(id: 'electric_blue', name: 'Electric Blue', hex: 0xFF0892D0, tier: ColorTier.rare),
  PaintColorDef(id: 'crimson', name: 'Crimson', hex: 0xFFDC143C, tier: ColorTier.rare),
  PaintColorDef(id: 'emerald', name: 'Emerald', hex: 0xFF50C878, tier: ColorTier.rare),
  // ── Epic (~10%) ──
  PaintColorDef(id: 'neon_pink', name: 'Neon Pink', hex: 0xFFFF6EC7, tier: ColorTier.epic),
  PaintColorDef(id: 'deep_ocean', name: 'Deep Ocean', hex: 0xFF003366, tier: ColorTier.epic),
  PaintColorDef(id: 'magma_red', name: 'Magma Red', hex: 0xFFFF4500, tier: ColorTier.epic),
  PaintColorDef(id: 'arctic_white', name: 'Arctic White', hex: 0xFFF0F8FF, tier: ColorTier.epic),
  // ── Legendary (~5%) ──
  PaintColorDef(id: 'holographic_silver', name: 'Holographic Silver', hex: 0xFFC0C0C0, tier: ColorTier.legendary),
  PaintColorDef(id: 'molten_gold', name: 'Molten Gold', hex: 0xFFFFD700, tier: ColorTier.legendary),
  PaintColorDef(id: 'midnight_indigo', name: 'Midnight Indigo', hex: 0xFF1A0033, tier: ColorTier.legendary),
  // ── Mythic (~2%) ──
  PaintColorDef(id: 'prismatic', name: 'Prismatic', hex: 0xFFFF69B4, tier: ColorTier.mythic),
  PaintColorDef(id: 'void_black', name: 'Void Black', hex: 0xFF0A0A0A, tier: ColorTier.mythic),
  PaintColorDef(id: 'celestial_white', name: 'Celestial White', hex: 0xFFFFFAF0, tier: ColorTier.mythic),
];

PaintColorDef? getPaintColorById(String id) {
  for (final c in kPaintColors) {
    if (c.id == id) return c;
  }
  return null;
}

/// Roll a random paint color using weighted tier drop rates.
PaintColorDef rollRandomPaintColor(Random rng) {
  final totalWeight = kColorTierDropWeights.values.fold(0.0, (a, b) => a + b);
  double roll = rng.nextDouble() * totalWeight;

  ColorTier selectedTier = ColorTier.common;
  for (final entry in kColorTierDropWeights.entries) {
    roll -= entry.value;
    if (roll <= 0) {
      selectedTier = entry.key;
      break;
    }
  }

  final colorsInTier = kPaintColors.where((c) => c.tier == selectedTier).toList();
  return colorsInTier[rng.nextInt(colorsInTier.length)];
}

// ═══════════════════════════════════════════════════════════════════════════
// DEFAULT COLORS
// ═══════════════════════════════════════════════════════════════════════════

const int kDefaultWallColor = 0xFFE8DCC8;
const int kDefaultDirtColor = 0xFFC4A882;
const int kDefaultRollerPaintColor = 0xFFFF3B30;
const int kDefaultBorderColor = 0xFF000000;
const int kGameBackgroundColor = 0xFFBCF9F1;
