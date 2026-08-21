import json
import tempfile
import unittest
import urllib.error
import urllib.request
from unittest.mock import MagicMock, patch

from ..freshness import check_seed_file, check_url_freshness


def _mock_response(status=200, body=b"Claim deadline: eligible consumers may file a claim."):
    mock = MagicMock()
    mock.__enter__.return_value.status = status
    mock.__enter__.return_value.read.return_value = body
    return mock


class CheckUrlFreshnessTests(unittest.TestCase):

    def test_reachable_page_with_claims_content_is_fresh(self):
        with patch.object(urllib.request, "urlopen", return_value=_mock_response()):
            result = check_url_freshness("https://example.com/claim")
        self.assertTrue(result.is_reachable)
        self.assertTrue(result.looks_like_claims_content)
        self.assertFalse(result.needs_attention)

    def test_reachable_page_without_claims_content_needs_attention(self):
        with patch.object(urllib.request, "urlopen", return_value=_mock_response(body=b"Welcome to our homepage.")):
            result = check_url_freshness("https://example.com/moved")
        self.assertTrue(result.is_reachable)
        self.assertFalse(result.looks_like_claims_content)
        self.assertTrue(result.needs_attention, "reachable but no claims content should still flag for review")

    def test_404_is_unreachable_and_needs_attention(self):
        error = urllib.error.HTTPError(url="https://example.com/gone", code=404, msg="Not Found",
                                        hdrs=None, fp=None)
        with patch.object(urllib.request, "urlopen", side_effect=error):
            result = check_url_freshness("https://example.com/gone")
        self.assertFalse(result.is_reachable)
        self.assertEqual(result.status_code, 404)
        self.assertTrue(result.needs_attention)

    def test_network_error_is_unreachable_not_a_crash(self):
        with patch.object(urllib.request, "urlopen", side_effect=TimeoutError("timed out")):
            result = check_url_freshness("https://example.com/slow")
        self.assertFalse(result.is_reachable)
        self.assertIsNotNone(result.error)

    def test_empty_or_invalid_url_does_not_attempt_a_request(self):
        result = check_url_freshness("")
        self.assertFalse(result.is_reachable)
        self.assertIn("Not a valid", result.error)

    def test_real_live_check_against_a_known_stable_government_site(self):
        """One real network call, not mocked, to prove this isn't purely
        theoretical. Skips gracefully if offline rather than failing CI."""
        try:
            result = check_url_freshness("https://oag.ca.gov/news")
        except Exception:
            self.skipTest("no network access in this environment")
        if result.error and "Name or service not known" in (result.error or ""):
            self.skipTest("no network access in this environment")
        self.assertTrue(result.is_reachable, f"expected oag.ca.gov to be reachable, got: {result}")


class CheckSeedFileTests(unittest.TestCase):

    def test_flags_placeholder_urls_appropriately(self):
        seed_data = [{
            "id": "test-1",
            "title": "Test Settlement",
            "isSampleData": True,
            "administratorPortalURLString": "https://example.com/sample-claim-portal",
        }]
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(seed_data, f)
            path = f.name

        with patch("Tools.ingest.freshness.check_url_freshness") as mock_check:
            from ..freshness import FreshnessResult
            mock_check.return_value = FreshnessResult(
                url="https://example.com/sample-claim-portal",
                checked_at="2026-08-21T00:00:00Z",
                is_reachable=True,
                status_code=200,
                looks_like_claims_content=True,
            )
            results = check_seed_file(path)

        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["title"], "Test Settlement")
        self.assertTrue(results[0]["isSampleData"])
        self.assertFalse(results[0]["needs_attention"])


if __name__ == "__main__":
    unittest.main()
