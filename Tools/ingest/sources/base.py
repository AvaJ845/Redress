"""
The contract every data source plugs into. Adding a new source means
writing one class here — the engine doesn't change.
"""

from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class Candidate:
    """One possible settlement/claim lead, before any publication decision."""

    source_name: str          # e.g. "courtlistener", "ftc", "sec_litigation"
    source_id: str            # stable ID within that source, for dedup/provenance
    case_name: str
    source_url: str
    court: Optional[str] = None
    date_filed: Optional[str] = None
    docket_number: Optional[str] = None

    # The core distinction this engine exists to make:
    #   "ground_truth"  — the source IS the authority (e.g. a government
    #                      agency's own announcement of its own settlement).
    #                      Still needs automated field-validation, not human
    #                      judgment about whether it's real.
    #   "inferred"       — the source is evidence a case exists, not proof a
    #                      claims window is open (e.g. generic docket search).
    #                      Needs human review before ever reaching users.
    confidence: str = "inferred"
    note: str = ""
    raw: dict = field(default_factory=dict)

    def requires_human_review(self) -> bool:
        return self.confidence != "ground_truth"


class SettlementSource:
    """Base class for a pluggable data source. Subclass and implement fetch()."""

    name = "unnamed-source"

    def fetch(self, query: str, max_results: int) -> List[Candidate]:
        raise NotImplementedError
