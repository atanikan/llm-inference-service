#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <prompt>"
    exit 1
fi

# Get the prompt from the script argument
PROMPT="$1"

# Run the curl command using the provided prompt
curl http://localhost:8000/generate \
-d "{
\"prompt\": \"$PROMPT\",
\"use_beam_search\": true,
\"n\": 4,
\"temperature\": 0
}"



