"""Génère l'icône Android de YOBALEMAsn (repère vert + route orange, comme le logo du site).

Usage (depuis mobile/) : python tool/generer_icone.py   — nécessite Pillow.
Écrit les mipmaps classiques, l'icône adaptative (Android 8+) et la couleur de fond.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw

RES = Path(__file__).resolve().parent.parent / "android/app/src/main/res"
VERT, VERT_CLAIR, ORANGE, FOND = "#0c6b3f", "#2fa36a", "#f29a1f", "#f4faf6"
S = 4  # sur-échantillonnage


def repere(taille, hauteur_relative):
    """Dessine le repère centré sur un calque transparent carré ; hauteur_relative = part de la hauteur occupée."""
    n = taille * S
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Le logo du site tient dans un viewBox 40x48 ; la forme va de y=4 à y=46.
    k = n * hauteur_relative / 42.0
    ox, oy = n / 2 - 20 * k, n / 2 - 25 * k

    def p(x, y):
        return ox + x * k, oy + y * k

    cx, cy, r = 20, 19, 15
    d.ellipse([*p(cx - r, cy - r), *p(cx + r, cy + r)], fill=VERT)
    # pointe : tangentes depuis (20, 46) au cercle
    dist = 46 - cy
    a = math.acos(r / dist)
    pts = [p(cx - r * math.sin(a), cy + r * math.cos(a)), p(20, 46), p(cx + r * math.sin(a), cy + r * math.cos(a))]
    d.polygon(pts, fill=VERT)
    d.ellipse([*p(cx - 10.5, cy - 10.5), *p(cx + 10.5, cy + 10.5)], fill="#ffffff")
    # route (arc orange)
    arc = []
    for i in range(41):
        t = i / 40
        x = 13 + 14 * t
        y = 23.5 - 8 * math.sin(math.pi * t) * 0.97
        arc.append(p(x, y))
    d.line(arc, fill=ORANGE, width=int(2.6 * k), joint="curve")
    for ex, ey in (arc[0], arc[-1]):
        w = 1.3 * k
        d.ellipse([ex - w, ey - w, ex + w, ey + w], fill=ORANGE)
    # tirets centraux
    for y0 in (17.5, 21.3):
        d.line([p(20, y0), p(20, y0 + 1.6)], fill=VERT, width=int(1.6 * k))
    # feuille
    d.polygon([p(27.5, 9.5), p(22.3, 14.5), p(27.3, 14.4)], fill=VERT_CLAIR)
    return img.resize((taille, taille), Image.LANCZOS)


def ecrire(img, chemin):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    img.save(chemin, optimize=True)


def classique(taille):
    fond = Image.new("RGBA", (taille * S, taille * S), (0, 0, 0, 0))
    ImageDraw.Draw(fond).rounded_rectangle([0, 0, taille * S - 1, taille * S - 1], radius=taille * S // 5, fill=FOND)
    fond = fond.resize((taille, taille), Image.LANCZOS)
    fond.alpha_composite(repere(taille, 0.72))
    return fond


densites = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for nom, px in densites.items():
    ecrire(classique(px), RES / f"mipmap-{nom}/ic_launcher.png")
    # Icône adaptative : calque de 108 dp ; zone sûre = 66 dp centraux.
    ecrire(repere(round(px * 108 / 48), 0.50), RES / f"mipmap-{nom}/ic_launcher_foreground.png")

(RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
(RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    "</adaptive-icon>\n",
    encoding="utf-8",
)
(RES / "values/ic_launcher_background.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    f'    <color name="ic_launcher_background">{FOND}</color>\n</resources>\n',
    encoding="utf-8",
)
print("Icône générée dans", RES)
