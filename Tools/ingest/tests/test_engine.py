import unittest
from typing import List

from ..engine import merge_leads, run
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


class MergeLeadsTests(unittest.TestCase):
    """Regression coverage for the leads.json overwrite bug (2026-08-23):
    every run used to fully replace the file, silently destroying any
    real candidate a human hadn't reviewed yet the moment it dropped out
    of a source's fetch window."""

    def test_a_lead_not_refound_this_run_is_not_dropped(self):
        existing = [{"case_name": "Smith v. Acme Corp", "docket_number": "1:26-cv-00001", "status": "lead-needs-review"}]
        merged = merge_leads(existing, new_records=[], now_iso="2026-08-23T00:00:00+00:00")

        self.assertEqual(len(merged), 1, "a lead missing from this run's fetch must still survive")
        self.assertEqual(merged[0]["case_name"], "Smith v. Acme Corp")

    def test_a_genuinely_new_lead_is_added(self):
        existing = [{"case_name": "Smith v. Acme Corp", "docket_number": "1:26-cv-00001", "status": "lead-needs-review"}]
        new = [{"case_name": "Jones v. Beta LLC", "docket_number": "1:26-cv-00002", "status": "lead-needs-review"}]
        merged = merge_leads(existing, new, now_iso="2026-08-23T00:00:00+00:00")

        self.assertEqual(len(merged), 2)
        case_names = {r["case_name"] for r in merged}
        self.assertEqual(case_names, {"Smith v. Acme Corp", "Jones v. Beta LLC"})

    def test_a_re_found_lead_updates_in_place_not_duplicated(self):
        existing = [{"case_name": "Smith v. Acme Corp", "docket_number": "1:26-cv-00001",
                     "status": "lead-needs-review", "first_seen_at": "2026-08-01T00:00:00+00:00"}]
        new = [{"case_name": "Smith v. Acme Corp", "docket_number": "1:26-cv-00001",
                "status": "lead-needs-review"}]
        merged = merge_leads(existing, new, now_iso="2026-08-23T00:00:00+00:00")

        self.assertEqual(len(merged), 1, "the same lead found again must update, not duplicate")

    def test_first_seen_at_is_preserved_across_runs(self):
        existing = [{"case_name": "Smith v. Acme Corp", "docket_number": "1:26-cv-00001",
                     "status": "lead-needs-review", "first_seen_at": "2026-08-01T00:00:00+00:00"}]
        new = [{"case_name": "Smith v. Acme Corp", "docket_number": "1:26-cv-00001",
                "status": "lead-needs-review"}]
        merged = merge_leads(existing, new, now_iso="2026-08-23T00:00:00+00:00")

        self.assertEqual(merged[0]["first_seen_at"], "2026-08-01T00:00:00+00:00",
                          "first_seen_at must not reset just because the lead was found again")
        self.assertEqual(merged[0]["last_seen_at"], "2026-08-23T00:00:00+00:00")

    def test_brand_new_lead_gets_matching_first_and_last_seen(self):
        new = [{"case_name": "Jones v. Beta LLC", "docket_number": "1:26-cv-00002", "status": "lead-needs-review"}]
        merged = merge_leads(existing_records=[], new_records=new, now_iso="2026-08-23T00:00:00+00:00")

        self.assertEqual(merged[0]["first_seen_at"], "2026-08-23T00:00:00+00:00")
        self.assertEqual(merged[0]["last_seen_at"], "2026-08-23T00:00:00+00:00")

    def test_existing_record_missing_timestamps_is_backfilled_not_left_blank(self):
        # Regression test: a record written before first_seen_at/
        # last_seen_at existed (or by any other path) must not stay
        # permanently missing them just because no source happens to
        # re-find that exact case again this run — confirmed live in
        # leads.json, where exactly this happened to one Verita record.
        existing = [{"case_name": "Smith v. Acme Corp", "docket_number": "1:26-cv-00001",
                     "status": "lead-needs-review"}]
        merged = merge_leads(existing, new_records=[], now_iso="2026-08-23T00:00:00+00:00")

        self.assertEqual(merged[0]["first_seen_at"], "2026-08-23T00:00:00+00:00")
        self.assertEqual(merged[0]["last_seen_at"], "2026-08-23T00:00:00+00:00")


if __name__ == "__main__":
    unittest.main()
