#!/bin/sh

alias zsh-update-plugins="zap --update"

# general use
alias ls='exa --icons'                                                          # ls
alias l='exa --icons -lbF --git'                                                # list, size, type, git
alias ll='exa --icons -lbGF --git'                                              # long list
alias llm='exa -lbGd --git --sort=modified'                                     # long list, modified date sort
alias la='exa -lbhHigUmuSa --time-style=long-iso --git --color-scale --icons'   # all list
alias lx='exa -lbhHigUmuSa@ --time-style=long-iso --git --color-scale'          # all + extended list

# specialty views
alias lS='exa -1'                                                       # one column, just names
alias lt='exa --tree --level=2'                                         # tree