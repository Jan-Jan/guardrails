#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-signing.sh [--strict] [REV_RANGE]
# check-signing.sh --setup
#
# Verifies commit signatures. Default scope: HEAD only; pass a rev range
# (e.g. main..feature) to check every commit in it.
#
#   pass            — signature verifies against trusted signers (%G? = G)
#   WARN-UNVERIFIED — signature present but untrusted/unverifiable (%G? = U
#                     or E, e.g. no gpg.ssh.allowedSignersFile); passes
#                     unless --strict
#   UNVERIFIED      — same, under --strict: fails
#   UNSIGNED        — no signature, or a bad signature: fails
#
# --setup answers a different question: not "is this history signed" but "can
# this project sign at all", which is what a merge gate depends on before there
# is anything to gate.
#
#   MISSING     — a setting a verifiable signature needs is not configured
#   UNREADABLE  — the trust root is configured but cannot be read
#   UNPROVED    — configured, but a real signed commit did not come out of it
#
# A trust root that is configured and present but that the process lacks
# permission to read — a chmod'd signers file, an unreadable ~/.gnupg — is
# exit 2 in EVERY mode, never UNVERIFIED/UNREADABLE at exit 1: exit 1 says
# "the project is wrong", and there only the environment is.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put — so outside a
# git repository the script carried on in the caller's directory with a
# relative config path. The status has to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

