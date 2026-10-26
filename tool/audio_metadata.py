"""Write assets/audio/recordings.json from the bundled audio filenames.

The uploader's filenames carry inconsistent prefixes (Mujaadalah is marked 01
but is surah 58; Baqarah and Hashr both say 02), so ordering by filename would
scatter the mushaf. This maps each filename to its verified surah number and a
clean title, and the app sorts by that number.

Files whose name does not match a surah unambiguously are left out of the JSON:
the app then falls back to a title derived from the filename rather than
guessing a number. Re-run this after adding audio.

    python tool/audio_metadata.py
"""
import json
import os
import re
import sys
import unicodedata

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "assets", "audio")
OUT = os.path.join(AUDIO, "recordings.json")

# (number, title, accepted spellings)
SURAHS = [
    (1, "Al-Faatihah", ["faatihah", "fatihah", "fatiha"]),
    (2, "Al-Baqarah", ["baqarah", "baqara"]),
    (3, "Aal-Imraan", ["aal imraan", "aal imran", "imraan", "imran"]),
    (4, "An-Nisaa", ["nisaa", "nisa"]),
    (5, "Al-Maaidah", ["maaidah", "maidah", "ma idah", "maa idah"]),
    (6, "Al-An'aam", ["an aam", "anaam", "anam"]),
    (7, "Al-A'raaf", ["a raaf", "araaf", "araf"]),
    (8, "Al-Anfaal", ["anfaal", "anfal"]),
    (9, "At-Tawbah", ["tawbah", "taubah", "tawba"]),
    (10, "Yunus", ["yunus"]),
    (11, "Huud", ["huud", "hud"]),
    (12, "Yusuf", ["yusuf"]),
    (13, "Ar-Ra'd", ["raad", "ra d"]),
    (14, "Ibrahim", ["ibrahim"]),
    (15, "Al-Hijr", ["hijr"]),
    (16, "An-Nahl", ["nahl", "nnahl"]),
    (17, "Al-Israa", ["israa", "isra"]),
    (18, "Al-Kahf", ["kahf"]),
    (19, "Maryam", ["maryam"]),
    (20, "Taa-Haa", ["taa haa", "ta ha", "taha"]),
    (21, "Al-Anbiyaa", ["ambiyaa", "anbiyaa", "anbiya"]),
    (22, "Al-Hajj", ["hajj"]),
    (23, "Al-Mu'minoon", ["mu minoon", "muminoon", "muminun", "mu minun"]),
    (24, "An-Noor", ["noor", "nur"]),
    (25, "Al-Furqaan", ["furqaan", "furqan"]),
    (26, "Ash-Shu'araa", ["shuaraa", "shu araa", "shuara"]),
    (27, "An-Naml", ["naml"]),
    (28, "Al-Qasas", ["qasas"]),
    (29, "Al-Ankaboot", ["ankaboot", "ankabut"]),
    (30, "Ar-Room", ["room", "rum"]),
    (31, "Luqman", ["luqman"]),
    (32, "As-Sajdah", ["sajdah", "sajda"]),
    (33, "Al-Ahzaab", ["ahzaab", "ahzab"]),
    (34, "Saba", ["saba"]),
    (35, "Faatir", ["faatir", "fatir"]),
    (36, "Yaaseen", ["yaaseen", "yasin", "yaseen"]),
    (37, "As-Saaffaat", ["saaffaat", "saffat", "saffaat"]),
    (38, "Saad", ["saad", "sad"]),
    (39, "Az-Zumar", ["zumar"]),
    (40, "Ghaafir", ["ghaafir", "ghafir"]),
    (41, "Fussilat", ["fussilat"]),
    (42, "Ash-Shooraa", ["shooraa", "shura"]),
    (43, "Az-Zukhruf", ["zukhruf"]),
    (44, "Ad-Dukhaan", ["dukhaan", "dukhan"]),
    (45, "Al-Jaathiyah", ["jaathiyah", "jathiyah"]),
    (46, "Al-Ahqaaf", ["ahqaaf", "ahqaf"]),
    (47, "Muhammad", ["muhammad"]),
    (48, "Al-Fath", ["fath"]),
    (49, "Al-Hujuraat", ["hujuraat", "hujurat"]),
    (50, "Qaaf", ["qaaf", "qaf"]),
    (51, "Adh-Dhaariyaat",
     ["dhaariyaat", "dhariyat", "dhariyaat", "thaariat", "thaariyat"]),
    (52, "At-Toor", ["toor", "tuur", "tur"]),
    (53, "An-Najm", ["najm"]),
    (54, "Al-Qamar", ["qamar"]),
    (55, "Ar-Rahmaan", ["rahmaan", "rahman"]),
    (56, "Al-Waaqi'ah", ["waaqiah", "waqiah", "waqia"]),
    (57, "Al-Hadeed", ["hadeed", "hadid"]),
    (58, "Al-Mujaadalah", ["mujaadalah", "mujadalah", "mujaadala", "mujadala"]),
    (59, "Al-Hashr", ["hashr"]),
    (60, "Al-Mumtahanah", ["mumtahanah", "mumtahana"]),
    (61, "As-Saff", ["saff"]),
    (62, "Al-Jumu'ah", ["jumuah", "jumua"]),
    (63, "Al-Munaafiqoon", ["munaafiqoon", "munafiqun", "munafiqoon"]),
    (64, "At-Taghaabun", ["taghaabun", "taghabun"]),
    (65, "At-Talaaq", ["talaaq", "talaq"]),
    (66, "At-Tahreem", ["tahreem", "tahrim"]),
    (67, "Al-Mulk", ["mulk"]),
    (68, "Al-Qalam", ["qalam"]),
    (69, "Al-Haaqqah", ["haaqqah", "haqqah", "haqqa"]),
    (70, "Al-Ma'aarij", ["ma aarij", "maarij", "ma arij", "marij"]),
    (71, "Nooh", ["nooh", "nuh"]),
    (72, "Al-Jinn", ["jinn"]),
    (73, "Al-Muzzammil", ["muzzammil", "muzammil"]),
    (74, "Al-Muddaththir", ["muddaththir", "muddathir"]),
    (75, "Al-Qiyaamah", ["qiyaamah", "qiyamah"]),
    (76, "Al-Insaan", ["insaan", "insan"]),
    (77, "Al-Mursalaat", ["mursalaat", "mursalat"]),
    (78, "An-Naba", ["naba"]),
    (79, "An-Naazi'aat", ["naazi aat", "naaziaat", "naziat"]),
    (80, "Abasa", ["abasa"]),
    (81, "At-Takweer", ["takweer", "takwir"]),
    (82, "Al-Infitaar", ["infitaar", "infitar"]),
    (83, "Al-Mutaffifeen", ["mutaffifeen", "mutaffifin"]),
    (84, "Al-Inshiqaaq", ["inshiqaaq", "inshiqaq"]),
    (85, "Al-Burooj", ["burooj", "buruj"]),
    (86, "At-Taariq", ["taariq", "tariq"]),
    (87, "Al-A'laa", ["a laa", "alaa"]),
    (88, "Al-Ghaashiyah", ["ghaashiyah", "ghashiyah"]),
    (89, "Al-Fajr", ["fajr"]),
    (90, "Al-Balad", ["balad"]),
    (91, "Ash-Shams", ["shams"]),
    (92, "Al-Layl", ["layl"]),
    (93, "Ad-Duhaa", ["duhaa", "duha"]),
    (94, "Ash-Sharh", ["sharh"]),
    (95, "At-Teen", ["teen", "tin"]),
    (96, "Al-Alaq", ["alaq"]),
    (97, "Al-Qadr", ["qadr"]),
    (98, "Al-Bayyinah", ["bayyinah", "bayyina"]),
    (99, "Az-Zalzalah", ["zalzalah", "zalzala"]),
    (100, "Al-Aadiyaat", ["aadiyaat", "adiyat"]),
    (101, "Al-Qaari'ah", ["qaari ah", "qaariah", "qariah"]),
    (102, "At-Takaathur", ["takaathur", "takathur"]),
    (103, "Al-Asr", ["asr"]),
    (104, "Al-Humazah", ["humazah", "humaza"]),
    (105, "Al-Feel", ["feel", "fil"]),
    (106, "Quraysh", ["quraysh"]),
    (107, "Al-Maa'oon", ["maa oon", "maaoon", "maun"]),
    (108, "Al-Kawthar", ["kawthar", "kausar"]),
    (109, "Al-Kaafiroon", ["kaafiroon", "kafirun", "kafiroon"]),
    (110, "An-Nasr", ["nasr"]),
    (111, "Al-Masad", ["masad"]),
    (112, "Al-Ikhlaas", ["ikhlaas", "ikhlas"]),
    (113, "Al-Falaq", ["falaq"]),
    (114, "An-Naas", ["naas", "nas"]),
]

