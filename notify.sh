#!/bin/bash

# Default values
DEFAULT_URL="http://localhost:8888/api/discord-forwarder"
MESSAGE=""
USERNAME=""
AVATAR_URL=""
WEBHOOK_URL=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -m|--message)
      MESSAGE="$2"
      shift 2
      ;;
    -u|--username)
      USERNAME="$2"
      shift 2
      ;;
    -a|--avatar)
      AVATAR_URL="$2"
      shift 2
      ;;
    -w|--webhook)
      WEBHOOK_URL="$2"
      shift 2
      ;;
    -s|--server)
      SERVER_URL="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: notify [options]"
      echo "Options:"
      echo "  -m, --message MESSAGE    The message to send (required)"
      echo "  -u, --username USERNAME  Custom username for the message"
      echo "  -a, --avatar URL         Custom avatar URL for the message"
      echo "  -w, --webhook URL        Discord webhook URL (overrides server config)"
      echo "  -s, --server URL         Serverless function URL (defaults to $DEFAULT_URL)"
      echo "  -h, --help               Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if message is provided
if [ -z "$MESSAGE" ]; then
  echo "Error: Message is required. Use -m or --message to specify a message."
  exit 1
fi

# Use default URL if not specified
if [ -z "$SERVER_URL" ]; then
  SERVER_URL="$DEFAULT_URL"
fi

# Prepare JSON payload
JSON_PAYLOAD="{\"message\":\"$MESSAGE\""

if [ ! -z "$USERNAME" ]; then
  JSON_PAYLOAD="$JSON_PAYLOAD,\"username\":\"$USERNAME\""
fi

if [ ! -z "$AVATAR_URL" ]; then
  JSON_PAYLOAD="$JSON_PAYLOAD,\"avatarUrl\":\"$AVATAR_URL\""
fi

if [ ! -z "$WEBHOOK_URL" ]; then
  JSON_PAYLOAD="$JSON_PAYLOAD,\"webhookUrl\":\"$WEBHOOK_URL\""
fi

JSON_PAYLOAD="$JSON_PAYLOAD}"

# Send the request
echo "Sending message to notify..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$SERVER_URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

# Extract status code and response body
HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$ d')

# Check if jq is available for prettier output
if command -v jq >/dev/null 2>&1; then
  JQ_AVAILABLE=true
else
  JQ_AVAILABLE=false
fi

# Display the response
if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
  echo -e "\033[32m✅ Success (HTTP $HTTP_STATUS):\033[0m"
  if $JQ_AVAILABLE && echo "$RESPONSE_BODY" | jq . >/dev/null 2>&1; then
    echo "$RESPONSE_BODY" | jq .
  else
    echo "$RESPONSE_BODY"
  fi
  exit 0
else
  echo -e "\033[31m❌ Error (HTTP $HTTP_STATUS):\033[0m"
  if $JQ_AVAILABLE && echo "$RESPONSE_BODY" | jq . >/dev/null 2>&1; then
    echo "$RESPONSE_BODY" | jq .
  else
    echo "$RESPONSE_BODY"
  fi
  exit 1
fi
