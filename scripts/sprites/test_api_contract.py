import tempfile
import unittest
from pathlib import Path
from api_contract import verify
from pipeline import QAError, run

class ContractTests(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.out=Path(t.name)/"demo"
        run("demo",None,self.out)

    def test_contract_pass(self):
        report=verify(self.out)
        self.assertEqual(report["result"],"offline_api_contract_passed_not_game_verified")
        self.assertFalse(report["factorio_data_stage_loaded"])
        self.assertFalse(report["docs_version_matches_target"])

    def test_tampered_lua_rejected(self):
        path=self.out/"prototype-snippet.lua"
        path.write_text(path.read_text().replace("direction_count = 1","direction_count = 64"))
        with self.assertRaisesRegex(QAError,"schema"):
            verify(self.out)

    def test_tampered_png_rejected(self):
        path=self.out/"ready/pole-hr.png"
        with path.open("ab") as f:
            f.write(b"not-original")
        with self.assertRaisesRegex(QAError,"hash mismatch"):
            verify(self.out)

    def test_false_game_test_claim_rejected(self):
        import json
        path=self.out/"report.json"
        data=json.loads(path.read_text())
        data["game_test"]=True
        path.write_text(json.dumps(data))
        with self.assertRaisesRegex(QAError,"game test"):
            verify(self.out)

if __name__=="__main__":
    unittest.main(verbosity=2)
