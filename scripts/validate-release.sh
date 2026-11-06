
#!/bin/bash

set -eu

echo "Starting Repository Validation"

FILES=(
    "app/index.html"
    "config/release-policy.txt"
    "docs/release-notes.md"
)

for file in "${FILES[@]}"
do
    if [ ! -s "$file" ]; then
        echo "ERROR: Missing or empty file: $file"
        exit 1
    fi

    echo "Validated: $file"
done

echo "Repository Validation Successful"
