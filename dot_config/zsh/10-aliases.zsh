alias hg='history | grep'

alias vim=nvim
alias vi=nvim
alias v=nvim

alias ls='ls --color=auto'
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'

alias k=kubectl
alias kcc=kubectx
alias kns=kubens
alias kg='kubectl get'
alias kgp='kubectl get pod'
alias kgcm='kubectl get configmaps'
alias kgst='kubectl get statefulsets'
alias kgd='kubectl get deployments'
alias kgsvc='kubectl get services'
alias kgsec='kubectl get secrets'

# eza aliases
alias eza='eza -g --icons'
alias ezal='eza -lah -a --icons'
alias ezas='eza -lah -a --icons --sort=size'
alias ezam='eza -lah -a --icons --sort=modified'
alias ezae='eza -lah -a --icons --sort=extension'
alias ezag='eza -lah -a --icons --git'
alias ezad='eza -lah -a --icons --only-dirs'
alias ezar='eza -lah -a --icons --reverse'
alias ezatree='eza --icons --tree'
