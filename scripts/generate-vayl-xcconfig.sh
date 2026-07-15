#!/bin/bash

set -euo pipefail

output_path="${1:-Vayl.xcconfig}"
required_variables=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  POSTHOG_API_KEY
  POSTHOG_HOST
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Missing required environment variable: ${variable_name}" >&2
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