# Words that carry no surah information.
NOISE = {
    "surah", "surat", "sura", "absurah", "quran", "full",
    "done", "done000", "new", "marying", "joining", "audio", "mp3",
    "chichewa",
}


def normalise(text):
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = text.lower().replace("'", "").replace("\u2019", "")
    return re.sub(r"[^a-z0-9]+", " ", text).strip()


def match(title):
    """Return (surah number, title suffix) or None when not unambiguous."""
    text = normalise(os.path.splitext(title)[0])
    juz = re.search(r"juz\s*0*(\d+)", text)
    tokens = [t for t in text.split() if not t.isdigit() and t not in NOISE and t != "juz"]
    # Two-word spellings such as "mu minoon" must survive the noise filter.
    joined = " ".join(tokens)
    haystack = f" {joined} "

    best = None
    for number, name, aliases in SURAHS:
        for alias in aliases:
            if f" {alias} " not in haystack:
                continue
            score = (len(alias.split()), len(alias))
            if best is None or score > best[0]:
                best = (score, number, name)
            elif score == best[0] and number != best[1]:
                return None  # two surahs match equally well: do not guess
    if best is None:
        return None
    return best[1], best[2], (f"Juz {int(juz.group(1))}" if juz else None)


AUDIO_EXTENSIONS = (".mp3", ".m4a", ".aac", ".ogg", ".opus", ".flac", ".wav")


def main():
    files = sorted(f for f in os.listdir(AUDIO)
                   if f.lower().endswith(AUDIO_EXTENSIONS))
    entries, unknown = [], []
    for name in files:
        found = match(name)
        if not found:
            unknown.append(name)
            continue
        number, surah_title, suffix = found
        title = f"{surah_title} \u00b7 {suffix}" if suffix else surah_title
        entries.append(
            {
                "file": f"assets/audio/{name}",
                "title": title,
                "surahNumber": number,
            }
        )

    entries.sort(key=lambda e: (e["surahNumber"], e["title"].lower()))
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"{len(entries)} of {len(files)} files mapped -> {os.path.relpath(OUT, ROOT)}")
    for entry in entries:
        print(f"  {entry['surahNumber']:>3}  {entry['title']:<28} {entry['file'].split('/')[-1]}")
    if unknown:
        print("\nleft unnumbered (title falls back to the filename):")
        for name in unknown:
            print(f"       {name}")


if __name__ == "__main__":
    main()
