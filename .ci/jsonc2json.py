#!/usr/bin/env python3
"""Convert JSONC (JSON with comments and trailing commas) to strict JSON.

Zed ships its settings as JSONC, which jq cannot read. A regex that strips
`//` to end-of-line corrupts any string containing `//` — a URL value such as
`"https://example.com"` would be truncated mid-string and produce a confusing
parse error further down. This walks the input instead, so comment stripping
never touches string contents.

Reads from stdin, writes strict JSON to stdout.
"""

import json
import re
import sys


def strip_comments(text: str) -> str:
    out = []
    i = 0
    n = len(text)
    in_string = False
    escaped = False

    while i < n:
        ch = text[i]

        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
        else:
            out.append(ch)
            i += 1

    return "".join(out)


def main() -> int:
    raw = sys.stdin.read()
    body = strip_comments(raw)
    # Trailing commas before a closing brace or bracket.
    body = re.sub(r",(\s*[}\]])", r"\1", body)
    try:
        json.dump(json.loads(body), sys.stdout)
    except json.JSONDecodeError as exc:
        print(f"jsonc2json: invalid JSONC: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
