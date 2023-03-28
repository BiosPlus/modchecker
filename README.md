# ModChecker

ModChecker is a modular Bash script that scans specified Reddit subreddits and checks the activity of their moderators. It can help identify inactive subreddits that may be open for takeover.

## Features

- Scans through a list of subreddits provided via command line arguments or text file.
- Fetches a list of moderators for each subreddit and checks their recent activity (posts and comments).
- Outputs the activity countdown for each moderator until they reach 30 days of inactivity.
- Generates and updates JSON files with the subreddit scan results in `./config/subreddits/`.
- Allows users to flag suspected bot moderators and adds them to a global exclude list in `./config/global_exclude.json`.

## Usage

```bash
./modchecker.sh [-sr|--subreddit] [subreddit1] [subreddit2] ...
./modchecker.sh -sr melbourne
./modchecker.sh -sr australia -sr sydney
```

If no subreddits are provided via the command line arguments, the script will automatically scan the subreddits that have JSON files in the `./config/subreddits/` directory.

## Output
For each subreddit, the script will print the activity countdown for each moderator until they reach 30 days of inactivity. If all moderators are inactive for at least 30 days, the script will output a message indicating that the subreddit is open for sniping.

After scanning each subreddit, the user will be prompted to enter the names or numbers of moderators they think may be bots. The suspected bot moderators will be added to the `./config/global_exclude.json` file, which will be used as a reference for excluding moderators from future checks.

## Configuration
Edit the `CLIENT_ID`, `CLIENT_SECRET`, `USERNAME`, and `PASSWORD` variables at the beginning of the script to match your Reddit app credentials and Reddit account.
Add or remove subreddits to scan by providing them as command line arguments or by editing the JSON files in the `./config/subreddits/` directory.

## Dependencies
jq - A lightweight and flexible command-line JSON processor. It's required for handling JSON data within the script.
