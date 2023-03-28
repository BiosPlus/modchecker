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
