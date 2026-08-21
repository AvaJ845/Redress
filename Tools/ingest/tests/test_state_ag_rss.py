import unittest
import urllib.request
from unittest.mock import patch, MagicMock

from ..sources.state_ag_rss import StateAGRSSSource

SAMPLE_FEED = b"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>Sample AG Press Releases</title>
    <item>
      <title>Attorney General Announces $5 Million Settlement With Acme Corp</title>
      <link>https://example.gov/press/acme-settlement</link>
      <description>Consumers eligible for refunds under the settlement.</description>
      <pubDate>Wed, 20 Aug 2026 12:00:00 +0000</pubDate>
      <guid>guid-1</guid>
    </item>
    <item>
      <title>Attorney General Launches New Consumer Protection Website</title>
      <link>https://example.gov/press/new-website</link>
      <description>A new tool to help residents report scams online.</description>
      <pubDate>Tue, 19 Aug 2026 12:00:00 +0000</pubDate>
      <guid>guid-2</guid>
    </item>
    <item>
      <title>Attorney General Files Lawsuit Seeking Restitution From Scam Operator</title>
      <link>https://example.gov/press/files-lawsuit</link>
      <description>The lawsuit seeks refunds for affected consumers.</description>
      <pubDate>Mon, 18 Aug 2026 12:00:00 +0000</pubDate>
      <guid>guid-3</guid>
    </item>
  </channel>
</rss>
"""


class StateAGRSSSourceTests(unittest.TestCase):

    def _mock_response(self):
        mock = MagicMock()
        mock.__enter__.return_value.read.return_value = SAMPLE_FEED
        return mock

    def test_filters_out_non_settlement_items(self):
        source = StateAGRSSSource("Sample", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(len(candidates), 1)
        self.assertIn("Acme Corp", candidates[0].case_name)

    def test_ground_truth_candidates_still_carry_a_review_caveat(self):
        source = StateAGRSSSource("Sample", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=10)

        self.assertEqual(candidates[0].confidence, "ground_truth")
        self.assertIn("does NOT confirm a public consumer claim form", candidates[0].note)

    def test_excludes_lawsuit_filings_that_merely_seek_restitution(self):
        """Regression test: a live run (2026-08-21) matched 'Files Lawsuits
        Against Operators of Illegal Online Casinos' because the description
        mentioned restitution as sought relief, not delivered relief."""
        source = StateAGRSSSource("Sample", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=10)

        case_names = [c.case_name for c in candidates]
        self.assertTrue(all("Files Lawsuit" not in name for name in case_names))
        self.assertEqual(len(candidates), 1)

    def test_respects_max_results(self):
        source = StateAGRSSSource("Sample", "https://example.gov/feed")
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response()):
            candidates = source.fetch(query="", max_results=0)
        self.assertEqual(candidates, [])


if __name__ == "__main__":
    unittest.main()
