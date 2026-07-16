#!/usr/bin/env bash
# SC tag consistency validator.
# Extracts SC tags from each artifact and checks every tag in SPEC.md §7 is also
# present in TC.md (section headings) and PLAN.md (sc_refs fields).
# Optionally checks REVIEW.md fidelity table.
#
# Usage:
#   bash scripts/validate-sc-tags.sh --spec SPEC.md --tc TC.md --plan PLAN.md
#   bash scripts/validate-sc-tags.sh --spec SPEC.md --tc TC.md --plan PLAN.md --review REVIEW.md
#
# Exit 0 = all consistent. Exit 1 = gap table printed to stdout.

set -euo pipefail

SPEC=""
TC=""
PLAN=""
REVIEW=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec)   SPEC="$2";   shift 2 ;;
    --tc)     TC="$2";     shift 2 ;;
    --plan)   PLAN="$2";   shift 2 ;;
    --review) REVIEW="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

die() { echo "ERROR: $1" >&2; exit 2; }

[[ -n "$SPEC" ]] || die "--spec is required"
[[ -n "$TC"   ]] || die "--tc is required"
[[ -n "$PLAN" ]] || die "--plan is required"

[[ -f "$SPEC" ]] || die "SPEC file not found: $SPEC"
[[ -f "$TC"   ]] || die "TC file not found: $TC"
[[ -f "$PLAN" ]] || die "PLAN file not found: $PLAN"

# Extract SC tags from SPEC.md §7 (Test Scope table).
# Accepts "SC-01" anywhere in a table row. Skips "Removed" and "N/A" tags.
extract_spec_tags() {
  local file="$1"
  grep -oE 'SC-[0-9]{2}' "$file" \
    | sort -u
}

# Extract "Removed" SC tags from SPEC.md — treat as satisfied, not a gap.
extract_removed_tags() {
  local file="$1"
  grep -iE 'Removed' "$file" \
    | grep -oE 'SC-[0-9]{2}' \
    | sort -u
}

# Extract SC tags from TC.md section headings: "## SC-01: ..."
extract_tc_tags() {
  local file="$1"
  grep -oE '^## SC-[0-9]{2}' "$file" \
    | grep -oE 'SC-[0-9]{2}' \
    | sort -u
}

# Extract SC tags from PLAN.md sc_refs fields: "sc_refs: [SC-01, SC-02]"
extract_plan_tags() {
  local file="$1"
  grep -oE 'SC-[0-9]{2}' "$file" \
    | sort -u
}

# Extract SC tags from REVIEW.md fidelity table rows
extract_review_tags() {
  local file="$1"
  grep -oE 'SC-[0-9]{2}' "$file" \
    | sort -u
}

SPEC_TAGS=$(extract_spec_tags "$SPEC")
REMOVED_TAGS=$(extract_removed_tags "$SPEC")
TC_TAGS=$(extract_tc_tags "$TC")
PLAN_TAGS=$(extract_plan_tags "$PLAN")

if [[ -n "$REVIEW" ]]; then
  [[ -f "$REVIEW" ]] || die "REVIEW file not found: $REVIEW"
  REVIEW_TAGS=$(extract_review_tags "$REVIEW")
fi

gaps=0

print_header() {
  printf "\n%-10s %-8s %-8s %-8s %s\n" "Tag" "SPEC" "TC" "PLAN" "${1:-}"
  printf "%-10s %-8s %-8s %-8s %s\n" "---" "----" "----" "----" "------"
}

check_tags() {
  local header="${1:-}"
  if [[ -n "$REVIEW" ]]; then
    print_header "REVIEW"
  else
    print_header ""
  fi

  while IFS= read -r tag; do
    # Skip tags marked as Removed
    if echo "$REMOVED_TAGS" | grep -qx "$tag"; then
      printf "%-10s %-8s %-8s %-8s %s\n" "$tag" "✓(removed)" "-" "-" "-"
      continue
    fi

    in_tc=$(echo "$TC_TAGS" | grep -x "$tag" && echo "✓" || echo "✗")
    in_plan=$(echo "$PLAN_TAGS" | grep -x "$tag" && echo "✓" || echo "✗")

    if [[ -n "$REVIEW" ]]; then
      in_review=$(echo "$REVIEW_TAGS" | grep -x "$tag" && echo "✓" || echo "✗")
      printf "%-10s %-8s %-8s %-8s %s\n" "$tag" "✓" "$in_tc" "$in_plan" "$in_review"
    else
      printf "%-10s %-8s %-8s %-8s\n" "$tag" "✓" "$in_tc" "$in_plan"
    fi

    if [[ "$in_tc" == "✗" || "$in_plan" == "✗" ]]; then
      gaps=$((gaps + 1))
    fi
    if [[ -n "$REVIEW" && "$in_review" == "✗" ]]; then
      gaps=$((gaps + 1))
    fi
  done <<< "$SPEC_TAGS"
}

echo "SC Tag Validator"
echo "  SPEC: $SPEC"
echo "  TC:   $TC"
echo "  PLAN: $PLAN"
[[ -n "$REVIEW" ]] && echo "  REVIEW: $REVIEW"

check_tags

if [[ $gaps -gt 0 ]]; then
  echo ""
  echo "FAIL: $gaps gap(s) found. Every SC tag in SPEC.md must appear in TC.md (## SC-NN heading) and PLAN.md (sc_refs field)."
  exit 1
else
  echo ""
  echo "OK: all SC tags consistent across artifacts."
  exit 0
fi
