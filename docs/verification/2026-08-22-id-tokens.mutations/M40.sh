#!/bin/sh
# describes: finalize-docs.sh: the rename loop runs in a pipeline subshell again
python3 - <<'PY'
s = open('scripts/finalize-docs.sh').read()
old = """for line in $renames; do
    [ -n "$line" ] || continue
    f=${line%% *}
    target=${line#* }
    [ ! -e "$target" ] || gr_die "rename target already exists: $target"
    git mv "$f" "$target" 2>/dev/null || mv "$f" "$target" || \\
        gr_die "rename failed: $f -> $target"
done"""
new = """printf '%s\\n' "$renames" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    f=${line%% *}
    target=${line#* }
    [ ! -e "$target" ] || gr_die "rename target already exists: $target"
    git mv "$f" "$target" 2>/dev/null || mv "$f" "$target" || \\
        gr_die "rename failed: $f -> $target"
done"""
assert old in s
open('scripts/finalize-docs.sh','w').write(s.replace(old, new))
PY
