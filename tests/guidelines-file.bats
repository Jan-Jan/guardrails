#!/usr/bin/env bats
# guidelines-file.sh: the one guidelines file that governs each path.

load helpers

setup() {
    make_fixture_repo
    mkdir -p .guardrails/templates
    printf '# Test guidelines (installed default)\n' > .guardrails/templates/TEST_GUIDELINES.md
}

write_root_guidelines() {
    printf '# Test guidelines (project)\n' > docs/TEST_GUIDELINES.md
}

# Written as tests/check-units.bats writes a manifest.
write_units_manifest() {
    mkdir -p apps/pump/docs apps/ui vendor
    cat > .guardrails/units.yaml <<'MANIFEST'
units:
  - apps/pump
  - apps/ui
not_a_unit:
  - vendor
MANIFEST
    printf '# Test guidelines (pump)\n' > apps/pump/docs/TEST_GUIDELINES.md
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: with no project file the installed default governs" {
    run sh .guardrails/scripts/guidelines-file.sh TEST src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/TEST_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
}

# verifies: D3, D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: a root docs/TEST_GUIDELINES.md governs over the default" {
    write_root_guidelines
    run sh .guardrails/scripts/guidelines-file.sh TEST src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "docs/TEST_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
}

# verifies: D3, D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: a unit's file replaces the root's for that unit's paths only" {
    write_units_manifest
    write_root_guidelines
    run sh .guardrails/scripts/guidelines-file.sh TEST apps/pump/x.c apps/ui/y.ts apps/pump/z.c vendor/v.c
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected="apps/pump/docs/TEST_GUIDELINES.md: apps/pump/x.c apps/pump/z.c
docs/TEST_GUIDELINES.md: apps/ui/y.ts vendor/v.c"
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: D3, D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: a unit with no file and no root file falls to the installed default" {
    write_units_manifest
    run sh .guardrails/scripts/guidelines-file.sh TEST apps/ui/y.ts
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/TEST_GUIDELINES.md: apps/ui/y.ts" ] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: a lower-case test_guidelines.md is not the project file, on any filesystem" {
    printf '# lower case\n' > docs/test_guidelines.md
    run sh .guardrails/scripts/guidelines-file.sh TEST src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/TEST_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md); D4 (docs/plans/2026-10-13-code-guidelines.md); D2 (docs/plans/2026-10-14-architecture-guidelines.md)
@test "guidelines-file: an unknown kind is exit 2, naming the known kinds" {
    run sh .guardrails/scripts/guidelines-file.sh NO_SUCH_KIND src/a.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"unknown kind: NO_SUCH_KIND (known: TEST CODE ARCHITECTURE)"* ]] || { echo "$output"; false; }
}

# verifies: D4, D5 (docs/plans/2026-10-13-code-guidelines.md); D3, D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: CODE picks the unit's, the root's or the installed default file, as TEST does" {
    printf '# Code guidelines (installed default)\n' > .guardrails/templates/CODE_GUIDELINES.md
    run sh .guardrails/scripts/guidelines-file.sh CODE src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/CODE_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
    write_units_manifest
    printf '# Code guidelines (project)\n' > docs/CODE_GUIDELINES.md
    printf '# Code guidelines (pump)\n' > apps/pump/docs/CODE_GUIDELINES.md
    run sh .guardrails/scripts/guidelines-file.sh CODE apps/pump/x.c apps/ui/y.ts vendor/v.c
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected="apps/pump/docs/CODE_GUIDELINES.md: apps/pump/x.c
docs/CODE_GUIDELINES.md: apps/ui/y.ts vendor/v.c"
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: D2, D7 (docs/plans/2026-10-14-architecture-guidelines.md)
@test "guidelines-file: ARCHITECTURE picks the unit's, the root's or the installed default file, as TEST does" {
    printf '# Architecture guidelines (installed default)\n' > .guardrails/templates/ARCHITECTURE_GUIDELINES.md
    run sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/ARCHITECTURE_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
    write_units_manifest
    printf '# Architecture guidelines (project)\n' > docs/ARCHITECTURE_GUIDELINES.md
    printf '# Architecture guidelines (pump)\n' > apps/pump/docs/ARCHITECTURE_GUIDELINES.md
    run sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE apps/pump/x.c apps/ui/y.ts vendor/v.c
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected="apps/pump/docs/ARCHITECTURE_GUIDELINES.md: apps/pump/x.c
docs/ARCHITECTURE_GUIDELINES.md: apps/ui/y.ts vendor/v.c"
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: D4 (docs/plans/2026-10-13-code-guidelines.md)
@test "guidelines-file: one kind's project file never governs another kind" {
    printf '# Code guidelines (installed default)\n' > .guardrails/templates/CODE_GUIDELINES.md
    write_root_guidelines
    run sh .guardrails/scripts/guidelines-file.sh CODE src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/CODE_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
}

# verifies: D4 (docs/plans/2026-10-13-code-guidelines.md)
@test "guidelines-file: a missing CODE default is exit 2 though the TEST default is installed" {
    run sh .guardrails/scripts/guidelines-file.sh CODE src/a.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"no installed default"* ]] || { echo "$output"; false; }
    [[ "$output" == *"CODE_GUIDELINES.md"* ]] || { echo "$output"; false; }
}

# verifies: D2 (docs/plans/2026-10-14-architecture-guidelines.md)
@test "guidelines-file: a missing ARCHITECTURE default is exit 2 though the TEST default is installed" {
    run sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE src/a.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"no installed default"* ]] || { echo "$output"; false; }
    [[ "$output" == *"ARCHITECTURE_GUIDELINES.md"* ]] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: no path is exit 2 with the usage line" {
    run sh .guardrails/scripts/guidelines-file.sh TEST
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"usage"* ]] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: an absolute path or a path with whitespace is exit 2, naming it" {
    run sh .guardrails/scripts/guidelines-file.sh TEST /etc/passwd
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"/etc/passwd"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/guidelines-file.sh TEST 'src/a b.sh'
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"src/a b.sh"* ]] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: a missing installed default is exit 2 even where a project file exists" {
    write_root_guidelines
    rm .guardrails/templates/TEST_GUIDELINES.md
    run sh .guardrails/scripts/guidelines-file.sh TEST src/a.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"no installed default"* ]] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: files print in first-needed order and paths in argument order, unsorted" {
    write_units_manifest
    write_root_guidelines
    run sh .guardrails/scripts/guidelines-file.sh TEST vendor/v.c apps/ui/y.ts apps/pump/z.c apps/pump/x.c
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected="docs/TEST_GUIDELINES.md: vendor/v.c apps/ui/y.ts
apps/pump/docs/TEST_GUIDELINES.md: apps/pump/z.c apps/pump/x.c"
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: an empty path is exit 2 with the usage line" {
    run sh .guardrails/scripts/guidelines-file.sh TEST src/a.sh ''
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"empty path"* ]] || { echo "$output"; false; }
    [[ "$output" == *"usage"* ]] || { echo "$output"; false; }
}

# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: an exported CDPATH does not change where it finds itself" {
    CDPATH="$PWD" run sh .guardrails/scripts/guidelines-file.sh TEST src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/TEST_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
}
