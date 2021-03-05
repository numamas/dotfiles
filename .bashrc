# vim: filetype=sh foldmethod=marker foldmarker=#region,#endregion :

#region: export
export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export PROMPT_DIRTRIM=3
export PATH=`cat - << EOS | xargs -I{} echo -n '{}:' && echo -n $PATH
$HOME/bin
$HOME/script
$HOME/go/bin
$HOME/bin/factor
$HOME/bin/swift-2020-12-05/usr/bin
$HOME/.local/bin
$HOME/.vim/plugged/vim-iced/bin
EOS
`

# clipboard sharing
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    export DISPLAY=localhost:0.0
fi

# misc
export DOTNET_CLI_TELEMETRY_OPTOUT=1
#endregion

#region: function
mkcd () {
    mkdir $1 && cd $1
}

_defalias() {
    if [ $# != 2 ] && [ $# != 3 ]; then
        echo 'wrong number of arguments' 2>&1
        return 1
    fi
    local alias=$1
    local cmd=$2
    local opt="$3"
    if type $cmd > /dev/null 2>&1; then
        if [ "$opt" != "" ]; then
            alias $alias="$cmd $opt"
        else
            alias $alias="$cmd"
        fi
        return 0
    else
        return 2
    fi
}

_babashka_facilitated () {
    local cmd="(->> *input* ($@))"
    cat - | bb -io "$cmd"
}

_tmux_newpane_or_newwindow () {
    local cols=`tput cols`
    if [ $cols -lt 200 ]; then
        local opt='new-window'
    else
        local opt='split-window -h'
    fi
    tmux $opt $*
}
#endregion

#region: alias
alias b='_babashka_facilitated'
alias c='xsel -b'
alias f='fzf'
alias t='_tmux_newpane_or_newwindow'
alias v='t vim'

# clojure
alias clj-new='clj -Sdeps "{:deps {seancorfield/clj-new {:mvn/version \"1.1.216\"}}}" -m clj-new.create' # clj-new app <myname/myapp>
alias rebel='clojure -Sdeps "{:deps {com.bhauman/rebel-readline {:mvn/version \"0.1.4\"}}}" -m rebel-readline.main'
alias iced='test -f deps.edn -o -f project.clj && export ICED_OPT="" || export ICED_OPT="--instant"; tmux split-window -l 14 "iced repl $ICED_OPT"'

# prolog
alias pro='swipl -g main -s'
alias prologc='swipl -O -g main -c'
alias prologlint="swipl -g 'asserta(use_module(_)), current_prolog_flag(argv, [File]), load_files(File, [sandboxed(true)]), halt.'"

_defalias ls exa '--git'
_defalias lt exa '-TL2'
_defalias cat bat
_defalias diff colordiff '-u'
_defalias diff delta
_defalias vi vim '-u NONE -N'
#endregion

#region: clipboard
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    export DISPLAY=localhost:0.0
fi

# https://qiita.com/TakaakiFuruse/items/2a50cdd824d389f2adf4
# https://gist.github.com/tavisrudd/1169093/4312ed38fab576f3c801903d9b68198a5336db0c
if [ -n "$DISPLAY" ]; then
    bind -m emacs -x '"\C-u": _xdiscard'
    bind -m emacs -x '"\C-k": _xkill'
    bind -m emacs -x '"\C-y": _xyank'
fi
_xdiscard() {
    # TODO
    echo -n "${READLINE_LINE:0:$READLINE_POINT}" | xsel -bi
    READLINE_LINE="${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=0
}
_xkill() {
    echo -n "${READLINE_LINE:$READLINE_POINT}" | xsel -bi
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}"
}
_xyank() {
    CLIP=$(xsel -bo)
    COUNT=$(echo -n "$CLIP" | wc -c)
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}${CLIP}${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$(($READLINE_POINT + $COUNT))
}
#endregion

#region: fzf
export FZF_PREVIEW='test -f {} && bat --color=always --style=header,grid --line-range :100 {} || test -d {} && exa -T -L2 --color=always {}'
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
export FZF_DEFAULT_OPTS='--reverse --ansi --height 50% --border --inline-info'
export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --glob '!.git/*' 2> /dev/null"
export FZF_CTRL_T_OPTS="--preview '$FZF_PREVIEW'"
export FZF_ALT_C_COMMAND="find -type d | sed -e 's/^\.\///'"
export FZF_ALT_C_OPTS="--preview '$FZF_PREVIEW'"
#endregion

#region: clojure
# deps.edn
mkdir -p $HOME/.clojure
cat << 'EOS' > ~/.clojure/deps.edn
{
 :aliases {
   :instant {:extra-deps {org.clojure/math.numeric-tower {:mvn/version "0.0.4"}}}}
}
EOS

# profiles.clj
mkdir -p $HOME/.lein
cat << 'EOS' > ~/.lein/profiles.clj
{:user {:plugins [[lein-exec "0.3.7"]]}}
EOS

#endregion

#region: ~/.tmux.conf
cat << 'SHELL' > ~/.tmux.conf
set -g mouse on
set -g status-fg white
set -g status-bg "colour238"
setw -g window-status-current-format "#[fg=colour255,bg=colour27] #I: #W #[default]"

# enable <C-Arrow> in vim on tmux
set -g default-terminal "xterm-256color"
setw -g xterm-keys on

# keybind
unbind C-b
set -g prefix M-q
bind k confirm-before -p "kill-pane #P? (y/n)" kill-pane
bind -n M-n new-window
bind -n M-, previous-window
bind -n M-. next-window
bind -n M-^ split-window -h
bind -n M-- split-window -v
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R
bind -n M-H resize-pane -L
bind -n M-J resize-pane -D
bind -n M-K resize-pane -U
bind -n M-L resize-pane -R
bind -n M-f resize-pane -Z
bind -n M-i copy-mode
bind -n M-v run "xsel -bo | tmux load-buffer - && tmux paste-buffer"

# set copy-mode in order to copy until under the caret
setw -g mode-keys vi
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xsel -bi"
SHELL
#endregion

#region: start tmux
if type tmux > /dev/null 2>&1; then
    count=`ps aux | grep tmux | grep -v grep | wc -l`
    if test $count -eq 0; then
        echo `tmux -u2 `
    elif test $count -eq 1; then
        echo `tmux -u2 a`
    fi
fi
#endregion

