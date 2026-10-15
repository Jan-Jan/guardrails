#!/usr/bin/env bats
# install.sh at its command line. Every install goes into a skills directory
# under $BATS_TEST_TMPDIR, never the real ~/.claude/skills.

load helpers

setup() {
    root=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
    export CLAUDE_SKILLS_DIR="$BATS_TEST_TMPDIR/skills"
}

# verifies: PR-783b29
@test "install: --copy records the checkout in every copied skill" {
    run sh "$root/install.sh" --copy
    [ "$status" -eq 0 ]
    for skill in "$root"/skills/*/; do
        skill_name=$(basename "$skill")
        source_file="$CLAUDE_SKILLS_DIR/$skill_name/.guardrails-source"
        [ -f "$source_file" ] || { echo "no .guardrails-source in $skill_name"; false; }
        [ "$(wc -l < "$source_file" | tr -d ' ')" = 1 ] ||
            { echo "$source_file is not one line"; cat "$source_file"; false; }
        [ "$(cat "$source_file")" = "$root" ] ||
            { echo "$source_file names $(cat "$source_file"), not $root"; false; }
    done
}

# verifies: PR-783b29
@test "install: a linked install writes nothing into the checkout" {
    run sh "$root/install.sh"
    [ "$status" -eq 0 ]
    for skill in "$root"/skills/*/; do
        skill_name=$(basename "$skill")
        [ -L "$CLAUDE_SKILLS_DIR/$skill_name" ] ||
            { echo "$skill_name is not installed as a symlink"; false; }
        if [ -e "$root/skills/$skill_name/.guardrails-source" ]; then
            echo "the linked install wrote skills/$skill_name/.guardrails-source"
            false
        fi
    done
}
