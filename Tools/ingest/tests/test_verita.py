import json
import os
import shutil
import tempfile
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

from ..sources import verita
from ..sources.verita import VeritaSource

SITEMAP_INDEX = """<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap><loc>https://veritaglobal.com/post-sitemap.xml</loc></sitemap>
  <sitemap><loc>https://veritaglobal.com/mt_settlement_case-sitemap.xml</loc></sitemap>
</sitemapindex>
"""

CASE_SITEMAP = """<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://veritaglobal.com/settlement-case/open-case-settlement/</loc></url>
  <url><loc>https://veritaglobal.com/settlement-case/closed-case-settlement/</loc></url>
  <url><loc>https://veritaglobal.com/settlement-case/no-deadline-page/</loc></url>
</urlset>
"""

PAGES = {
    "https://veritaglobal.com/settlement-case/open-case-settlement/":
        "<html><body><p>Claim deadline: 15 Nov 2099</p></body></html>",
    "https://veritaglobal.com/settlement-case/closed-case-settlement/":
        "<html><body><p>Claim deadline: 01 Jan 2020</p></body></html>",
    "https://veritaglobal.com/settlement-case/no-deadline-page/":
        "<html><body><p>This page has no deadline text at all.</p></body></html>",
}


def fake_fetch(url):
    if "sitemap_index" in url:
        return SITEMAP_INDEX
    if "mt_settlement_case-sitemap" in url:
        return CASE_SITEMAP
    return PAGES[url]


class VeritaSourceTests(unittest.TestCase):

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.state_path = os.path.join(self._tmpdir, "verita_seen.json")

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_finds_and_returns_only_open_cases(self):
        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fake_fetch), \
             patch("time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(len(candidates), 1, "closed case and no-deadline page must both be excluded")
        self.assertEqual(candidates[0].source_id, "open-case-settlement")

    def test_open_case_is_tagged_ground_truth(self):
        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fake_fetch), \
             patch("time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(candidates[0].confidence, "ground_truth")
        self.assertIn("15 Nov 2099", candidates[0].note)

    def test_closed_case_is_genuinely_excluded_not_just_deprioritized(self):
        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fake_fetch), \
             patch("time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        ids = [c.source_id for c in candidates]
        self.assertNotIn("closed-case-settlement", ids)

    def test_missing_settlement_sitemap_returns_empty_not_crash(self):
        def fetch_without_settlement_sitemap(url):
            if "sitemap_index" in url:
                return """<?xml version="1.0"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
                    <sitemap><loc>https://veritaglobal.com/post-sitemap.xml</loc></sitemap>
                </sitemapindex>"""
            raise AssertionError("should not fetch further if no settlement sitemap found")

        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fetch_without_settlement_sitemap):
            candidates = source.fetch(query="", max_results=10)
        self.assertEqual(candidates, [])

    def test_unchecked_pages_are_prioritized_over_already_checked_ones(self):
        # Pre-seed state as if two of the three pages were already checked
        # in an earlier run, leaving only "open-case-settlement" unseen.
        with open(self.state_path, "w") as f:
            json.dump({
                "https://veritaglobal.com/settlement-case/closed-case-settlement/":
                    {"checked_at": "2026-01-01T00:00:00+00:00", "deadline": "01 Jan 2020"},
                "https://veritaglobal.com/settlement-case/no-deadline-page/":
                    {"checked_at": "2026-01-01T00:00:00+00:00", "deadline": None},
            }, f)

        fetch_log = []

        def counting_fetch(url):
            fetch_log.append(url)
            return fake_fetch(url)

        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=counting_fetch), \
             patch("time.sleep"):
            candidates = source.fetch(query="", max_results=1)

        page_fetches = [u for u in fetch_log if "/settlement-case/" in u]
        self.assertEqual(
            page_fetches,
            ["https://veritaglobal.com/settlement-case/open-case-settlement/"],
            "the one never-checked page should be fetched before either "
            "already-checked page, and satisfying max_results=1 from the "
            "unseen pool alone should mean the already-checked pages are "
            "never re-fetched at all",
        )
        self.assertEqual(len(candidates), 1)
        self.assertEqual(candidates[0].source_id, "open-case-settlement")

    def test_state_file_persists_between_source_instances(self):
        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fake_fetch), \
             patch("time.sleep"):
            source.fetch(query="", max_results=10)

        with open(self.state_path) as f:
            state = json.load(f)

        self.assertEqual(
            set(state.keys()),
            {
                "https://veritaglobal.com/settlement-case/open-case-settlement/",
                "https://veritaglobal.com/settlement-case/closed-case-settlement/",
                "https://veritaglobal.com/settlement-case/no-deadline-page/",
            },
        )
        self.assertEqual(
            state["https://veritaglobal.com/settlement-case/open-case-settlement/"]["deadline"],
            "15 Nov 2099",
        )
        self.assertIsNone(
            state["https://veritaglobal.com/settlement-case/no-deadline-page/"]["deadline"]
        )

    def test_case_name_uses_real_page_title_when_present(self):
        # Regression test: deriving case_name from the URL slug mangles
        # acronyms — "toyota-ic-forklift..." .title()-cases to "Toyota Ic
        # Forklift...", not the real "Toyota IC Forklift..." the
        # administrator's own <title> tag states. Confirmed live 2026-08-23
        # against the real page.
        titled_sitemap = """<?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://veritaglobal.com/settlement-case/toyota-ic-forklift-class-action-settlement/</loc></url>
        </urlset>
        """
        titled_page = (
            "<html><head><title>Toyota IC Forklift Class Action Settlement | Verita Global</title></head>"
            "<body><p>Claim deadline: 22 Sep 2099</p></body></html>"
        )

        def fetch_with_title(url):
            if "sitemap_index" in url:
                return SITEMAP_INDEX
            if "mt_settlement_case-sitemap" in url:
                return titled_sitemap
            return titled_page

        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fetch_with_title), \
             patch("time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(candidates[0].case_name, "Toyota IC Forklift Class Action Settlement")

    def test_a_deadline_of_today_is_not_treated_as_already_closed(self):
        # Regression test: comparing a midnight-UTC deadline directly
        # against datetime.now() (which carries the current time-of-day)
        # meant a settlement whose deadline is literally today was
        # discarded as "already closed" for nearly the whole day — real
        # settlements were silently dropped before ever reaching
        # leads.json for human review. Must compare calendar dates.
        today_str = datetime.now(timezone.utc).strftime("%d %b %Y")
        sitemap = """<?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://veritaglobal.com/settlement-case/due-today-settlement/</loc></url>
        </urlset>
        """
        page = f"<html><body><p>Claim deadline: {today_str}</p></body></html>"

        def fetch_due_today(url):
            if "sitemap_index" in url:
                return SITEMAP_INDEX
            if "mt_settlement_case-sitemap" in url:
                return sitemap
            return page

        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fetch_due_today), \
             patch("time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(len(candidates), 1, "a deadline of today must still count as open, not already closed")
        self.assertEqual(candidates[0].source_id, "due-today-settlement")

    def test_case_name_falls_back_to_slug_when_title_tag_missing(self):
        # Existing fixture pages have no <title> tag at all — confirms the
        # fallback still works rather than dropping the candidate.
        source = VeritaSource(state_path=self.state_path)
        with patch.object(verita, "_fetch", side_effect=fake_fetch), \
             patch("time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(candidates[0].case_name, "Open Case Settlement")


if __name__ == "__main__":
    unittest.main()
