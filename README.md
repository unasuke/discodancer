# Discodancer
The toy feed crawler. If new feed is found, post this to webhook (currently, only discord webhook is supported).

## Installation
```bash
$ git clone https://github.com/unasuke/discodancer.git
$ cd discodancer
$ bundle install
```

## Usage
```bash
$ bundle exec rake console # Follow the instructions
Which operations do you want? (Press ↑/↓ arrow to move and Enter to select)
‣ website
  webhook
  outgoing setting
  exit

$ bundle exec ruby app.rb
```
