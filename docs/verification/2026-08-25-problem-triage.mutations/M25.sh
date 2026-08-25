#!/bin/sh
# describes: check-trace: the front-matter skip is restored to the triage scan (review BLOCKING 1)
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old_frag = '"$GR_AWK_ITEM_BLOCK$GR_AWK_CIVIL"'
new_frag = '"$GR_AWK_ITEM_BLOCK$GR_AWK_CIVIL$GR_AWK_FRONT_MATTER"'
old_line = '''            { line = $0; sub(/\\r$/, "", line) }
            gr_block_closes(line) {
                gr_prflush()'''
new_line = '''            FNR == NR { gr_fm_scan($0, FNR); next }
            gr_fm_skip(FNR) { next }
            { line = $0; sub(/\\r$/, "", line) }
            gr_block_closes(line) {
                gr_prflush()'''
old_args = """        ' "$f" || gr_die "problem-report scan failed on $f\""""
new_args = """        ' "$f" "$f" || gr_die "problem-report scan failed on $f\""""
old_begin = '''                gr_block_init("PR", body)
                gr_date_ok(today)'''
new_begin = '''                gr_block_init("PR", body)
                gr_fm_reset()
                gr_date_ok(today)'''
for o in (old_frag, old_line, old_args, old_begin):
    assert s.count(o) == 1, "mutation did not apply: %d matches for %r" % (s.count(o), o[:40])
s = s.replace(old_frag, new_frag).replace(old_line, new_line)
s = s.replace(old_args, new_args).replace(old_begin, new_begin)
open(p, 'w').write(s)
PY
