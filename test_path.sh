#!/bin/bash
echo "BASH_SOURCE[0]: ${BASH_SOURCE[0]}"
echo "dirname: $(dirname "${BASH_SOURCE[0]}")"
echo "pwd: $(pwd)"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "SCRIPT_DIR: $SCRIPT_DIR"
