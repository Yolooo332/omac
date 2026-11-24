// Builds the white theme from the dark one, so both keep the same coloring layout.
// Usage: node scripts/build-white.mjs   (run from the vscode/ folder, or anywhere)
//
// Every color in the dark theme is translated by role via ../palette.json.
// Colors that are not palette roles (VS Code chrome defaults: git, merge, peek, terminal)
// get a light equivalent from EXTRA below; keys whose meaning differs from their hex
// (e.g. dark text on a baby-blue button) are pinned in KEY_OVERRIDES.
// The build fails if any color is left untranslated.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const palette = JSON.parse(readFileSync(join(root, "..", "palette.json"), "utf8"));
const darkPath = join(root, "themes", "Baby Blue Theme-color-theme.json");
const whitePath = join(root, "themes", "Baby Blue Theme White-color-theme.json");

const dark = JSON.parse(readFileSync(darkPath, "utf8"));
const { dark: D, white: W } = palette;

// Roles translated by hex. (accentFill and frame share a hex with accent and link, so they
// are resolved per key below; surface/pink/terminal etc. are for the terminal ports.)
const HEX_ROLES = ["bg", "fg", "muted", "accent", "string", "comment", "link",
  "selection", "lineNumber", "guide", "error", "invalid"];

// 6-digit base (lowercase) -> role
const baseToRole = {};
for (const role of HEX_ROLES) baseToRole[D[role].slice(1, 7).toLowerCase()] = role;

// Non-role colors: dark value -> white value (VS Code Light+ equivalents, tuned for #ffffff).
// (Translucent whites like #ffffff66 already flip to translucent black via the "invalid" role.)
const EXTRA = {
  "#000000": "#dddddd",       // scrollbar shadow
  "#cccccc99": "#20202099",   // inactive title bar text
  "#92929299": "#20202080",   // inactive panel title
  "#00000085": "#00000020",   // menu border
  "#a6a6a6": "#8a8a8a",       // input placeholder
  "#ea5c0055": "#ea5c0040",   // other find matches
  "#575757b8": "#57575730",   // word highlight
  "#5a5a5a": "#d0d0d0",       // ruler
  "#888888": "#b0b0b0",       // bracket match border
  "#25252500": "#ffffff00",
  "#f48771": "#e51400",       // error squiggle / icons
  "#cca700": "#bf8803",       // warning
  "#75beff": "#1a85ff",       // info
  "#0c7d9d": "#2090d3",       // gutter modified
  "#587c0c": "#48985d",       // gutter added
  "#94151b": "#e51400",       // gutter deleted
  "#999999": "#919191",       // code lens
  "#9bb95533": "#9bb95540",   // diff inserted
  "#ff000033": "#ff000026",   // diff removed
  "#444444": "#d0d0d0",       // diff border
  "#2d2d30": "#f3f3f3",       // marker navigation
  "#001f33": "#f2f8fc",       // peek editor
  "#252526": "#f3f3f3",       // peek results
  "#1e1e1e": "#f3f3f3",       // peek title
  "#bbbbbb": "#646465",       // peek result lines
  "#ccccccb3": "#616161",     // peek title description
  "#00000050": "#f4f4f4",     // walkthrough embedded editor
  // Unchanged: transparent values and accents that read fine on white.
  "#00000000": "#00000000", "#007acc00": "#007acc00",
  "#b73a3400": "#b73a3400", "#a9904000": "#a9904000", "#4490bf00": "#4490bf00",
  "#be1100": "#be1100", "#0064001a": "#0064001a", "#7f7f7f4d": "#7f7f7f4d",
  "#0078d4": "#0078d4", "#ff8f0099": "#ff8f0099", "#ee931e": "#ee931e",
  "#ea5c004d": "#ea5c004d", "#3399ff33": "#3399ff33",
};

const KEY_OVERRIDES = {
  // Baby blue stays baby blue where it is a fill behind dark text.
  "button.background": W.accentFill,
  "button.secondaryBackground": W.accentFill,
  "statusBarItem.remoteBackground": W.accentFill,
  "progressBar.background": W.accentFill,
  "button.foreground": "#181818",
  "button.secondaryForeground": "#181818",
  "statusBarItem.remoteForeground": "#181818",
  "button.hoverBackground": "#b5e1f6",
  "button.secondaryHoverBackground": "#b5e1f6",
  // Orange debug bar keeps its fill and dark text.
  "statusBar.debuggingBackground": "#ff9b21",
  "statusBar.debuggingForeground": "#181818",
  // Tan frame lines.
  "editorGroup.border": W.frame,
  "peekView.border": W.frame,
  // Git decorations (Light+).
  "gitDecoration.addedResourceForeground": "#587c0c",
  "gitDecoration.conflictingResourceForeground": "#ad0707",
  "gitDecoration.deletedResourceForeground": "#ad0707",
  "gitDecoration.ignoredResourceForeground": "#8e8e90",
  "gitDecoration.modifiedResourceForeground": "#895503",
  "gitDecoration.stageDeletedResourceForeground": "#ad0707",
  "gitDecoration.stageModifiedResourceForeground": "#895503",
  "gitDecoration.submoduleResourceForeground": "#1258a7",
  "gitDecoration.untrackedResourceForeground": "#007100",
  // Merge conflicts.
  "merge.currentHeaderBackground": "#40c8ae80",
  "merge.currentContentBackground": "#40c8ae33",
  "merge.incomingHeaderBackground": "#40a6ff80",
  "merge.incomingContentBackground": "#40a6ff33",
  "merge.commonHeaderBackground": "#60606066",
  "merge.commonContentBackground": "#60606029",
  // Terminal ANSI comes from palette.json (no yellow: slots 3 and 11 are baby blue).
  ...Object.fromEntries(
    ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]
      .flatMap((n, i) => [[`terminal.ansi${n}`, W.terminal[i]], [`terminal.ansiBright${n}`, W.terminal[i + 8]]]),
  ),
};

const missing = new Set();

function translate(hex, where) {
  const h = hex.toLowerCase();
  const base = h.slice(1, 7);
  const alpha = h.slice(7);
  const role = baseToRole[base];
  if (role) {
    const darkVal = D[role].toLowerCase();
    const whiteVal = W[role];
    // Exact match (including the role's own alpha) -> the white role value as-is.
    if (h === darkVal || (!alpha && darkVal.length === 7)) return whiteVal;
    // Same base, different alpha (e.g. a transparent "#18181800") -> keep that alpha.
    return whiteVal.slice(0, 7) + alpha;
  }
  if (h in EXTRA) return EXTRA[h];
  missing.add(`${hex}  (${where})`);
  return hex;
}

const white = structuredClone(dark);
white.name = "Baby Blue Theme White";
white.type = "light";

for (const [scope, style] of Object.entries(white.semanticTokenColors ?? {})) {
  if (style.foreground) style.foreground = translate(style.foreground, `semantic ${scope}`);
}
for (const rule of white.tokenColors) {
  const s = rule.settings;
  if (s.foreground) s.foreground = translate(s.foreground, `token ${rule.name ?? rule.scope}`);
  if (s.background) s.background = translate(s.background, `token ${rule.name ?? rule.scope}`);
}
for (const [key, val] of Object.entries(white.colors)) {
  white.colors[key] = key in KEY_OVERRIDES ? KEY_OVERRIDES[key] : translate(val, key);
}

if (missing.size) {
  console.error("Untranslated colors - add them to palette.json or EXTRA:\n  " + [...missing].join("\n  "));
  process.exit(1);
}

writeFileSync(whitePath, JSON.stringify(white, null, "\t") + "\n");
console.log(`Wrote ${whitePath}`);
