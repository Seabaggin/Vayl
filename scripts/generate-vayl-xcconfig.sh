#!/bin/bash
#
# Generates the gitignored Vayl.xcconfig (the baseConfiguration for every build
# configuration) from environment variables. Xcode substitutes these build
# settings into Vayl/Vayl.plist, which PostHogService/SupabaseService read at
# runtime. Vayl.xcconfig is gitignored — real keys never land in git.
#
# WHERE TO PASTE REAL KEYS: put them in `.env` at the repo root (gitignored),
# one per line, e.g.
#   SUPABASE_URL=https://<project>.supabase.co
#   SUPABASE_ANON_KEY=sb_publishable_...
#   POSTHOG_API_KEY=phc_...            <- PostHog project API key (project 512827)
#   POSTHOG_HOST=https://us.i.posthog.com
# then run:  scripts/generate-vayl-xcconfig.sh
# (Already-exported environment variables take precedence over .env.)

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

# Load .env if present; exported env vars win over .env values.
if [[ -f "${repo_root}/.env" ]]; then
  while IFS='=' read -r name value; do
    [[ -z "${name}" || "${name}" == \#* ]] && continue
    if [[ -z "${!name:-}" ]]; then
      export "${name}=${value}"
    fi
  done < "${repo_root}/.env"
fi

output_path="${1:-${repo_root}/Vayl.xcconfig}"
required_variables=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  POSTHOG_API_KEY
  POSTHOG_HOST
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Missing required variable: ${variable_name} (export it or add it to ${repo_root}/.env)" >&2
    exit 1
  fi
done

# xcconfig treats // as a comment. Insert an empty build-setting expansion
# between the slashes so URL values survive Xcode's parser unchanged.
escape_url_for_xcconfig() {
  local value="$1"
  local escaped_slashes='/$()/'
  printf '%s' "${value//\/\//$escaped_slashes}"
}

{
  printf 'SLASH = /\n'
  printf 'SUPABASE_URL = %s\n' "$(escape_url_for_xcconfig "${SUPABASE_URL}")"
  printf 'SUPABASE_ANON_KEY = %s\n' "${SUPABASE_ANON_KEY}"
  printf 'POSTHOG_API_KEY = %s\n' "${POSTHOG_API_KEY}"
  printf 'POSTHOG_HOST = %s\n' "$(escape_url_for_xcconfig "${POSTHOG_HOST}")"
} > "${output_path}"

echo "Generated ${output_path} from environment variables."
