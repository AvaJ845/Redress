import unittest
from typing import List

from ..engine import run
from ..sources.base import Candidate, SettlementSource


class WorkingSource(SettlementSource):
    name = "working"

    def fetch(self, query: str, max_results: int) -> List[Candidate]:
        return [
            Candidate(source_name=self.name, source_id="1", case_name="Smith v. Acme Corp",
                      source_url="https://example.com/1", docket_number="1:26-cv-00001"),
        ]


class BrokenSource(SettlementSource):
    name = "broken"

    def fetch(self, query: str, max_results: int) -> List[Candidate]:
        raise RuntimeError("simulated network failure")


class DuplicateSource(SettlementSource):
    name = "duplicate"

    def fetch(self, query: str, max_results: int) -> List[Candidate]:
        return [
            Candidate(source_name=self.name, source_id="dup-1", case_name="Smith v. Acme Corp",
                      source_url="https://example.com/dup", docket_number="1:26-cv-00001",
                      confidence="ground_truth"),
        ]


class EngineResilienceTests(unittest.TestCase):

    def test_one_source_failing_does_not_break_the_run(self):
        results = run([WorkingSource(), BrokenSource()], query="test", max_results_per_source=5)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0].source_name, "working")

    def test_all_sources_failing_returns_empty_not_crash(self):
        results = run([BrokenSource(), BrokenSource()], query="test", max_results_per_source=5)
        self.assertEqual(results, [])

    def test_same_case_from_two_sources_deduplicates(self):
        results = run([WorkingSource(), DuplicateSource()], query="test", max_results_per_source=5)
        self.assertEqual(len(results), 1, "same case_name+docket from two sources should merge to one")

    def test_dedup_prefers_ground_truth_over_inferred(self):
        results = run([WorkingSource(), DuplicateSource()], query="test", max_results_per_source=5)
        self.assertEqual(results[0].confidence, "ground_truth")

    def test_requires_human_review_flag(self):
        inferred = Candidate(source_name="x", source_id="1", case_name="A", source_url="u")
        ground_truth = Candidate(source_name="x", source_id="2", case_name="B", source_url="u",
                                  confidence="ground_truth")
        self.assertTrue(inferred.requires_human_review())
        self.assertFalse(ground_truth.requires_human_review())


if __name__ == "__main__":
    unittest.main()
