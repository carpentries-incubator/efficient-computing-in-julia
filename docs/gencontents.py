from pathlib import Path
import json
import re
import io
from contextlib import contextmanager


def write_weave_html(files):
    data = {"call": [
        {   "template": "pandoc",
            "collect": "html",
            "args": { "basename": [p.stem for p in files] }
        }]}
    json.dump(data, open("docs/weave_html.json", "w"))


contents_header = """
<!-- automatically generated from docs/gencontents.py
     editing this file is futile -->
"""


@contextmanager
def write_if_changed(filename):
    out = io.StringIO()
    yield out
    content = out.getvalue()
    if content != open(filename, "r").read():
        open(filename, "w").write(content)


def write_contents(files):
    with write_if_changed("docs/contents.md") as out:
        print(contents_header, file=out)
        for i, fn in enumerate(files):
            with open(fn, "r") as f:
                for line in f:
                    if m := re.match(r"^title:(.*)$", line):
                        title = m.group(1).strip(" '\"")
                        print(f"{i+1}. [{title}]({fn.name})", file=out)


if __name__ == "__main__":
    files = list(Path("episodes").glob("*.md"))
    write_weave_html(files)
    write_contents(files)
