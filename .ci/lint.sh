#!/usr/bin/env bash
# =============================================================================
# .ci/lint.sh — static validation for this dotfiles repo.
#
# Runs the same checks locally and in CI so that `make lint` reproduces exactly
# what the "validate" workflow does. Lives under a dot-prefixed directory, which
# chezmoi ignores automatically, so it is never deployed to $HOME.
#
# Checks:
#   templates : render every run_once_*.tmpl across a matrix of chezmoi data
#               combinations, then assert no unresolved directives, no
#               "<no value>", valid bash syntax and a clean shellcheck run.
#   toml      : parse every TOML file the repo ships.
#   actions   : actionlint over .github/workflows (skipped when unavailable).
#
# Usage: .ci/lint.sh [templates|toml|actions|all]
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
RESET=$'\033[0m'

fail() {
    echo "${RED}ERROR:${RESET} $*" >&2
    exit 1
}

info() { echo "${BLUE}==>${RESET} $*"; }
warn() { echo "${YELLOW}WARN:${RESET} $*" >&2; }
ok() { echo "${GREEN}OK${RESET} $*"; }

# -----------------------------------------------------------------------------
# Locate a working chezmoi. `command -v` is not enough: a mise shim with no
# version pinned resolves fine but fails on execution.
# -----------------------------------------------------------------------------
find_chezmoi() {
    local candidate
    if [ -n "${CHEZMOI:-}" ] && "$CHEZMOI" --version > /dev/null 2>&1; then
        echo "$CHEZMOI"
        return 0
    fi
    for candidate in \
        "$(command -v chezmoi 2> /dev/null || true)" \
        "$HOME/.local/bin/chezmoi" \
        "/opt/homebrew/bin/chezmoi" \
        "/usr/local/bin/chezmoi"; do
        [ -n "$candidate" ] || continue
        if "$candidate" --version > /dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done
    # mise installs, newest first
    for candidate in "$HOME/.local/share/mise/installs/chezmoi"/*/chezmoi; do
        if [ -x "$candidate" ] && "$candidate" --version > /dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# -----------------------------------------------------------------------------
# Template rendering matrix.
#
# Each row is "headless:mise_tools:container_services:kvm". These four flags are
# the only inputs that change what the templates emit, so this covers the same
# ground as the CI matrix without needing four operating systems.
#
# $LINT_COMBOS overrides the list (space or newline separated). CI uses it so
# each matrix job lints its own combination on its own OS, which is what
# exercises the distro-specific template branches.
# -----------------------------------------------------------------------------
DEFAULT_MATRIX=(
    "false:true:true:true"
    "true:true:false:false"
    "false:false:true:false"
    "true:false:false:true"
)

if [ -n "${LINT_COMBOS:-}" ]; then
    read -r -a MATRIX <<< "$LINT_COMBOS"
else
    MATRIX=("${DEFAULT_MATRIX[@]}")
fi

lint_templates() {
    local chezmoi
    chezmoi="$(find_chezmoi)" || fail "chezmoi not found. Install it or set \$CHEZMOI."
    info "using $chezmoi ($("$chezmoi" --version | head -1))"

    local shellcheck_bin=""
    if command -v shellcheck > /dev/null 2>&1; then
        shellcheck_bin="$(command -v shellcheck)"
    else
        warn "shellcheck not installed; skipping shell static analysis."
    fi

    local tmp
    tmp="$(mktemp -d -t dotfiles-lint-XXXXXX)"
    trap 'rm -rf "$tmp"' RETURN

    local rendered_total=0 skipped_total=0 combo
    for combo in "${MATRIX[@]}"; do
        IFS=: read -r headless mise_tools services kvm <<< "$combo"
        local label="headless=$headless mise=$mise_tools services=$services kvm=$kvm"
        info "combination: $label"

        local cfg="$tmp/chezmoi.toml"
        CHEZMOI_HEADLESS="$headless" \
            CHEZMOI_MISE_TOOLS="$mise_tools" \
            CHEZMOI_ENABLE_CONTAINER_SERVICES="$services" \
            CHEZMOI_ENABLE_KVM="$kvm" \
            "$chezmoi" execute-template --init --source "$ROOT" \
            < .chezmoi.toml.tmpl > "$cfg" \
            || fail "could not render .chezmoi.toml.tmpl for $label"

        local f out rendered=0 skipped=0
        for f in run_once_*.tmpl; do
            out="$tmp/$(basename "${f%.tmpl}").sh"
            "$chezmoi" execute-template --config "$cfg" --source "$ROOT" \
                < "$f" > "$out" \
                || fail "$f failed to render for $label"

            if grep -q '{{' "$out"; then
                fail "unresolved template directives in $f ($label)"
            fi
            if grep -q '<no value>' "$out"; then
                fail "'<no value>' rendered in $f ($label) — a template key is missing"
            fi

            # A template gated out by OS renders empty. `bash -n` on an empty
            # file trivially succeeds, so count these separately instead of
            # reporting a vacuous pass.
            if [ ! -s "$out" ]; then
                skipped=$((skipped + 1))
                continue
            fi

            bash -n "$out" || fail "bash syntax error in $f ($label)"
            if [ -n "$shellcheck_bin" ]; then
                # The scripts are clean at the strictest level today; keep the
                # baseline there so regressions surface immediately.
                "$shellcheck_bin" --shell=bash --severity=style "$out" \
                    || fail "shellcheck reported problems in $f ($label)"
            fi
            rendered=$((rendered + 1))
        done

        [ "$rendered" -gt 0 ] \
            || fail "no template produced output for $label — the lint would be vacuous"
        echo "    $rendered checked, $skipped gated out"
        rendered_total=$((rendered_total + rendered))
        skipped_total=$((skipped_total + skipped))
    done

    ok "run_once templates: $rendered_total checks across ${#MATRIX[@]} combinations ($skipped_total gated out)"
}

lint_toml() {
    command -v python3 > /dev/null 2>&1 || fail "python3 is required to validate TOML files."
    python3 - <<'PY'
import pathlib, sys
try:
    import tomllib
except ModuleNotFoundError:
    sys.exit("python3.11+ (tomllib) is required to validate TOML files")

files = [
    *sorted(pathlib.Path(".chezmoidata").glob("*.toml")),
    pathlib.Path("dot_config/mise/config.toml"),
    pathlib.Path("dot_config/mise/config.local.toml"),
    pathlib.Path("dot_config/zsh/oh-my-posh/omp-config.toml"),
    pathlib.Path("dot_config/zsh/starship/starship.toml"),
]
for f in files:
    if not f.exists():
        sys.exit(f"missing TOML file: {f}")
    with open(f, "rb") as fh:
        tomllib.load(fh)
    print(f"  parsed {f}")
PY
    ok "TOML files parse"
}

lint_actions() {
    if ! command -v actionlint > /dev/null 2>&1; then
        warn "actionlint not installed; skipping workflow analysis."
        return 0
    fi
    actionlint || fail "actionlint reported problems"
    ok "GitHub workflows"
}

case "${1:-all}" in
    templates) lint_templates ;;
    toml) lint_toml ;;
    actions) lint_actions ;;
    all)
        lint_templates
        lint_toml
        lint_actions
        ;;
    *) fail "unknown target '$1' (expected: templates|toml|actions|all)" ;;
esac
