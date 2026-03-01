import 'package:flutter/material.dart';
import '../config/game_config.dart' show ColorTier;

/// Centralized color palette for the entire app.
/// Change values here to re-theme everything at once.
abstract final class AppColors {
  // ── Core backgrounds ──
  static const background    = Color(0xFFE8D5B8); // warm beige
  static const cardCream     = Color(0xFFF5E6D0); // lighter cream for cards
  static const dialogBg      = Color(0xFFFFF5E8); // very light cream for dialogs

  // ── Brown palette (text & borders) ──
  static const brownDark     = Color(0xFF6B5038); // primary text, titles, tab bg
  static const brownMid      = Color(0xFF8B7355); // secondary text, labels
  static const brownLight    = Color(0xFFB89E7A); // tertiary text, icons
  static const borderBrown   = Color(0xFFC4A882); // card borders
  static const inputBorder   = Color(0xFFD5C4A8); // text field borders
  static const tabUnselected = Color(0xFFD4C4A8); // unselected tab label

  // ── Accent colors ──
  static const primary       = Color(0xFFE8734A); // orange/coral – buttons, focused borders
  static const secondary     = Color(0xFF4ADE80); // green – success, rewards, idle income
  static const gold          = Color(0xFFF5C842); // coin/gold accents
  static const gem           = Color(0xFFDA70D6); // gem purple (orchid)
  static const purpleAccent  = Color(0xFFA855F7); // marketplace gem, color-match minigame

  // ── Dark UI (HUD, nav bar) ──
  static const hudDark       = Color(0xFF2A2A2A); // HUD tiles, nav bar bg
  static const hudBorder     = Color(0xFF111111); // HUD tile borders
  static const darkText      = Color(0xFF2A2A2A); // dark text on light backgrounds

  // ── Progression cards ──
  static const progressionBg    = Color(0xFF5A4230); // dark brown card bg
  static const progressionBrown = Color(0xFF8B6B4F); // skin card border

  // ── Streak & payout ──
  static const streak        = Color(0xFFFF6B35); // streak fire
  static const payoutGold    = Color(0xFFFFC843); // payout text

  // ── Upgrade card accents ──
  static const upgradeHouse  = Color(0xFFF5C842); // house level card (= gold)
  static const upgradeRoller = Color(0xFF3B82F6); // roller level card (blue)

  // ── Badge / title colors ──
  static const badgeGoldBrown = Color(0xFFD4880F);
  static const badgePurple    = Color(0xFF8B3FC7);
  static const badgeGreen     = Color(0xFF2E8B57);
  static const badgeOrange    = Color(0xFFCC5522);
  static const badgeBlue      = Color(0xFF2563EB);

  // ── Nav bar tab colors ──
  static const navTrade   = Color(0xFF38BDF8); // sky blue
  static const navSocial  = Color(0xFFFF6B6B); // coral
  static const navPaint   = Color(0xFFF5C842); // gold
  static const navLevelUp = Color(0xFF4ADE80); // green
  static const navMe      = Color(0xFFA855F7); // purple

  // ── Rarity colors ──
  static const rarityCommon    = Color(0xFF9E9E9E);
  static const rarityUncommon  = Color(0xFF4ADE80);
  static const rarityRare      = Color(0xFF3B82F6);
  static const rarityEpic      = Color(0xFFA855F7);
  static const rarityLegendary = Color(0xFFF59E0B);
  static const rarityMythic    = Color(0xFFFF1744);

  static Color colorForTier(ColorTier tier) {
    switch (tier) {
      case ColorTier.common: return rarityCommon;
      case ColorTier.uncommon: return rarityUncommon;
      case ColorTier.rare: return rarityRare;
      case ColorTier.epic: return rarityEpic;
      case ColorTier.legendary: return rarityLegendary;
      case ColorTier.mythic: return rarityMythic;
    }
  }

  // ── Minigame shared ──
  static const minigameBg     = Color(0xFF1A1A2E); // dark navy background
  static const minigameCardBg = Color(0xFF222240); // results card
  static const minigameWallBg = Color(0xFF2A2A40); // wall/bar background

  // ── Payout bonus labels ──
  static const bonusPerfect = Color(0xFFE53935); // red
  static const bonusGreat   = Color(0xFFF5C842); // gold
  static const bonusNice    = Color(0xFFB0BEC5); // silver

  // ── Settings ──
  static const switchActive      = Color(0xFF2E8B57);
  static const switchActiveTrack = Color(0xFF90D5A0);
  static const dangerRed         = Color(0xFFCC3333);
  static const dangerBg          = Color(0xFFFDE8E8);
  static const debugGoldBg       = Color(0xFFFFF3D0);
  static const equippedGreenBg   = Color(0xFFD9F2D9);
  static const earnedBadgeBg     = Color(0xFFFFF3D0);

  // ── Confetti / celebration ──
  static const confetti = [
    Color(0xFFE94560),
    Color(0xFF4ADE80),
    Color(0xFFF5C842),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFFFF6B6B),
    Color(0xFF38BDF8),
  ];
}
