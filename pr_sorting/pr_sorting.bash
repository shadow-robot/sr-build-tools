#!/usr/bin/bash

WORKING_DIR="$( cd -- . && pwd )"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
cd "$SCRIPT_DIR"

if [ ! -d .venv ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate

pip install -r requirements.txt

python3 pr_sorting.py

deactivate

cd "$WORKING_DIR"
