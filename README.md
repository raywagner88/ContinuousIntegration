Sinatra app using Github web hooks to run bash scripts.

Download and activate (ngrok)[https://ngrok.com]

Start required containers for nightwatch per the repo readme

Start the CI application by running:
```
bundle
ruby server.js
```

Start ngrok on port 4567
```
./ngrok http 4567
```

Add webhook for pull requests only to Github repo include ngrok URL
