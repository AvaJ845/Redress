import unittest
import urllib.request
from unittest.mock import patch, MagicMock

from ..sources.courtlistener import CourtListenerSource

SAMPLE_PAGE = {
    "results": [
        {
            "docket_id": 123,
            "caseName": "Smith v. Acme Corp",
            "docket_absolute_url": "/docket/123/smith-v-acme-corp/",
            "court": "cand",
            "dateFiled": "2026-05-01",
            "docketNumber": "1:26-cv-00001",
        },
        {
            "docket_id": 124,
            "caseName": "Jones v. Beta LLC",
            "docket_absolute_url": "/docket/124/jones-v-beta-llc/",
            "court": "nysd",
            "dateFiled": "2026-04-01",
            "docketNumber": "1:26-cv-00002",
        },
    ],
    "next": None,
}


class CourtListenerSourceTests(unittest.TestCase):

    def _mock_response(self, payload):
        mock = MagicMock()
        mock.__enter__.return_value.read.return_value = __import__("json").dumps(payload).encode()
        return mock

    def test_query_includes_a_date_filed_recency_filter(self):
        # Regression test: a docket search with no date bound can eventually
        # paginate into multi-year-old, long-dead dockets. Confirmed live
        # 2026-08-23 that dateFiled:[YYYY-MM-DD TO *] is the real, documented
        # CourtListener syntax for this — not a guessed parameter name.
        source = CourtListenerSource()
        captured_urls = []

        def capturing_urlopen(request, timeout=30):
            captured_urls.append(request.full_url)
            return self._mock_response(SAMPLE_PAGE)

        with patch.object(urllib.request, "urlopen", side_effect=capturing_urlopen):
            source.fetch(query="class action settlement", max_results=5)

        self.assertTrue(captured_urls, "no request was made")
        self.assertIn("dateFiled", captured_urls[0])
        self.assertIn("TO", captured_urls[0])

    def test_candidates_are_always_inferred_confidence(self):
        source = CourtListenerSource()
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response(SAMPLE_PAGE)):
            candidates = source.fetch(query="class action settlement", max_results=5)

        self.assertEqual(len(candidates), 2)
        self.assertTrue(all(c.confidence == "inferred" for c in candidates))

    def test_candidate_fields_map_correctly(self):
        source = CourtListenerSource()
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response(SAMPLE_PAGE)):
            candidates = source.fetch(query="class action settlement", max_results=5)

        first = candidates[0]
        self.assertEqual(first.case_name, "Smith v. Acme Corp")
        self.assertEqual(first.docket_number, "1:26-cv-00001")
        self.assertEqual(first.source_url, "https://www.courtlistener.com/docket/123/smith-v-acme-corp/")

    def test_respects_max_results_within_a_single_page(self):
        source = CourtListenerSource()
        with patch.object(urllib.request, "urlopen", return_value=self._mock_response(SAMPLE_PAGE)):
            candidates = source.fetch(query="class action settlement", max_results=1)

        self.assertEqual(len(candidates), 1)


if __name__ == "__main__":
    unittest.main()
