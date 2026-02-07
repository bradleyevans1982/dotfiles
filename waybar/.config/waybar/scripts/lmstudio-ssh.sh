#!/bin/bash
# SSH to LMStudio server via Tailscale with port forwarding, straight into lms chat

alacritty -e ssh -t -L 1234:localhost:1234 bradv@bradv-ms-7c02 "~/.lmstudio/bin/lms chat"
