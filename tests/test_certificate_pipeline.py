from __future__ import annotations

import json
import unittest
from pathlib import Path

from lowdefect_certificate.alpha import (
    alpha_multiple_less_than,
    compare_alpha_multiple_to_int,
    floor_alpha_multiple,
)
from lowdefect_certificate.complexity import solid_numbers_up_to_complexity
from lowdefect_certificate.verifier import (
    TARGET_B_VALUES,
    certificate_success_conditions,
    target_cases,
)


ROOT = Path(__file__).resolve().parents[1]


class AlphaArithmeticTests(unittest.TestCase):
    def test_threshold_arithmetic_is_exact(self) -> None:
        self.assertTrue(alpha_multiple_less_than(46, 5))
        self.assertEqual(floor_alpha_multiple(46), 4)
        self.assertTrue(alpha_multiple_less_than(9, 1))
        self.assertEqual(compare_alpha_multiple_to_int(9, 1), -1)


class SolidNumberTests(unittest.TestCase):
    def test_solids_through_complexity_six(self) -> None:
        self.assertEqual(solid_numbers_up_to_complexity(6), [1, 6, 8, 9])


class TargetCaseTests(unittest.TestCase):
    def test_all_32_near_power_targets_are_present(self) -> None:
        cases = target_cases()
        self.assertEqual(len(cases), 32)
        self.assertEqual({case.m for case in cases}, set(range(49, 57)))
        self.assertEqual({case.b for case in cases}, set(TARGET_B_VALUES))
        self.assertEqual(len({(case.m, case.b, case.n) for case in cases}), 32)


class CoveringArtifactTests(unittest.TestCase):
    def test_s46_degree_bound_when_artifact_exists(self) -> None:
        path = ROOT / "artifacts" / "S_46.json"
        if not path.exists():
            self.skipTest("artifacts/S_46.json has not been generated")
        data = json.loads(path.read_text(encoding="ascii"))
        self.assertEqual(data["threshold_multiple"], 46)
        degrees = [pair["degree"] for pair in data["pairs"]]
        self.assertLessEqual(max(degrees), 4)


class CertificateSuccessGuardTests(unittest.TestCase):
    def assert_success(self, **overrides: object) -> None:
        params = {
            "threshold": 46,
            "pair_count_matches_declared": True,
            "max_degree": 4,
            "target_count": 32,
            "all_excluded": True,
            "survivors_empty": True,
        }
        params.update(overrides)
        self.assertTrue(certificate_success_conditions(**params))

    def assert_failure(self, **overrides: object) -> None:
        params = {
            "threshold": 46,
            "pair_count_matches_declared": True,
            "max_degree": 4,
            "target_count": 32,
            "all_excluded": True,
            "survivors_empty": True,
        }
        params.update(overrides)
        self.assertFalse(certificate_success_conditions(**params))

    def test_certificate_success_requires_all_guards(self) -> None:
        self.assert_success()
        self.assert_failure(threshold=45)
        self.assert_failure(pair_count_matches_declared=False)
        self.assert_failure(max_degree=5)
        self.assert_failure(max_degree=None)
        self.assert_failure(target_count=31)
        self.assert_failure(all_excluded=False)
        self.assert_failure(survivors_empty=False)


if __name__ == "__main__":
    unittest.main()
