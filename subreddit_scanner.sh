#!/bin/bash

CONFIG_DIR="./config"
CREDENTIALS_FILE="$CONFIG_DIR/credentials.json"

declare -a SUBREDDITS

INTERACTIVE_BOTS=false
SILENT=false

# Command-line arguments processing
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -sr|--subreddit)
      shift
      SUBREDDITS+=("$1")
      ;;
    -ib|--interactive-bots)
      INTERACTIVE_BOTS=true
      ;;
    -s|--silent)
      SILENT=true
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
  shift
done


if [ ${#SUBREDDITS[@]} -eq 0 ]; then
  for file in "$CONFIG_DIR/subreddits"/*.json; do
    SUBREDDITS+=($(basename "$file" .json))
  done
fi

CLIENT_ID=$(jq -r '.client_id' $CREDENTIALS_FILE)
CLIENT_SECRET=$(jq -r '.client_secret' $CREDENTIALS_FILE)
USERNAME=$(jq -r '.username' $CREDENTIALS_FILE)
PASSWORD=$(jq -r '.password' $CREDENTIALS_FILE)

# Function to check if a moderator is in the global exclude list
function is_excluded() {
  local mod_name="$1"
  local excluded_mods=$(jq '.[]' "$CONFIG_DIR/global_exclude.json" 2>/dev/null)
  [[ $excluded_mods =~ $mod_name ]]
}

# Function to get an access token for the Reddit API
function get_access_token() {
  curl -s -X POST -d "grant_type=password&username=$USERNAME&password=$PASSWORD" --user "$CLIENT_ID:$CLIENT_SECRET" -H "User-Agent: ModChecker/0.1" https://www.reddit.com/api/v1/access_token | jq -r '.access_token'
}

# Function to get a list of moderators for a subreddit
function get_mods() {
  local subreddit="$1"
  local access_token="$2"
  curl -s -H "Authorization: bearer $access_token" -A "ModChecker/0.1" "https://oauth.reddit.com/r/$subreddit/about/moderators" | jq -r '.data.children[].name'
}

# Function to get the number of days since a user's last activity
function get_last_activity() {
  local user="$1"
  local access_token="$2"
  local now=$(date +%s)
  
  local last_post_activity=$(curl -s -H "Authorization: bearer $access_token" -A "ModChecker/0.1" "https://oauth.reddit.com/user/$user/submitted?limit=5" | jq -r '.data.children[].data.created_utc' 2>/dev/null)
  local last_comment_activity=$(curl -s -H "Authorization: bearer $access_token" -A "ModChecker/0.1" "https://oauth.reddit.com/user/$user/comments?limit=5" | jq -r '.data.children[].data.created_utc' 2>/dev/null)

  if [[ -z "$last_post_activity" && -z "$last_comment_activity" ]]; then
    echo "unknown"
    return
  fi

  local all_activity=($last_post_activity $last_comment_activity)
  local most_recent_activity=0

  for activity in "${all_activity[@]}"; do
    if (( $(echo "$activity > $most_recent_activity" | bc -l) )); then
      most_recent_activity=$activity
    fi
  done

  echo $(( (now - most_recent_activity) / 86400 ))
}

# Function to update the JSON file with information about subreddit moderators and their activity
function update_json() {
  local subreddit="$1"
  local last_scanned=$(date +%s)
  local mod_data="$2"
  local output="{\"last_scanned\": $last_scanned, \"moderators\": $mod_data}"
  mkdir -p "./config/subreddits"
  echo "$output" > "./config/subreddits/$subreddit.json"
}

# Function to add specified moderators to the global exclude list
function get_global_exclude() {
  if [ -f "./config/global_exclude.json" ]; then
    cat "./config/global_exclude.json" | jq -r '.[]'
  fi
}

# Function to add specified moderators to the global exclude list
function add_to_global_exclude() {
  local bots="$1"
  local current_data=$(cat "./config/global_exclude.json" 2>/dev/null)
  if [ -z "$current_data" ]; then
    current_data="[]"
  fi
  local updated_data=$(echo "$current_data" | jq ". + $bots")
  echo "$updated_data" > "./config/global_exclude.json"
}

# Main function of the script
function main() {
  local access_token=$(get_access_token)
  local global_exclude=($(get_global_exclude))

  for subreddit in "${SUBREDDITS[@]}"; do
    local all_inactive=true
    local mods=$(get_mods "$subreddit" "$access_token")
    local mod_data="["

    local i=1
    declare -A mod_map
    for mod in $mods; do
      if [[ " ${global_exclude[*]} " != *"$mod"* ]]; then
        local last_activity=$(get_last_activity "$mod" "$access_token")

        if [[ "$last_activity" == "unknown" ]]; then
          # Yellow color for unknown activity
          if ! $SILENT; then
            printf "\e[33m[$i] Moderator: $mod, Days remaining until inactive: unknown\e[0m\n"
          fi
        else
          if ! $SILENT; then
            echo "[$i] Moderator: $mod, Days remaining until inactive: $((30 - last_activity))"
          fi

          if [[ "$last_activity" -lt 30 ]]; then
            all_inactive=false
          fi
        fi

        mod_map[$i]=$mod
        mod_data+="{\"name\": \"$mod\", \"days_remaining\": $((30 - last_activity))}"
        if [ $i -lt ${#mods[@]} ]; then
          mod_data+=", "
        fi
        i=$((i + 1))
      fi
    done

    mod_data+="]"
    update_json "$subreddit" "$mod_data"

    if $all_inactive; then
      echo "Subreddit: $subreddit is inactive and open for sniping"
    elif ! $SILENT; then
      echo "Subreddit: $subreddit is active"
    fi

    if $INTERACTIVE_BOTS && ! $SILENT; then
      echo "Enter the numbers or names of moderators you think may be bots (separated by spaces):"
      read -a suspected_bots

      local bots="[]"
      for suspect in "${suspected_bots[@]}"; do
        if [[ "$suspect" =~ ^[0-9]+$ ]] && [[ -n "${mod_map[$suspect]}" ]]; then
          bots=$(echo "$bots" | jq ". + [\"${mod_map[$suspect]}\"]")
        elif [[ ! -z "${suspect// }" ]]; then
          bots=$(echo "$bots" | jq ". + [\"$suspect\"]")
        fi
      done

      if [ "$(echo "$bots" | jq 'length')" -gt 0 ]; then
        add_to_global_exclude "$bots"
      fi
    fi
  done
}


main