strict=0
setup=0
range=""
while [ $# -gt 0 ]; do
    case "$1" in
        (--strict) strict=1 ;;
        (--setup) setup=1 ;;
        (-*) gr_die "unknown argument: $1" ;;
        (*)
            [ -z "$range" ] || gr_die "only one rev range allowed"
            range="$1"
            ;;
    esac
    shift
done

if [ "$setup" -eq 1 ]; then
    [ -z "$range" ] || gr_die \
        "--setup proves the configuration, not a history: it takes no rev range"
    [ "$strict" -eq 0 ] || gr_die \
        "--setup already implies --strict; pass --setup alone"
    strict=1
fi

# Environment guard: a trust root that is CONFIGURED AND PRESENT but that this
# process lacks permission to read. That state produces the same %G? = U/E as
# a genuinely untrusted signature, and reporting it as UNVERIFIED at exit 1
# says "the project is wrong" when only the environment is — the operator then
# goes hunting in the project's configuration, which is exactly where the
# repair is not. Exit 2 is the environment verdict, and it is reserved for the
# permission-denied shape: a configured path that does not EXIST stays exit 1,
# because a wrong path is something the project wrote (usually a typo in it).
#
# Two trust roots, by format. ssh names a file; openpgp (and an unset format,
# which git signs with openpgp) reads the caller's keyring, so the inspectable
# thing is the keyring directory itself.
#
# Called lazily from check_commits — only once a signature has failed to
# verify — so a project that never signs, whatever the state of the caller's
# keyring, is never convicted over a trust root no verdict depended on.
trust_root_env_guard() {
    _tr_fmt=$(git config --get gpg.format 2>/dev/null)
    if [ "$_tr_fmt" = ssh ]; then
        _tr_signers=$(git config --path --get gpg.ssh.allowedSignersFile 2>/dev/null)
        if [ -n "$_tr_signers" ] && [ -e "$_tr_signers" ] && [ ! -r "$_tr_signers" ]; then
            gr_die "the ssh trust root exists but this process cannot read it: $_tr_signers
  This is an ENVIRONMENT error, not a project one — the configuration is
  intact and names a real file; what failed is this process's permission to
  open it. Fix the permissions or run as the user who owns it.
  check-signing.sh --setup is the tool that separates configuration gaps
  from environment ones."
        fi
    else
        _tr_home="${GNUPGHOME:-${HOME:-}/.gnupg}"
        if [ -d "$_tr_home" ] && { [ ! -r "$_tr_home" ] || [ ! -x "$_tr_home" ]; }; then
            gr_die "the gpg keyring exists but this process cannot read it: $_tr_home
  This is an ENVIRONMENT error, not a project one — no project setting can
  repair a keyring the process lacks permission to open. Fix the permissions
  or run as the user who owns it. check-signing.sh --setup is the tool that
  separates configuration gaps from environment ones."
        fi
    fi
}

# The verdict for a list of commits, one line each, non-zero if any failed.
# A function so that --setup can put its own commit through exactly the path a
# real check takes: a second implementation of "did it verify" would be free to
# drift from the one the merge gate runs.
check_commits() {
    _fail=0
    for c in $1; do
        gstat=$(git log -1 --format='%G?' "$c")
        case "$gstat" in
            (G) ;;
            (U|E)
                trust_root_env_guard
                if [ "$strict" -eq 1 ]; then
                    echo "UNVERIFIED $c (signature present but untrusted/unverifiable)"
                    _fail=1
                else
                    echo "WARN-UNVERIFIED $c (signature present but untrusted/unverifiable; configure gpg.ssh.allowedSignersFile or keyring to verify)"
                fi
                ;;
            (B|X|Y|R)
                echo "UNSIGNED $c (bad, expired, or revoked signature)"
                _fail=1
                ;;
            (*)
                if git cat-file commit "$c" | grep -q '^gpgsig'; then
                    trust_root_env_guard
                    if [ "$strict" -eq 1 ]; then
                        echo "UNVERIFIED $c (signature present but not verifiable)"
                        _fail=1
                    else
                        echo "WARN-UNVERIFIED $c (signature present but not verifiable; configure gpg.ssh.allowedSignersFile or keyring to verify)"
                    fi
                else
                    echo "UNSIGNED $c (no signature)"
                    _fail=1
                fi
                ;;
        esac
    done
    return $_fail
}

# --setup: prove that this project can produce a verifiable signature.
#
# Two halves, in this order. First the configuration is read and every missing
# piece is NAMED — the caller is a human about to fix them, and one verdict
# covering four separate gaps costs three more runs than it needs to. Then, and
# only when nothing is missing, the rest is PROVED: settings being present says
# nothing about whether the key can sign or the signature verifies, and only a
# real signature answers that.
#
# The proof is made in a throwaway repository. A signed commit in the project
# would dirty the very tree the merge guards inspect. No history is read here
# either, so a project with no commits yet — the shape ratchet runs in — can
# still be proved.
run_setup() {
    # The environment guard runs first: a trust root the process cannot even
    # open is not a finding to work through alongside MISSING lines — every
    # one of those is a project repair, and this one is not. It also keeps
    # the proof below from failing with a gpg error that never names the
    # permission problem.
    trust_root_env_guard

    _fmt=$(git config --get gpg.format 2>/dev/null)
    _key=$(git config --get user.signingkey 2>/dev/null)
    _sign=$(git config --bool --get commit.gpgsign 2>/dev/null)
    # In a linked worktree the effective value is not the project's answer:
    # worktree-discipline leaves worktree commits unsigned on purpose, and a
    # project that writes that down as worktree-scoped config is following
    # the discipline, not missing a setting. Taking the effective value here
    # reported a false MISSING from every worktree — and all the work happens
    # in worktrees, so every project saw it, and a false finding beside a
    # true one teaches the operator to discount both. So the worktree scope
    # is dropped and the last remaining scope wins, which is git's own
    # precedence with the worktree file taken out. If --show-scope is not
    # available (git < 2.26) or the key is set nowhere, the plain read above
    # stands — no worse than before, and an absent key is MISSING either way.
    if [ "$(git rev-parse --git-dir 2>/dev/null)" != "$(git rev-parse --git-common-dir 2>/dev/null)" ]; then
        _scoped=$(git config --show-scope --bool --get-all commit.gpgsign 2>/dev/null) \
            && _sign=$(printf '%s\n' "$_scoped" \
                | LC_ALL=C awk '$1 != "worktree" { v = $2 } END { print v }')
    fi
    _name=$(git config --get user.name 2>/dev/null)
    _email=$(git config --get user.email 2>/dev/null)
    _prog=$(git config --get gpg.program 2>/dev/null)
    _sshprog=$(git config --get gpg.ssh.program 2>/dev/null)
    _signers=""
    _missing=0

    if [ -z "$_fmt" ]; then
        echo "MISSING gpg.format (no signature format configured; e.g. git config gpg.format ssh)"
        _missing=1
    fi
    if [ -z "$_key" ]; then
        echo "MISSING user.signingkey (no signing key configured)"
        _missing=1
    fi
    # Unset and false are one finding, not two: both mean the next commit this
    # project makes is unsigned, and the fix is the same word.
    if [ "$_sign" != true ]; then
        echo "MISSING commit.gpgsign (commits are not signed by default; git config commit.gpgsign true)"
        _missing=1
    fi
    # A signature is verified against the COMMITTER's address. With no
    # user.email git guesses one from the host, the guess is in no signers
    # file, and every commit the project makes is unverifiable for a reason no
    # message about keys would ever mention.
    if [ -z "$_email" ]; then
        echo "MISSING user.email (the identity a signature is verified against)"
        _missing=1
    fi
    # The trust root is what makes a signature verifiable, and it is per
    # format: ssh reads a signers file, openpgp reads the caller's keyring —
    # not a path anything here can inspect. So the file is required where there
    # is a file to require, and the proof below covers the rest either way.
    if [ "$_fmt" = ssh ]; then
        _signers=$(git config --path --get gpg.ssh.allowedSignersFile 2>/dev/null)
        if [ -z "$_signers" ]; then
            echo "MISSING gpg.ssh.allowedSignersFile (no trust root: ssh signatures can be made but never verified)"
            _missing=1
        elif [ ! -r "$_signers" ]; then
            echo "UNREADABLE gpg.ssh.allowedSignersFile ($_signers is configured but cannot be read)"
            _missing=1
        fi
    fi

    # Nothing is signed until every piece is there. Reaching the proof with a
    # gap in the configuration means signing with whatever git falls back to,
    # which on a developer's own machine is their personal key — measured: a
    # hardware one, waiting on a touch that a script run has no way to ask for.
    [ "$_missing" -eq 0 ] || return 1

    # git resolves a relative config path against the working directory of the
    # process reading it, and the proof runs in the throwaway repository — so a
    # path written relative to the project would be looked for beside that
    # repository instead, and read as absent.
    case "$_signers" in
        (/*) ;;
        (*) _signers="$gr_repo_root/$_signers" ;;
    esac
    # The same for the key, but only where the value names a file that is
    # there: user.signingkey may equally be literal key material or a
    # fingerprint, and those must be passed through untouched.
    case "$_key" in
        (/*) ;;
        (*) [ ! -f "$_key" ] || _key="$gr_repo_root/$_key" ;;
    esac

    _tmp=$(mktemp -d 2>/dev/null) || _tmp=""
    if [ -z "$_tmp" ]; then
        _tmp="${TMPDIR:-/tmp}/guardrails-signing-proof-$$"
        mkdir "$_tmp" 2>/dev/null || gr_die "cannot create a temporary directory: $_tmp"
    fi
    # A whole repository per proof, and ratchet asks the operator to run this
    # until it passes. Removed on every exit path, including the ones gr_die
    # takes below.
    trap 'rm -rf "$_tmp"' EXIT

    # Every git command from here has to land in the throwaway repository. An
    # inherited GIT_DIR points at the project and would send them all there —
    # including the commit.
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
    cd "$_tmp" || gr_die "cannot enter the temporary directory: $_tmp"
    git init -q --template= . >/dev/null 2>&1 \
        || gr_die "cannot create a throwaway repository in $_tmp"

    # Written into the throwaway repository's own config rather than passed per
    # command: the verification above is reused verbatim, and it reads a plain
    # `git log` that carries no overrides. Nothing is inherited from the
    # project's repository either, so every setting the signature depends on
    # has to be restated here.
    git config user.name "${_name:-guardrails}"
    git config user.email "$_email"
    git config gpg.format "$_fmt"
    git config user.signingkey "$_key"
    git config commit.gpgsign true
    [ -z "$_signers" ] || git config gpg.ssh.allowedSignersFile "$_signers"
    [ -z "$_prog" ] || git config gpg.program "$_prog"
    [ -z "$_sshprog" ] || git config gpg.ssh.program "$_sshprog"

    : > proof
    git add proof >/dev/null 2>&1
    if ! git commit -q -S -m "guardrails signing proof" > proof.log 2>&1; then
        echo "UNPROVED signing (the test commit could not be signed with this configuration)"
        sed 's/^/  /' proof.log
        return 1
    fi
    if ! check_commits "$(git rev-list -1 HEAD)"; then
        echo "UNPROVED signing (the test commit was signed, but its signature did not verify against the configured trust root)"
        return 1
    fi

    echo "signing proved: a commit signed with this project's configuration verifies (gpg.format=$_fmt)"
    return 0
}

if [ "$setup" -eq 1 ]; then
    run_setup
    exit $?
fi

if [ -n "$range" ]; then
    commits=$(git rev-list "$range") || gr_die "bad rev range: $range"
else
    commits=$(git rev-list -1 HEAD) || gr_die "no commits"
fi

check_commits "$commits" || exit 1
exit 0
