import unittest
from unittest.mock import patch

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

    def test_finds_and_returns_only_open_cases(self):
        source = VeritaSource()
        with patch("Tools.ingest.sources.verita._fetch", side_effect=fake_fetch), \
             patch("Tools.ingest.sources.verita.time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(len(candidates), 1, "closed case and no-deadline page must both be excluded")
        self.assertEqual(candidates[0].source_id, "open-case-settlement")

    def test_open_case_is_tagged_ground_truth(self):
        source = VeritaSource()
        with patch("Tools.ingest.sources.verita._fetch", side_effect=fake_fetch), \
             patch("Tools.ingest.sources.verita.time.sleep"):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(candidates[0].confidence, "ground_truth")
        self.assertIn("15 Nov 2099", candidates[0].note)

    def test_closed_case_is_genuinely_excluded_not_just_deprioritized(self):
        source = VeritaSource()
        with patch("Tools.ingest.sources.verita._fetch", side_effect=fake_fetch), \
             patch("Tools.ingest.sources.verita.time.sleep"):
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

        source = VeritaSource()
        with patch("Tools.ingest.sources.verita._fetch", side_effect=fetch_without_settlement_sitemap):
            candidates = source.fetch(query="", max_results=10)
        self.assertEqual(candidates, [])


if __name__ == "__main__":
    unittest.main()
