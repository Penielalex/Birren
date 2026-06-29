"""Re-parse all messages in sms_logs/*.md and print coverage stats."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

# Import parser via subprocess-friendly duplicate: run dart test instead.
# This script parses md structure only and shells out to dart for validation.

import subprocess


def parse_md(path: Path):
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    parts = re.split(r"\n---\n", text)
    msgs = []
    bank = re.search(r"# (\w+) SMS Log", text)
    bank_name = bank.group(1) if bank else path.stem.replace("_sms_log", "")
    for part in parts:
        if "## Message" not in part:
            continue
        body_m = re.search(r"```text\n(.*?)```", part, re.S)
        if not body_m:
            continue
        msgs.append({"bank": bank_name, "body": body_m.group(1).strip()})
    return msgs


def main():
    dart_check = ROOT / "scripts" / "validate_sms_parser.dart"
    result = subprocess.run(
        ["dart", "run", str(dart_check)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
