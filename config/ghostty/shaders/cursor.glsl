// omac cursor effects for Ghostty (custom-shader), in the shell and in Neovim:
//
//  1. Smear: when the cursor jumps, a short trail in the cursor's colour
//     stretches from where it was and shrinks into the new spot. Typing
//     (one-cell moves) leaves no trail.
//  2. Expand blink, like VS Code's "editor.cursorBlinking": "expand": after
//     half a second without typing the cursor shrinks to nothing from its middle
//     and grows back, instead of switching on and off. It stops after 10s,
//     the way VS Code does.
//
// Ghostty draws the cursor itself; for the blink this shader hides the part of
// it that has "shrunk" by rebuilding the cell from the cursor colours.
// Turn it off: remove the `custom-shader` line from ~/.config/ghostty/config.ghostty.

// Smear
const float SMEAR_TIME = 0.14;  // seconds the trail takes to catch up
const float SMEAR_OPACITY = 0.85;
// Expand blink (VS Code timings)
const float BLINK_DELAY = 0.5;  // idle time before it starts
const float BLINK_HALF = 0.5;   // one shrink (or one grow)
const float BLINK_HALVES = 20.0; // then it stays solid (10s)

float easeOut(float t) {
  float u = 1.0 - t;
  return 1.0 - u * u * u;
}

// How far point p lies inside an axis-aligned box of half-size h swept from
// centre a to centre b (positive inside, negative outside, in pixels).
// The margin along the sweep is concave and piecewise linear in t, so its
// maximum sits at one of these breakpoints.
float sweptBox(vec2 p, vec2 a, vec2 b, vec2 h) {
  vec2 d = b - a;
  vec2 e0 = p - a;
  float ts[8];
  ts[0] = 0.0;
  ts[1] = 1.0;
  ts[2] = abs(d.x) > 1e-4 ? e0.x / d.x : 0.0;
  ts[3] = abs(d.y) > 1e-4 ? e0.y / d.y : 0.0;
  const vec2 signs[4] = vec2[4](vec2(1.0, 1.0), vec2(-1.0, 1.0), vec2(1.0, -1.0), vec2(-1.0, -1.0));
  for (int i = 0; i < 4; i++) {
    float k = signs[i].x * d.x - signs[i].y * d.y;
    ts[4 + i] = abs(k) > 1e-4 ? (h.y - h.x - signs[i].y * e0.y + signs[i].x * e0.x) / k : 0.0;
  }
  float best = -1e9;
  for (int i = 0; i < 8; i++) {
    float t = clamp(ts[i], 0.0, 1.0);
    vec2 e = abs(e0 - t * d);
    best = max(best, min(h.x - e.x, h.y - e.y));
  }
  return best;
}

vec3 srgbToLinear(vec3 c) {
  return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

// Expand blink: visible height of the cursor (1 = full, 0 = gone).
// VS Code keyframes: hold 20%, ease-in-out 60%, hold 20%, alternating.
float blinkScale(float idle) {
  float u = idle - BLINK_DELAY;
  if (u < 0.0) return 1.0;
  float half_ = floor(u / BLINK_HALF);
  if (half_ >= BLINK_HALVES) return 1.0;
  float x = clamp((fract(u / BLINK_HALF) - 0.2) / 0.6, 0.0, 1.0);
  float e = x * x * (3.0 - 2.0 * x);
  return mod(half_, 2.0) < 0.5 ? 1.0 - e : e;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
  fragColor = base;

  if (iFocus == 0 || iCursorVisible == 0) return;

  float idle = iTime - iTimeCursorChange;

  // xy is the left/top corner (y grows upwards), zw the size
  vec2 size = iCurrentCursor.zw;
  vec2 h = 0.5 * size;
  vec2 head = iCurrentCursor.xy + vec2(0.5, -0.5) * size;
  vec2 q = abs(fragCoord - head);
  bool onCursor = q.x < h.x && q.y < h.y;

  // ── expand blink ──────────────────────────────────────────────────────────
  if (onCursor) {
    float s = blinkScale(idle);
    if (s >= 1.0 || q.y < s * h.y) return; // still part of the visible cursor

    // Hide this pixel. Inside the cursor Ghostty paints the cursor colour with
    // the glyph in the cursor-text colour: t is how much glyph a pixel holds.
    // The screen texture may hold linear or sRGB values, so read the cursor
    // colour off the cursor's own top-left pixel and match the others to it.
    vec2 topAt = vec2(iCurrentCursor.x + 0.5, iCurrentCursor.y - 0.5);
    vec3 cc = texture(iChannel0, topAt / iResolution.xy).rgb;
    vec3 ccS = iCurrentCursorColor.rgb;
    vec3 ccL = srgbToLinear(ccS);
    float dS = distance(cc, ccS), dL = distance(cc, ccL);
    if (min(dS, dL) > 0.08) return; // that pixel isn't the cursor (underline style)
    bool lin = dL < dS;
    vec3 ct = lin ? srgbToLinear(iCursorText) : iCursorText;
    vec3 fg = lin ? srgbToLinear(iForegroundColor) : iForegroundColor;
    vec3 axis = ct - cc;
    float t = clamp(dot(base.rgb - cc, axis) / max(dot(axis, axis), 1e-5), 0.0, 1.0);
    if (distance(base.rgb, cc + t * axis) > 0.08) return; // not a cursor pixel (bar/underline cell)

    // Cell background: the blank top row of the next cell keeps Ghostty's
    // background colour and glass opacity exactly as it renders them.
    vec2 bgAt = vec2(iCurrentCursor.x + size.x + 0.5 * size.x, iCurrentCursor.y - 1.0);
    vec4 bg = texture(iChannel0, clamp(bgAt, vec2(0.5), iResolution.xy - 0.5) / iResolution.xy);
    fragColor = mix(bg, vec4(fg, 1.0), t);
    return;
  }

  // ── smear ─────────────────────────────────────────────────────────────────
  float st = idle / SMEAR_TIME;
  if (st >= 1.0) return;

  vec2 prev = iPreviousCursor.xy + vec2(0.5, -0.5) * iPreviousCursor.zw;
  vec2 jump = head - prev;
  // Typing moves one cell at a time: no trail for that
  if (abs(jump.y) < 0.5 && abs(jump.x) <= max(size.x, iPreviousCursor.z) * 1.5) return;

  float p = easeOut(clamp(st, 0.0, 1.0));
  vec2 tail = mix(prev, head, p);
  float m = sweptBox(fragCoord, tail, head, h);
  float a = clamp(m + 0.5, 0.0, 1.0) * SMEAR_OPACITY * (1.0 - p);
  if (a <= 0.0) return;

  // "over" blend that keeps Ghostty's background opacity intact
  vec3 c = iCurrentCursorColor.rgb;
  fragColor = vec4(base.rgb * (1.0 - a) + c * a, base.a * (1.0 - a) + a);
}
