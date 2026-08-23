import unittest
import urllib.request
from unittest.mock import patch, MagicMock

from ..sources.federal_agency_rss import FederalAgencyRSSSource

SAMPLE_FEED = b"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>Sample CFPB Newsroom</title>
    <item>
      <title>CFPB Reaches Settlement With Acme Lending for Military Lending Act Violations</title>
      <link>https://www.consumerfinance.gov/about-us/newsroom/acme-settlement</link>
      <description>Consumers eligible for refunds under the settlement.</description>
      <pubDate>Wed, 20 Aug 2026 12:00:00 +0000</pubDate>
      <guid>guid-1</guid>
    </item>
    <item>
      <title>CFPB Releases New Mortgage Data Report</title>
      <link>https://www.consumerfinance.gov/about-us/newsroom/mortgage-data</link>
      <description>Annual HMDA data now available for researchers.</description>
      <pubDate>Tue, 19 Aug 2026 12:00:00 +0000</pubDate>
      <guid>guid-2</guid>
    </item>
    <item>
      <title>CFPB Sues Acme Corp Over Deceptive Fee Practices</title>
      <link>https://www.consumerfinance.gov/about-us/newsroom/sues-acme</link>
      <description>The lawsuit seeks restitution for affected consumers.</description>
      <pubDate>Mon, 18 Aug 2026 12:00:00 +0000</pubDate>
      <guid>guid-3</guid>
    </item>
  </channel>
</rss>
"""


class FederalAgencyRSSSourceTests(unittest.TestCase):

    def _mock_response(self):
        mock = MagicMock()
        mock.__enter__.return_value.read.return_value = SAMPLE_FEED
        return mock

    def test_filters_out_non_settlement_items(self):
        source = FederalAgencyRSSSource("CFPB", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(len(candidates), 1)
        self.assertIn("Acme Lending", candidates[0].case_name)

    def test_excludes_lawsuit_filings_that_merely_seek_restitution(self):
        source = FederalAgencyRSSSource("CFPB", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=10)

        case_names = [c.case_name for c in candidates]
        self.assertTrue(all("Sues Acme" not in name for name in case_names))

    def test_ground_truth_candidates_still_carry_a_review_caveat(self):
        source = FederalAgencyRSSSource("CFPB", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(candidates[0].confidence, "ground_truth")
        self.assertIn("does NOT confirm a public consumer claim form", candidates[0].note)
        self.assertEqual(candidates[0].court, "CFPB")

    def test_source_name_is_derived_from_agency(self):
        source = FederalAgencyRSSSource("CFPB", "https://example.gov/feed")
        self.assertEqual(source.name, "agency_rss_cfpb")

    def test_respects_max_results(self):
        source = FederalAgencyRSSSource("CFPB", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=0)
        self.assertEqual(candidates, [])


if __name__ == "__main__":
    unittest.main()
