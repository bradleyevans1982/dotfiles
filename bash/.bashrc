#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ── Aliases ───────────────────────────────────────────────────────────────
alias grep='grep --color=auto'

# eza (modern ls replacement)
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'

# bat (modern cat replacement)
alias cat='bat --style=auto'

# lazygit
alias lg='lazygit'

# ── Zoxide (smarter cd) ───────────────────────────────────────────────────
eval "$(zoxide init bash)"

# ── Starship prompt ───────────────────────────────────────────────────────
eval "$(starship init bash)"
export PATH="$HOME/go/bin:$PATH"

# opencode
export PATH=/home/bradv/.opencode/bin:$PATH
