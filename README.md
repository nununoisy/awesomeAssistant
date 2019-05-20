# Awesome Assistant

The Google Assistant in AwesomeWM 4.x

Built on top of [endoplasmic's google-assistant library](https://github.com/endoplasmic/google-assistant).
Thanks to rxi for [json.lua](https://github.com/rxi/json.lua/).

## Setup with Google

To use the Awesome Assistant, you need to get API access. Follow the steps [here](https://developers.google.com/assistant/sdk/guides/library/python/embed/config-dev-project-and-account) until you get a JSON file with a long name (it should look like `client_secret_XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com.json`). ***DO NOT RENAME THIS FILE!***

You need to make one tweak to this file to allow you to sign in. Change
```js
"redirect_uris":["urn:ietf:wg:oauth:2.0:oob","http://localhost"]
```
to
```js
"redirect_uris":["http://localhost:3000/oauth2callback","urn:ietf:wg:oauth:2.0:oob"]
```

## Setup

Make sure you have Node.js (>10.0) installed.

Then clone the repo and grab the npm packages:

```bash
git clone https://github.com/nununoisy/awesomeAssistant
cd awesomeAssistant
npm i
```

It's recommended that you clone in the `~/.config/awesome` directory (or similar) so that it is easier to import the class into your `rc.lua` later.

Copy the OAuth2 JSON file you got earlier into the directory where you cloned this repo.

To setup the sound, you need to know what audio backend you use. The default is ALSA. To use a different backend, reinstall `speaker` with an appropriate mpg123 backend (e.g. `pulse`, `jack`, `openal`, etc.). For example, to use Awesome Assistant with PulseAudio, issue:

```bash
npm i speaker --mpg123-backend=pulse
```

Now add this to your `rc.lua` (or somewhere in your Awesome config):

```lua
local Assistant = require('assistant')

Assistant.init("/path/to/node", "/path/to/repo", "client_secret_XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com.json")

-- something
Assistant.start("tokens.json")
```

Where:
+ `/path/to/node` is a relative or absolute path to the Node.js executable. If it is relative make sure Node.js is in your PATH!
+ `/path/to/repo` is an **absolute** path where you cloned this repo. `assistant.lua` expects the `index.js` and OAuth2 files to reside here.
+ `client_secret_XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com.json` is the filename of the OAuth2 keys file you got from Google.
+ `tokens.json` is the name of the file where OAuth tokens should be stored. This can be changed to allow multiple accounts (allocate one file to each account).

## Methods

+ `assistant.init(node_path, index_path, key_file_path)` - Initialize the Assistant library.
    + `node_path` - (string) Path to Node.js
    + `index_path` - (string) Path to supplementary files
    + `key_file_path` - (string) Name of OAuth2 keys JSON file
+ `assistant.start(tokens_path)` - Start the Google Assistant.
    + `tokens_path` - (string) Name of file to store OAuth2 refresh tokens.
+ `assistant.stop()` - Stop the Assistant if it is running.
+ `running, pid = assistant.is_running()` - Check if the Assistant is running.
    + `running` - (boolean) Whether the Assistant is active.
    + `pid` - (integer or `nil`) PID of the Node.js process (active) or `nil` (inactive)