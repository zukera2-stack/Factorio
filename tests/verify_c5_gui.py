#!/usr/bin/env python3
"""Read-only EM072-C5 GUI log summarizer. Native GUI screenshots remain mandatory."""
import argparse
import json
import pathlib

def parse(text):
    events = []
    for line in text.splitlines():
        if "EMC5|" not in line:
            continue
        payload = line.split("EMC5|", 1)[1]
        chunks = payload.split("|")
        record = {"event": chunks[0]}
        for chunk in chunks[1:]:
            if "=" in chunk:
                key, value = chunk.split("=", 1)
                record[key] = value
        events.append(record)
    return events

def analyze(text):
    events = parse(text)
    native = [e for e in events if e.get("event") == "gui_open" and e.get("train_id") not in (None, "none")]
    with_helpers = [e for e in native if int(e.get("technical_helpers", "0")) > 0]
    return {
        "status": "COUNTS_OBSERVED_ONLY" if native else "NO_NATIVE_TRAIN_GUI_EVENTS",
        "visual_train_gui_verdict": "UNVERIFIED_REQUIRES_CLIENT_SCREENSHOTS",
        "events_total": len(events),
        "native_gui_train_events": len(native),
        "native_gui_train_events_with_helper": len(with_helpers),
        "observed_cases": sorted({e.get("case", "unknown") for e in native}),
        "helper_present_while_gui_opened": bool(with_helpers),
        "events": native,
        "notice": "A logged GUI opening plus LuaTrain counts does not reveal the pixels or contents of the native train GUI."
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True, help="factorio-current.log from disposable C4+C5 client game")
    parser.add_argument("--output", required=True, help="JSON result path")
    args = parser.parse_args()
    report = analyze(pathlib.Path(args.log).read_text(encoding="utf-8", errors="replace"))
    pathlib.Path(args.output).write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(report["status"] + ": " + str(report["native_gui_train_events"]) + " train GUI opening(s)")
    if not report["native_gui_train_events"]:
        raise SystemExit(2)

if __name__ == "__main__":
    main()
