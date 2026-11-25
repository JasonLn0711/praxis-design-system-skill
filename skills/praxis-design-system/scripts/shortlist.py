"""Compare styles proposed for an exact product in the pinned UI/UX Pro Max database."""

import argparse
import json
import re
import sys

# Both libraries are read-only when this CLI runs from a project directory.
sys.dont_write_bytecode = True
from catalog import UI_DATA, csv_rows, relative, slug

sys.path.insert(0, str(UI_DATA.parent / "scripts"))
from design_system import DesignSystemGenerator
from reasoning_contract import CONDITION_SIGNALS


def comparison(product, *, intents=(), mode=None, low_cost=False):
    engine = DesignSystemGenerator()
    category = product["Product Type"]
    # Use explicit positive intents so upstream's lexical rule matcher never
    # mistakes a negation in a free-form brief for a requested design feature.
    signals = [CONDITION_SIGNALS[f"if_{intent}"][0] for intent in intents]
    if low_cost:
        signals.append("low-end")
    if mode:
        signals.append(f"{mode} mode")
    reasoning = engine._apply_reasoning(category, " ".join(signals))
    if reasoning["is_default"]:
        raise ValueError(f"Missing upstream reasoning profile for {category!r}")
    candidates = [
        ("reasoning", reasoning["style_priority"]),
        ("product primary", re.split(r"\s+\+\s+", product["Primary Style Recommendation"])),
        ("product secondary", product["Secondary Styles"].split(",")),
    ]

    styles = {}
    unresolved = []
    for origin, names in candidates:
        for label in names:
            label = label.strip()
            if not label:
                continue
            style = engine._resolve_style(label)
            if not style:
                unresolved.append({"source": origin, "label": label})
                continue
            key = style["Style ID"]
            if key in styles:
                if origin not in styles[key]["sources"]:
                    styles[key]["sources"].append(origin)
                continue
            excluded = []
            if mode:
                support = style[f"{mode.title()} Mode ✓"]
                if support != "supported":
                    excluded.append(f"{mode} mode is {support}")
            cost = style["Performance"].split("|", 1)[0]
            if low_cost and cost != "cost:low":
                excluded.append(cost)
            styles[key] = {
                "style": f"ui-styles/{key}", "name": style["Style Category"],
                "status": style["Status"], "sources": [origin], "best_for": style["Best For"],
                "avoid_for": style["Do Not Use For"], "performance": style["Performance"],
                "accessibility": style["Accessibility"], "excluded_by": excluded,
            }
    profile = slug(category)
    return {
        "product": category,
        "records": [f"ui-products/{profile}", f"ui-reasoning/{profile}", f"ui-palettes/{profile}"],
        "activated_rules": reasoning["activated_rules"],
        "upstream_considerations": reasoning["constraints"],
        "anti_patterns": reasoning["anti_patterns"],
        "eligible": [row for row in styles.values() if not row["excluded_by"]],
        "excluded": [row for row in styles.values() if row["excluded_by"]],
        "unresolved_source_labels": unresolved,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("product", help="Exact ui-products ID or its full upstream name.")
    parser.add_argument("--intent", action="append", default=[],
                        choices=sorted(name[3:] for name in CONDITION_SIGNALS),
                        help="An explicit positive brief signal. Repeat for additional signals.")
    parser.add_argument("--mode", choices=("light", "dark"),
                        help="Require unconditional catalog support for this color mode.")
    parser.add_argument("--low-cost", action="store_true",
                        help="Keep only styles classified as low rendering cost by upstream.")
    args = parser.parse_args()
    source = UI_DATA / "products.csv"
    key = slug(args.product)
    product = next((r for r in csv_rows(source) if slug(r["Product Type"]) == key), None)
    if product is None:
        parser.error(f"Unknown product {args.product!r}. Search with catalog.py -c ui-products.")
    result = comparison(product, intents=args.intent, mode=args.mode, low_cost=args.low_cost)
    result["product_source"] = relative(source)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
