#!/bin/sh
# describes: lib.sh: gr_md_files accepts a directory with no *.md
python3 - <<'PY'
s = open('scripts/lib.sh').read()
s = s.replace('    [ "$_n" -gt 0 ] || gr_die "$2 \'$_dir\', which contains no *.md files"\n', '')
open('scripts/lib.sh','w').write(s)
PY
