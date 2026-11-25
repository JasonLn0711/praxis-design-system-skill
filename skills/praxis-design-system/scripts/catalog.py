"""Search the installed Praxis libraries or open one complete source record."""

import argparse
import csv
from functools import partial
from html import unescape
import json
from pathlib import Path
import re
import unicodedata

SKILL = Path(__file__).resolve().parents[1]
UPSTREAM = SKILL / "references/.upstream"
UI_DATA = UPSTREAM / "ui-ux-pro-max-skill/src/ui-ux-pro-max/data"
TASTE = UPSTREAM / "taste-skill/skills/taste-skill"
TASTE_V2 = UPSTREAM / "taste-skill-v2-1-5/skills/taste-skill/library"
DIAGRAMS = UPSTREAM / "diagram-design"
DESIGN_PRO = UPSTREAM / "design-pro/skills/design-pro/references"


def normalize(value):
    return unicodedata.normalize("NFKC", value).casefold()


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", normalize(name)).strip("-")


def relative(path):
    return path.relative_to(SKILL).as_posix()


def entry(key, name, source, details, status=None):
    item = {"id": key, "name": name, "path": relative(source), "details": details}
    if status is not None:
        item["status"] = status
    return item


def csv_rows(source):
    with source.open(encoding="utf-8-sig", newline="") as stream:
        yield from csv.DictReader(stream)


def csv_catalog(filename, title, key=None, status=None):
    source = UI_DATA / filename
    for row in csv_rows(source):
        identifier = row[key] if key else slug(row[title])
        yield entry(identifier, row[title], source, row, row.get(status))


def stack_guidelines():
    for source in sorted((UI_DATA / "stacks").glob("*.csv")):
        for row in csv_rows(source):
            key = f"{source.stem}-{row['No']}"
            yield entry(key, row["Guideline"], source, row, row.get("Status"))


def design_pro(filename, table_header):
    source = DESIGN_PRO / filename
    purpose = ""
    in_table = False
    for line in source.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            purpose = line[3:]
        if not line.startswith("| "):
            in_table = False
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if cells[0] == table_header:
            headings = cells
            in_table = True
        elif in_table and cells[0] != "---":
            if len(cells) != len(headings):
                raise ValueError(f"Expected {len(headings)} columns in {source}: {line}")
            details = {"Section": purpose, **dict(zip(headings, cells))}
            yield entry(slug(cells[0]), cells[0], source, details)


def rcs_styles():
    source = UPSTREAM / "rcs-frontend-skill/references/style-atlas.md"
    for block in re.split(r"^## ", source.read_text(encoding="utf-8"), flags=re.MULTILINE)[1:]:
        heading, details = block.split("\n", 1)
        match = re.fullmatch(r"\d+\. (.*)", heading)
        if match:
            name = match[1]
            yield entry(slug(name), name, source, details.strip())


def diagrams():
    source = DIAGRAMS / "README.md"
    section = source.read_text(encoding="utf-8").split("## What it makes", 1)[1].split("</table>", 1)[0]
    pattern = r'<a href="docs/screenshots/([^"]+)\.png">.*?</a><br><b>(.*?)</b><br><sub>(.*?)</sub>'
    for key, name, description in re.findall(pattern, section):
        root = DIAGRAMS / "skills/diagram-design"
        variants = {label: relative(root / f"assets/example-{key}{suffix}.html")
                    for label, suffix in (("light", ""), ("dark", "-dark"), ("full", "-full"))}
        guide = root / f"references/type-{key}.md"
        yield entry(key, unescape(name), SKILL / variants["light"], {
            "purpose": unescape(description), "guide": relative(guide),
            "variants": variants, "guidance": guide.read_text(encoding="utf-8"),
        })


def json_catalog(source, group=None, heading="name", hero=False):
    records = json.loads(source.read_text(encoding="utf-8"))
    if group:
        records = records[group]
    for row in records:
        name = row["display"]["family"] if heading == "display" else row[heading]
        path = source.with_name(f"hero-{row['id']}.html") if hero else source
        details = {"record": row, "catalog": relative(source)} if hero else row
        yield entry(row["id"], name, path, details)


def skill_documents(repository):
    for source in sorted((UPSTREAM / repository / "skills").glob("*/SKILL.md")):
        body = source.read_text(encoding="utf-8-sig")
        frontmatter = body.split("---", 2)[1]
        name = re.search(r"^name:\s*(.+)", frontmatter, re.MULTILINE)[1].strip("'\"")
        yield entry(name, name, source, body)


def guides(directory):
    for source in sorted(directory.rglob("*.md")):
        body = source.read_text(encoding="utf-8")
        title = re.search(r"^# (.+)", body, re.MULTILINE)
        yield entry(source.stem, title[1] if title else source.stem, source, body)


