import csv
import json
import sys
from pathlib import Path


def clean(value: str | None) -> str:
    if not value:
        return ""
    return value.replace("\r\n", "\n").replace("\r", "\n").strip()


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: build_dictionary.py <ecdict.csv> <dictionary_seed.json>")
        return 2

    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    entries = []
    seen: set[str] = set()

    with source.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            word = clean(row.get("word")).lower()
            translation = clean(row.get("translation"))
            definition = clean(row.get("definition"))

            if not word or word in seen:
                continue
            if not translation and not definition:
                continue

            seen.add(word)
            entries.append(
                {
                    "word": word,
                    "phonetic": clean(row.get("phonetic")) or None,
                    "translation": translation or definition,
                    "definition": definition or None,
                }
            )

    entries.sort(key=lambda item: item["word"])
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(entries, handle, ensure_ascii=False, separators=(",", ":"))

    print(f"wrote {len(entries)} dictionary entries to {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
