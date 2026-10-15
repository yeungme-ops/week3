#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

# Reuse a working environment; recreate it if the base Python has changed.
python_identity='import sys; print(sys.version); print(sys.base_prefix); print(sys.platform)'
expected_python="$(python3 -c "$python_identity")"
existing_python="$(.venv/bin/python -c "$python_identity" 2>/dev/null || true)"
if [[ "$existing_python" != "$expected_python" ]]; then
  echo "Creating the class virtual environment..."
  python3 -m venv --clear .venv
fi

# A normal restart only reads local files; it does not contact PyPI.
requirements_hash="$(python3 - <<'PY'
import hashlib
from pathlib import Path

digest = hashlib.sha256()
digest.update(Path('requirements.txt').read_bytes())
digest.update(Path('.devcontainer/setup.sh').read_bytes())
print(digest.hexdigest())
PY
)"
stamp_file=".venv/.requirements.sha256"
installed_hash="$(cat "$stamp_file" 2>/dev/null || true)"

if [[ "$installed_hash" != "$requirements_hash" ]]; then
  echo "Installing the class packages..."
  rm -f "$stamp_file"
  .venv/bin/python -m pip install --disable-pip-version-check -r requirements.txt
  .venv/bin/python -m pip check
  # Record success only after installation and dependency checks have passed.
  printf '%s\n' "$requirements_hash" > "$stamp_file"
fi

echo "Ready: select .venv as your notebook kernel."
