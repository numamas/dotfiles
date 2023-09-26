#!/bin/bash
# vim: foldmethod=marker foldmarker={,} :
set -u
SCRIPT_DIR=$(cd "$(dirname "$(readlink "${BASH_SOURCE:-$0}" || echo "${BASH_SOURCE:-$0}")")"; pwd)

: 'default' && {
    alias vi='nvim'
    alias sudo='sudo ' # in order to expand first argument as an alias
    alias grep='grep --color=auto'
    alias ls='ls --color=auto --si --group-directories-first --classify'

    export EDITOR='vim'
    export USER_CONFIG_DEFAULT="$HOME/shared/config"
    export PROMPT_COMMAND=":"
    export EXIT_TRAP_COMMAND=":"
    
    # display
    if [ -f '/proc/sys/fs/binfmt_misc/WSLInterop' ]; then
        export DISPLAY=localhost:0.0
        # export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
    fi

    # prompt
    export PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[\$(echo -n \$PATH_COLOR)m\]\w\[\033[00m\]\$ "
    export PROMPT_DIRTRIM=3
    export PROMPT_COMMAND="$PROMPT_COMMAND; set_path_color"

    set_path_color() {
        if [[ "$(pwd)" =~ /mnt/([a-z]|[a-z]/.*) ]]; then
            PATH_COLOR='01;35' # Windows
        else
            PATH_COLOR='01;34' # Linux
        fi
    }
}

: 'path' && {
    # path
    declare -a path_list=(
        "$SCRIPT_DIR/bin"
        "$SCRIPT_DIR/scripts"
        "$HOME/.local/bin"
        "$HOME/.local/eget"
        "$HOME/.luarocks/bin"
        "$HOME/bin"
        "$HOME/go/bin"
    )
    # shellcheck disable=2155
    export PATH="$(IFS=$':'; echo "${path_list[*]}"):$PATH"
}

: 'keymaps' && {
    readline_dismiss() {
        READLINE_LINE_TEMP="$READLINE_LINE"
        READLINE_POINT_TEMP="$READLINE_POINT"
        READLINE_LINE=''
        READLINE_POINT=0
    }

    readline_restore() {
        READLINE_LINE="$READLINE_LINE_TEMP"
        READLINE_POINT="$READLINE_POINT_TEMP"
        unset READLINE_LINE_TEMP
        unset READLINE_POINT_TEMP
    }

    # cd_stack
    PROMPT_COMMAND="$PROMPT_COMMAND; __cd_stack_push__"

    __cd_stack_push__() {
        if [ -z "${CD_STACK:-}" ]; then
            CD_STACK_POS=0
            CD_STACK[$CD_STACK_POS]="$PWD"
        fi
        if [ "$PWD" != "${CD_STACK[$CD_STACK_POS]}" ]; then
            CD_STACK_POS=$((CD_STACK_POS + 1))
            CD_STACK[$CD_STACK_POS]="$PWD"

            # remove padding
            for ((i = $((CD_STACK_POS + 1)); i < ${#CD_STACK[@]}; i++)); do
                unset "CD_STACK[$i]"
            done
            CD_STACK=("${CD_STACK[@]}")
        fi
    }

    __cd_stack_move__() {
        local index="$1"
        local size="${#CD_STACK[@]}"

        if [ "$index" -lt 0 ] || [ "$index" -gt $((size - 1)) ]; then
            # echo 'No newer or older entry exists.' > /dev/stderr
            return
        fi

        CD_STACK_POS="$index"
        local dest="${CD_STACK[$CD_STACK_POS]}"
        if [ -n "$dest" ]; then
            cd "$dest" || return
        fi
    }

    __cd_stack_next__() {
        __cd_stack_move__ $((CD_STACK_POS + 1))
    }

    __cd_stack_prev__() {
        __cd_stack_move__ $((CD_STACK_POS - 1))
    }


    if [ -t 1 ]; then
        bind -x '"\C-x1": readline_dismiss' 2>/dev/null
        bind -x '"\C-x0": readline_restore' 2>/dev/null

        # Alt + Up : move to parent directory
        bind -x '"\C-x2": cd ..'              2>/dev/null
        bind '"\e[1;3A": "\C-x1\C-x2\n\C-x0"' 2>/dev/null

        # Alt + Left : move backward cd history
        bind -x '"\C-x3": __cd_stack_prev__'  2>/dev/null
        bind '"\e[1;3D": "\C-x1\C-x3\n\C-x0"' 2>/dev/null

        # Alt + Right : move forward cd history
        bind -x '"\C-x4": __cd_stack_next__'  2>/dev/null
        bind '"\e[1;3C": "\C-x1\C-x4\n\C-x0"' 2>/dev/null
    fi

    # xsel
    # https://gist.github.com/tavisrudd/1169093/4312ed38fab576f3c801903d9b68198a5336db0c
    __xsel_discard__() {
        echo -n "${READLINE_LINE:0:$READLINE_POINT}" | xsel -bi
        READLINE_LINE="${READLINE_LINE:$READLINE_POINT}"
        READLINE_POINT=0
    }

    __xsel_kill__() {
        echo -n "${READLINE_LINE:$READLINE_POINT}" | xsel -bi
        READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}"
    }

    __xsel_yank__() {
        CLIP=$(xsel -bo)
        COUNT=$(echo -n "$CLIP" | wc -c)
        READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}${CLIP}${READLINE_LINE:$READLINE_POINT}"
        READLINE_POINT=$((READLINE_POINT + COUNT))
    }

    if [ -n "$DISPLAY" ] && type xsel > /dev/null 2>&1; then
        bind -x '"\C-u": __xsel_discard__' 2>/dev/null
        bind -x '"\C-k": __xsel_kill__'    2>/dev/null
        bind -x '"\C-y": __xsel_yank__'    2>/dev/null
    fi
}

: 'z' && {
    Z_FILE="$HOME/.zfile"
    Z_FILE_MAX=500

    __z_var__() {
        echo "containts"
        echo "  Z_FILE = $Z_FILE"
        echo "  Z_FILE_MAX = $Z_FILE_MAX"
        echo "veriables"
        echo "  #Z_DATA_NEW = ${#Z_DATA_NEW[@]}"
        echo "  #Z_DATA_LOADED = ${#Z_DATA_LOADED[@]}"
    }

    __z_init__() {
        if [ ! -f "$Z_FILE" ]; then
            "$Z_FILE not found"
            touch "$Z_FILE"
            return
        fi
        mapfile -t Z_DATA_LOADED < <(tac "$Z_FILE" | __z_refine__ | tac | tail -n "$Z_FILE_MAX")

        # update $Z_FILE
        (IFS=$'\n'; echo "${Z_DATA_LOADED[*]}") > "$Z_FILE"
    }

    __z_add__() {
        if [ -z "${Z_DATA_NEW:-}" ] || [ "$PWD" != "${Z_DATA_NEW[-1]}" ]; then
            Z_DATA_NEW+=("$PWD")
        fi
    }

    __z_save__() {
        (IFS=$'\n'; echo "${Z_DATA_NEW[*]}") >> "$Z_FILE"
    }

    __z_show__() {
        (IFS=$'\n'; echo "${Z_DATA_LOADED[*]}"; echo "${Z_DATA_NEW[*]}") | tac | __z_refine__
    }

    __z_refine__() {
        grep -xv '/' | grep -xv '' | awk '!a[$0]++'
    }

    __z_init__

    alias z='cd "$(__z_show__ | fzf)"'
    PROMPT_COMMAND="$PROMPT_COMMAND; __z_add__"
    EXIT_TRAP_COMMAND="$EXIT_TRAP_COMMAND; __z_save__"
}

: 'config: fzf' && {
    export FZF_PREVIEW='test -f {} && bat --color=always --style=header,grid --line-range :100 {} || test -d {} && exa -T -L2 --color=always {}'
    export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
    export FZF_DEFAULT_OPTS='--reverse --ansi --height 50% --border --inline-info'
    export FZF_COMPLETION_TRIGGER=','
    export FZF_COMPLETION_OPTS="--preview '$FZF_PREVIEW'"
    export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --glob '!.git/*' 2> /dev/null"
    export FZF_CTRL_T_OPTS="--preview '$FZF_PREVIEW'"
    export FZF_ALT_C_OPTS="--preview '$FZF_PREVIEW'"

}

: 'config: git' && {
    if type delta > /dev/null 2>&1; then
        alias diff='delta'
        export GIT_PAGER='delta -s'
    fi

    git config --global alias.s status
    git config --global alias.d difftool
    git config --global alias.ds 'difftool --cached'
    git config --global alias.addp '!vim -c Gdiff'
    git config --global alias.drop 'reset --soft HEAD^'
    git config --global alias.chmod 'update-index --add --chmod'
    git config --global difftool.prompt false

    # nvimdiff
    # https://yu8mada.com/2018/08/21/i-tried-configuring-for-git-s-difftool-and-mergetool-commands-to-use-neovim
    git config --global difftool.nvimdiff.cmd 'nvim -R -d -c "wincmd l" -d "$LOCAL" "$REMOTE"'
    git config --global mergetool.nvimdiff.cmd 'nvim -d -c "4wincmd w | wincmd J" "$LOCAL" "$BASE" "$REMOTE" "$MERGED"'

    if type nvim > /dev/null 2>&1; then
        git config --global diff.tool nvimdiff
    else
        git config --global diff.tool vimdiff
    fi
}

: 'config: nnn' && {
    # shellcheck disable=2262
    alias nnn='nnn -edo'
    export NNN_COLORS='#0a1b2c3d;1234'

    alias n='__nnn_cd__'
    bind -m emacs -x '"\C-o": __nnn_select__' 2>/dev/null

    function __nnn_select__ {
        # Don't nest command substitution with interactive commands.
        # Inputting 'C-c' breaks the terminal when using interactive command inside command substitution.
        local selected
        selected=$(nnn_select_on_tmux | tr '\n' ' ')
        if [ "$selected" != " " ] && [ "$selected" != "" ]; then
            READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
            READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
        fi
    }

    function nnn_select_on_tmux {
        # create FIFO
        id=$RANDOM
        fifo_stdout="${TMPDIR:-/tmp}/nnn-fifo-$id-stdout"
        mkfifo -m o+w "$fifo_stdout"

        # trap for cleanup
        trap 'cleanup' EXIT
        function cleanup {
            rm -f "$fifo_stdout"
        }

        # execute
        tmux split-window -v "stty start undef; stty stop undef; nnn -p '-' > $fifo_stdout"

        # read results
        cat "$fifo_stdout"
    }

    function __nnn_cd__ {
        # https://github.com/jarun/nnn/blob/master/misc/quitcd/quitcd.bash_zsh

        # Block nesting of nnn in subshells
        if [ -n "${NNNLVL:-}" ] && [ "${NNNLVL:-0}" -ge 1 ]; then
            echo "nnn is already running"
            return
        fi

        # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
        # To cd on quit only on ^G, remove the "export" as in:
        NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
        # export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

        # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
        stty start undef   # C-q
        stty stop undef    # C-s
        # stty lwrap undef
        # stty lnext undef

        nnn -nA -edo "$@"

        if [ -f "$NNN_TMPFILE" ]; then
            # shellcheck disable=1090
            source "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
        fi
    }
}

: 'source' && {
    if [ -f "${USER_CONFIG:-$USER_CONFIG_DEFAULT}/proxy" ]; then
        source "${USER_CONFIG:-$USER_CONFIG_DEFAULT}/proxy"
    fi

    if [ -f "${USER_CONFIG:-$USER_CONFIG_DEFAULT}/user.bash" ]; then
        source "${USER_CONFIG:-$USER_CONFIG_DEFAULT}/user.bash"
    fi
}

# shellcheck disable=2064
trap "$EXIT_TRAP_COMMAND" EXIT SIGHUP SIGQUIT SIGTERM

: 'start tmux' && {
    export PROMPT_COMMAND="$PROMPT_COMMAND; tmux_set_pwd"
    tmux_set_pwd() {
        # not to resolve symlink with new-window instead of #{pane_current_path}
        # https://unix.stackexchange.com/questions/212667/how-can-i-make-tmux-tell-bash-to-display-the-logical-version-of-the-current-di
        [ -n "${TMUX:-}" ] && tmux setenv "TMUXPWD_$(tmux display -p '#I')" "$PWD"
    }

    if type tmux > /dev/null 2>&1; then
        # count=$(ps aux | grep tmux | grep -v grep | wc -l)
        count=$(pgrep -c tmux)
        if test "$count" -eq 0; then
            tmux -u2
        elif test "$count" -eq 1; then
            tmux -u2 a
        fi
    fi
}
