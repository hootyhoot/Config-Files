alias code='open -a /Applications/Visual\ Studio\ Code.app/ '
# ssh into nerdrack vps
alias sshs='ssh root@107.172.208.141'
alias update="brew update && brew upgrade"
alias cd="z"
#ls replacement, use -H to show hard links like in trad ls -l
alias ls="eza -l --no-user --header"
alias nvim="lvim"
#takes port number and searches for name of processes using the port then pipelines it to xargs (kinda like tee) and runs kill on those processes
findandkill() { lsof -t -i tcp:$1 | xargs kill }
alias killport=findandkill
alias pest=./vendor/bin/pest

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

#zoxide (cd replacemment)
eval "$(zoxide init zsh)"

#zsh autosuggestions (gray suggestions in zsh)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
export PATH=$(npm config get prefix)/bin:$PATH