COLLECTIONS = {
    "ui-styles": partial(csv_catalog, "styles.csv", "Style Category", "Style ID", "Status"),
    "design-pro": partial(design_pro, "style-library.md", "Style"),
    "rcs": rcs_styles,
    "diagrams": diagrams,
    "taste-heroes": partial(json_catalog, TASTE / "assets/layout/heroes.json", "heroes", hero=True),
    "taste-palettes": partial(json_catalog, TASTE / "library/palettes.json"),
    "taste-type": partial(json_catalog, TASTE / "library/type.json", heading="display"),
    "taste-v2-directions": partial(json_catalog, TASTE_V2 / "directions.json"),
    "taste-v2-apps": partial(json_catalog, TASTE_V2 / "app.json", "styles"),
    "taste-classics": partial(skill_documents, "taste-skill-classics"),
    "frontend-codex": partial(skill_documents, "frontend-codex-skills"),
    "ui-products": partial(csv_catalog, "products.csv", "Product Type"),
    "ui-reasoning": partial(csv_catalog, "ui-reasoning.csv", "UI_Category"),
    "ui-palettes": partial(csv_catalog, "colors.csv", "Product Type"),
    "ui-type": partial(csv_catalog, "typography.csv", "Font Pairing Name"),
    "ui-fonts": partial(csv_catalog, "google-fonts.csv", "Family"),
    "ui-ux": partial(csv_catalog, "ux-guidelines.csv", "Issue", "No"),
    "ui-charts": partial(csv_catalog, "charts.csv", "Data Type", "No"),
    "ui-landing": partial(csv_catalog, "landing.csv", "Pattern Name", "Pattern ID"),
    "ui-motion": partial(csv_catalog, "motion.csv", "Category", "No"),
    "ui-icons": partial(csv_catalog, "icons.csv", "Icon Name", "No"),
    "ui-app": partial(csv_catalog, "app-interface.csv", "Issue", "No"),
    "ui-react": partial(csv_catalog, "react-performance.csv", "Issue", "No"),
    "ui-stacks": stack_guidelines,
    "design-pro-composition": partial(design_pro, "creative-library.md", "Resource"),
    "taste-v2-heroes": partial(json_catalog, TASTE_V2 / "heroes.json"),
    "taste-v2-sections": partial(json_catalog, TASTE_V2 / "sections.json"),
    "taste-v2-shells": partial(json_catalog, TASTE_V2 / "app.json", "shells"),
    "taste-v2-patterns": partial(json_catalog, TASTE_V2 / "app.json", "patterns"),
    "taste-craft": partial(guides, TASTE / "references"),
    "impeccable": partial(guides, UPSTREAM / "impeccable/.agents/skills/impeccable/reference"),
    "rcs-craft": partial(guides, UPSTREAM / "rcs-frontend-skill/references"),
    "refero": partial(guides, UPSTREAM / "refero_skill/skills/refero-design/references"),
    "modern-web": partial(guides, UPSTREAM / "modern-web-guidance/skills/modern-web-guidance/guides"),
}


def find(collections, query):
    terms = normalize(query).split()
    for collection in collections:
        for item in COLLECTIONS[collection]():
            if terms:
                haystack = normalize(json.dumps(item, ensure_ascii=False))
                if not all(term in haystack for term in terms):
                    continue
            yield {"collection": collection, **{k: v for k, v in item.items() if k != "details"}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("query", nargs="*", help="Match all words in names, paths or source details.")
    parser.add_argument("-c", "--collection", choices=COLLECTIONS, help="Search one library.")
    parser.add_argument("--show", metavar="COLLECTION/ID", help="Return a single complete record.")
    parser.add_argument("--json", action="store_true", help="Emit JSON.")
    args = parser.parse_args()
    if args.show is not None:
        collection, _, key = args.show.partition("/")
        if args.query or args.collection or collection not in COLLECTIONS or not key:
            parser.error("Use --show COLLECTION/ID with an exact catalog ID.")
        for item in COLLECTIONS[collection]():
            if item["id"] == key:
                if args.json:
                    print(json.dumps({"collection": collection, **item}, ensure_ascii=False, indent=2))
                else:
                    print(f"{args.show}  {item['name']}\n{item['path']}\n")
                    details = item["details"]
                    print(details if isinstance(details, str) else json.dumps(details, ensure_ascii=False, indent=2))
                return
        parser.error(f"Unknown catalog ID {args.show!r}. Browse with -c {collection}.")

    collections = (args.collection,) if args.collection else COLLECTIONS
    matches = find(collections, " ".join(args.query))
    if args.json:
        print(json.dumps(list(matches), ensure_ascii=False, indent=2))
    else:
        for row in matches:
            status = f" ({row['status']})" if "status" in row else ""
            print(f"{row['collection']}/{row['id']}{status}  {row['name']}\n  {row['path']}")


if __name__ == "__main__":
    main()
