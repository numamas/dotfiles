#!/bin/bash

SCRIPT_PATH=$(readlink ${BASH_SOURCE:-$0} || echo ${BASH_SOURCE:-$0})
SCRIPT_DIR=$(cd $(dirname $SCRIPT_PATH); pwd)

declare -A link_table=(
    ['config/emacs.el']='$HOME/.emacs.el'
    ['config/tmux.conf']='$HOME/.tmux.conf'
    ['config/vimrc']='$HOME/.vimrc'
)

export PATH=`cat - << EOS | xargs -I{} echo -n '{}:' && echo -n $PATH
$SCRIPT_DIR/bin
$SCRIPT_DIR/scripts
$HOME/bin
$HOME/script
$HOME/go/bin
$HOME/.local/bin
$HOME/.vim/plugged/vim-iced/bin
EOS
`

_main () {
    # alias
_defalias cat bat
    alias b='_babashka_facilitated'
    alias t='_tmux_newpane_or_newwindow'

    _defalias clip xsel '-b'
    _defalias diff colordiff '-u' || _defalias diff delta
    _defalias em emacs '-nw'
    _defalias ls exa '--git'
    _defalias lt exa '-TL2'
    _defalias vi vim '-u NONE -N'
    
    # clojure
    alias clj-new='clj -Sdeps "{:deps {seancorfield/clj-new {:mvn/version \"1.1.216\"}}}" -m clj-new.create' # clj-new app <myname/myapp>
    alias rebel='clojure -Sdeps "{:deps {com.bhauman/rebel-readline {:mvn/version \"0.1.4\"}}}" -m rebel-readline.main'
    alias iced='test -f deps.edn -o -f project.clj && export ICED_OPT="" || export ICED_OPT="--instant"; tmux split-window -l 14 "iced repl $ICED_OPT"'

    # export
    export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    export PROMPT_DIRTRIM=3

    export DOTNET_CLI_TELEMETRY_OPTOUT=1

    # Proxy
    if [ -f "$HOME/config/proxy" ]; then
        source "$HOME/config/proxy"
    fi

    # Homebrew
    if [ -f '/home/linuxbrew/.linuxbrew/bin/brew' ]; then
        eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    fi

    _setup_clipboard
    _setup_fzf
    _main_wsl
    _start_tmux
}

_main_wsl () {
    if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
        # Clipboard sharing
        export DISPLAY=localhost:0.0
        export config=$HOME/shared/config

        # Prompt
        export PROMPT_COMMAND='path_color'
        export PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[\$(echo -n \$PATH_COLOR)m\]\w\[\033[00m\]\$ "

        path_color() {
            if [[ "$(pwd)" =~ /mnt/([a-z]|[a-z]/.*) ]]; then
                # Windows
                PATH_COLOR='01;35'
            else
                # Linux
                PATH_COLOR='01;34'
            fi
        }

        startvm() {
            name="$1"; port="$2"; user="$3"
            VBoxManage.exe startvm "$name" --type headless 2> /dev/null
            ssh -Y -p $port $user@localhost
        }

        # Load other config
        if [ -f "$config/wsl" ]; then
            source "$config/wsl"
        fi
    fi

}

_setup_clipboard () {
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
}

_setup_fzf () {
    export FZF_PREVIEW='test -f {} && bat --color=always --style=header,grid --line-range :100 {} || test -d {} && exa -T -L2 --color=always {}'
    export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
    export FZF_DEFAULT_OPTS='--reverse --ansi --height 50% --border --inline-info'
    export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --glob '!.git/*' 2> /dev/null"
    export FZF_CTRL_T_OPTS="--preview '$FZF_PREVIEW'"
    export FZF_ALT_C_COMMAND="find -type d | sed -e 's/^\.\///'"
    export FZF_ALT_C_OPTS="--preview '$FZF_PREVIEW'"
}

_start_tmux () {
    if type tmux > /dev/null 2>&1; then
        count=`ps aux | grep tmux | grep -v grep | wc -l`
        if test $count -eq 0; then
            echo `tmux -u2 `
        elif test $count -eq 1; then
            echo `tmux -u2 a`
        fi
    fi
}

# Utils
_blockinfile() {
    if [ $# != 2 ]; then
        echo 'error: wrong number of arguments' 1>&2
        return 2
    elif [ -t 0 ]; then
        echo 'error: stdin is empty' 1>&2
        return 3
    fi

    # args
    local file="$1"
    local marker="$2"
    local content=`cat -`

    # edit
    echo -n "  Editing $file for $marker block... "
    local begin="$marker __BEGIN__"
    local end="$marker __END__"
    local pattern="$begin[\s\S]*?$end"
    local block="$begin\n$content\n$end"
    if grep -qPzo "$pattern" "$file"; then
        python3 -c "import re; f = open('$file', 'r'); data = f.read(); f.close(); f = open('$file', 'w'); f.write(re.sub('''$pattern''', '''$block''', data)); f.close()"
        echo 'overwrite'
    else
        echo -e "\n$block" >> "$file"
        echo 'append'
    fi
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

_echosh () {
    echo "$*"
    eval "$*"
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

dump () {
    echo 'dump'
}

mkcd () {
    mkdir $1 && cd $1
}

setup_bin() {
    # essential
    apt_install build-essential curl colordiff fzf git ripgrep vim-gtk xsel
    brew_install bat exa node yarn

    # common lisp
    # https://moremagic.hateblo.jp/entry/2018/06/16/095231
    apt_install libcurl4-openssl-dev zlib1g-dev build-essential
    brew_install roswell

    # clojure
    brew_install leiningen borkdude/brew/babashka clojure

    # go
    brew_install go
    go get -u golang.org/x/tools/cmd/gopls
    go get -u golang.org/x/tools/cmd/goimports

    # typescript
    brew_install typescript

    # others
    # brew_install erlang
    # brew_install nim
}

slink () {
    local opts=''
    if [ "$1" = "-f" ]; then
        opts="-f"
    fi
    for key in ${!link_table[@]}; do
        _echosh ln -s $opts "$SCRIPT_DIR/$key" $(eval echo "${link_table[$key]}")
    done
}

template () {
    echo 'template TEPLATE_NAME DIR_NAME'
}

_main
