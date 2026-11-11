#!/usr/bin/env bash
# Rebuild the "Hemo Glyphs" font, so text-only UIs (polybar) can show the logo:
#   U+E000  the whole lizard  (branding/assets/hemo-mark.png)
#   U+E001  just the head     (branding/assets/hemo-head-mark.png) — polybar's icon
# Both inputs are light art on transparent. Re-run after changing either.
#   out: branding/assets/hemo-mark.svg, hemo-head-mark.svg   (traced vectors)
#        overlays/usr/local/share/fonts/HemoGlyphs.ttf
# Needs: imagemagick, potrace, python3-fontforge.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# the alpha channel is the shape; potrace traces black, so invert it
for m in hemo-mark hemo-head-mark; do
  convert "branding/assets/$m.png" -alpha extract -threshold 50% -negate -trim +repage "$tmp/$m.pbm"
  potrace -s --flat -t 8 -O 0.4 "$tmp/$m.pbm" -o "branding/assets/$m.svg"
done

mkdir -p overlays/usr/local/share/fonts
python3 - branding/assets/hemo-mark.svg branding/assets/hemo-head-mark.svg \
  overlays/usr/local/share/fonts/HemoGlyphs.ttf <<'EOF'
import sys, fontforge, psMat
body, head, out = sys.argv[1:4]
f = fontforge.font()
f.fontname, f.familyname, f.fullname = "HemoGlyphs", "Hemo Glyphs", "Hemo Glyphs"
f.encoding = "UnicodeFull"; f.em = 1000; f.ascent = 800; f.descent = 200
def glyph(code, name, svg):
    g = f.createChar(code, name)
    g.importOutlines(svg)
    g.removeOverlap(); g.simplify(); g.correctDirection()
    # fit the longer side to the em box, centred vertically on it
    xmin, ymin, xmax, ymax = g.boundingBox()
    s = 1000.0 / max(ymax - ymin, xmax - xmin)
    g.transform(psMat.translate(-xmin, -ymin)); g.transform(psMat.scale(s))
    g.transform(psMat.translate(40, -200 + (1000 - (ymax - ymin) * s) / 2))
    g.width = int((xmax - xmin) * s) + 80
glyph(0xE000, "hemo", body)
glyph(0xE001, "hemohead", head)
f.generate(out)
EOF
echo "built overlays/usr/local/share/fonts/HemoGlyphs.ttf"
