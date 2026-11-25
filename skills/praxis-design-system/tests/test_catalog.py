"""Regression checks for source fidelity and brief-driven style selection."""

import csv
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from catalog import COLLECTIONS, DIAGRAMS, UI_DATA, UPSTREAM
from shortlist import comparison


def run_cli(script, *args, check=True):
    return subprocess.run(
        [sys.executable, "-B", ROOT / "scripts" / script, *args],
        cwd=tempfile.gettempdir(), capture_output=True, text=True, check=check,
    )


def show(identifier):
    return json.loads(run_cli("catalog.py", "--show", identifier, "--json").stdout)


class CatalogTests(unittest.TestCase):
    def test_every_record_has_a_unique_id_and_a_readable_source(self):
        for collection, reader in COLLECTIONS.items():
            with self.subTest(collection=collection):
                seen = set()
                for item in reader():
                    key = item["id"]
                    self.assertTrue(key and key not in seen, key)
                    seen.add(key)
                    self.assertTrue((ROOT / item["path"]).is_file(), item["path"])
                    self.assertTrue(item["details"], key)
                self.assertTrue(seen)

    def test_original_styles_keep_every_source_field_and_status(self):
        actual = {r["id"]: r for r in COLLECTIONS["ui-styles"]()}
        with (UI_DATA / "styles.csv").open(newline="", encoding="utf-8-sig") as stream:
            expected = list(csv.DictReader(stream))
        self.assertEqual(len(actual), len(expected))
        for row in expected:
            record = actual[row["Style ID"]]
            self.assertEqual(record["details"], row)
            self.assertEqual(record["status"], row["Status"])
        sample = expected[0]
        self.assertEqual(show("ui-styles/" + sample["Style ID"])["details"], sample)

    def test_each_diagram_links_to_its_type_guide_and_three_artifacts(self):
        docs = DIAGRAMS / "skills/diagram-design/references"
        rows = list(COLLECTIONS["diagrams"]())
        self.assertEqual({r["id"] for r in rows}, {p.stem[5:] for p in docs.glob("type-*.md")})
        for item in rows:
            details = item["details"]
            self.assertEqual(details["guidance"], (ROOT / details["guide"]).read_text(encoding="utf-8"))
            self.assertEqual(set(details["variants"]), {"light", "dark", "full"})
            for path in details["variants"].values():
                self.assertTrue((ROOT / path).is_file(), path)

    def test_web_guides_are_exact_and_failed_lookup_is_explicit(self):
        sources = UPSTREAM / "modern-web-guidance/skills/modern-web-guidance/guides"
        actual = {r["id"]: r["details"] for r in COLLECTIONS["modern-web"]()}
        expected = {p.stem: p.read_text(encoding="utf-8") for p in sources.rglob("*.md")}
        self.assertEqual(actual, expected)
        self.assertEqual(show("modern-web/light-dismiss-a-dialog")["details"], expected["light-dismiss-a-dialog"])
        result = run_cli("catalog.py", "--show", "diagrams/missing-key", check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_brief_rules_and_filters_are_reproducible_and_explain_exclusions(self):
        args = ("museum-gallery", "--mode", "light", "--low-cost")
        result = run_cli("shortlist.py", *args).stdout
        self.assertEqual(result, run_cli("shortlist.py", *args).stdout)
        shortlist = json.loads(result)
        excluded = {row["style"]: row for row in shortlist["excluded"]}
        self.assertIn("cost:high", excluded["ui-styles/3d-and-hyperrealism"]["excluded_by"])
        self.assertTrue(all(r["performance"].startswith("cost:low|") for r in shortlist["eligible"]))
        self.assertNotIn("ui-styles/3d-and-hyperrealism", [r["style"] for r in shortlist["eligible"]])
        research = json.loads(run_cli("shortlist.py", "research-lab-university-department",
                                      "--intent", "trust_needed").stdout)
        self.assertIn("if_trust_needed", [r["condition"] for r in research["activated_rules"]])

    def test_profiles_resolve_without_guessing_or_silent_generic_fallback(self):
        ids = {row["id"] for row in COLLECTIONS["ui-styles"]()}
        for product in COLLECTIONS["ui-products"]():
            with self.subTest(product=product["id"]):
                result = comparison(product["details"])
                self.assertEqual(result["unresolved_source_labels"], [])
                self.assertTrue(result["eligible"])
                for candidate in result["eligible"]:
                    self.assertIn(candidate["style"].split("/", 1)[1], ids)
                    self.assertNotEqual(candidate["status"], "deprecated")
        unknown = run_cli("shortlist.py", "not-a-pinned-profile", check=False)
        self.assertNotEqual(unknown.returncode, 0)
        self.assertFalse(unknown.stdout.strip())


if __name__ == "__main__":
    unittest.main()
