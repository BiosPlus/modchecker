# ModChecker

ModChecker is a modular Bash script that scans specified Reddit subreddits and checks the activity of their moderators. It can help identify inactive subreddits that may be open for takeover.

## Features

- Scans subreddits for moderator activity
- Identifies inactive moderators based on a 30-day inactivity threshold
- Excludes known bot accounts from scanning
- Automatically scans subreddits with JSON files in the `config/subreddits/` directory
- Stores subreddit scan data in JSON files for future reference

## Prerequisites

- Bash
- [curl](https://curl.se/)
- [jq](https://stedolan.github.io/jq/)

## Configuration

Add your Reddit API credentials to `./config/credentials.json`:

   ```json
   {
     "client_id": "YOUR_CLIENT_ID",
     "client_secret": "YOUR_CLIENT_SECRET",
     "username": "YOUR_USERNAME",
     "password": "YOUR_PASSWORD"
   }
```

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

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to improve the project.

# License

This project is licensed under the MIT License.