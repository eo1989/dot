# External plugins

eval %sh{
    kak-lsp --kakoune -s $kak_session
    colorcol
}

# Initialization

require-module connect-skim

decl -hidden regex curword
decl -hidden regex curword_word_class

set global ui_options ncurses_assistant=none
set global scrolloff 7,7
set global autoreload yes
set global grepcmd 'rg -iHL --column'
set global modelinefmt '%opt{modeline_git_branch} %val{bufname}
%val{cursor_line}:%val{cursor_char_column} {{mode_info}}
{{context_info}}◂%val{client}⊙%val{session}▸'

alias global sw sudo-write
alias global cdb change-directory-current-buffer
alias global f find
alias global g grep
alias global s sort-selections
alias global explore-files skim-files
alias global explore-buffers skim-buffers

face global LineNumbersWrapped black
face global CurWord +b

addhl global/number-lines number-lines -hlcursor -separator ' '
addhl global/ruler column 100 default,rgb:303030
addhl global/trailing-whitespace regex '\h+$' 0:default,red
addhl global/todo regex \b(TODO|FIXME|XXX|NOTE)\b 0:default+rb
addhl global/matching-brackets show-matching
addhl global/wrap wrap -word -indent -marker ''
addhl global/current-word dynregex '%opt{curword}' 0:CurWord

# Keybinds

map global normal <space> ,
map global normal -docstring 'remove all sels except main' <backspace> <space>
map global normal -docstring 'remove main sel' <a-backspace> <a-space>
map global normal -docstring 'comment line' '#' ': comment-line<ret>'
map global normal -docstring 'comment block' '<a-#>' ': comment-block<ret>'
map global normal -docstring 'delete to end of line' D <a-l>d
map global normal -docstring 'yank to end of line' Y <a-l>
map global user -docstring 'replay macro' . q
map global user -docstring 'record macro' <a-.> Q

map global normal w ': word-select-next-word<ret>'
map global normal <a-w> ': word-select-next-big-word<ret>'
map global normal q ': word-select-previous-word<ret>'
map global normal <a-q> ': word-select-previous-big-word<ret>'
map global normal Q B
map global normal <a-Q> <a-B>

map global user -docstring 'replace mode' r ': replace<ret>'

map global user -docstring 'expand selection' e ': expand<ret>'
map global user -docstring 'expand repeat' E ': expand-repeat<ret>'

map global normal -docstring 'buffers…' b ': enter-buffers-mode<ret>'
map global normal -docstring 'buffers (lock)…' B ': enter-user-mode -lock buffers<ret>'
map global normal -docstring 'select buffer' <a-b> ': explore-buffers<ret>'

declare-user-mode anchor
map global normal ';' ': enter-user-mode anchor<ret>'
map global anchor -docstring 'ensure anchor after cursor' h '<a-:><a-;>'
map global anchor -docstring 'ensure cursor after anchor' l '<a-:>'
map global anchor -docstring 'flip cursor and anchor' f '<a-;>'
map global anchor -docstring 'reduce to anchor' a '<a-;>;'
map global anchor -docstring 'reduce to cursor' c ';'
map global anchor -docstring 'select cursor and anchor' s '<a-S>'

declare-user-mode clipboard
map global normal ',' ': enter-user-mode clipboard<ret>'
map global clipboard -docstring 'clip-paste after' p '<a-!>xsel -b -o<ret>'
map global clipboard -docstring 'clip-paste before' P '!xsel -b -o<ret>'
map global clipboard -docstring 'clip-paste replace' R '|xsel -b -o<ret>'
map global clipboard -docstring 'clip-yank' y '<a-|>xclip -i -f -sel c<ret>'
map global clipboard -docstring 'clip-cut' d '<a-|>xclip -i -f -sel c<ret><a-d>'
map global clipboard -docstring 'clip-cut -> insert mode' c '<a-|>xclip -i -f -sel c<ret><a-c>'

# Functions

def type -params 1 -docstring 'Set buffer filetype' %{
    set buffer filetype %arg{1}
}

def lint-engage -docstring 'Enable linting' %{
    lint-enable
    map global user -docstring "next error" l ': lint-next-error<ret>'
    map global user -docstring "previous error" L ': lint-previous-error<ret>'
}

def lsp-engage -docstring 'Enable language server' %{
    lsp-enable
    lsp-auto-hover-enable
    map global user -docstring 'Enter lsp user mode' <a-l> ': enter-user-mode lsp<ret>'
}

def lsp-semantic-highlighting -docstring 'Enable semantic highlighting' %{
    hook window -group semantic-tokens BufReload .* lsp-semantic-tokens
    hook window -group semantic-tokens NormalIdle .* lsp-semantic-tokens
    hook window -group semantic-tokens InsertIdle .* lsp-semantic-tokens
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window semantic-tokens
    }
}

def lint-on-write -docstring 'Activate linting on buffer write' %{
    lint-engage
    hook buffer BufWritePost .* lint
}

def set-indent -params 1 -docstring 'Set indentation width' %{
    set buffer indentwidth %arg{1}
    set buffer tabstop %arg{1}
    set buffer softtabstop %arg{1}
}

def no-tabs -params 1 -docstring 'Indent with spaces' %{
    expandtab
    set-indent %arg{1}
    hook buffer InsertKey <space> %{ try %{
        exec -draft h<a-i><space><a-k>^\h+<ret>
        exec -with-hooks <tab>
    }}
}

def clean-trailing-whitespace -docstring 'Remove trailing whitespace' %{
    try %{ exec -draft '%s\h+$<ret>d' }
}

# Hooks

hook global WinCreate .* %{
    smarttab
    readline-enable
    colorcol-enable
    colorcol-refresh-continuous
}

hook global KakBegin .* %{
    state-save-reg-load colon
    state-save-reg-load pipe
    state-save-reg-load slash
}

hook global KakEnd .* %{
    state-save-reg-save colon
    state-save-reg-save pipe
    state-save-reg-save slash
}

hook global WinDisplay .* info-buffers

hook global BufWritePre .* %{ nop %sh{
    mkdir -p "$(dirname "$kak_buffile")"
}}

hook global NormalIdle .* %{
    eval -draft %{
        try %{
            exec <space><a-i>w
            set buffer curword "(?<!%opt{curword_word_class})\Q%val{selection}\E(?!%opt{curword_word_class})"
        } catch %{
            set buffer curword ''
        }
    }
}

hook global WinSetOption extra_word_chars=.* %{
    eval %sh{
        eval set -- "$kak_quoted_opt_extra_word_chars"
        word_class='['
        while [ $# -ne 0 ]; do
            case "$1" in
                -) word_class="$word_class-";;
            esac
            shift
        done
        word_class="$word_class"'\w'
        eval set -- "$kak_quoted_opt_extra_word_chars"
        while [ $# -ne 0 ]; do
            case "$1" in
                "-") ;;
                "]") word_class="$word_class"'\]';;
                "'") word_class="$word_class''";;
                *)   word_class="$word_class$1";;
            esac
            shift
        done
        word_class="$word_class]"
        printf "set window curword_word_class '%s'\\n" "$word_class"
    }
}

eval %sh{ git rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null && printf %s "
    hook global BufWritePost .* %{ git show-diff }
    hook global BufReload .* %{ git show-diff }
"}

hook global ModuleLoaded kitty %{
    set global kitty_window_type kitty
}

# Filetype detection

hook global BufCreate .*srcpkgs/.+/template$ %{
    set buffer filetype sh
    def xgensum %{ %sh{ xgensum -i "$kak_buffile" } }
}

hook global BufCreate .*/\.?((sx|xinit)(rc)?|profile) %{ set buffer filetype sh }
hook global BufCreate .*\.ino %{ set buffer filetype cpp }
hook global BufCreate .*\.cs %{ addhl buffer/java }
hook global BufCreate .*\.rasi %{ set buffer filetype css }
hook global BufCreate .*\.sccprofile %{ set buffer filetype json }

# Filetype settings

hook global WinSetOption filetype=sh %{
    set buffer lintcmd 'shellcheck --norc -x -f gcc'
    lint-on-write
}

hook global WinSetOption filetype=elvish %{
    no-tabs 2
}

hook global WinSetOption filetype=go %{
    lsp-engage
}

hook global WinSetOption filetype=(c|cpp) %{
    set buffer formatcmd clang-format
    lsp-engage
}

hook global WinSetOption filetype=rust %{
    lsp-engage
    hook window -group rust-inlay-hints BufReload .* rust-analyzer-inlay-hints
    hook window -group rust-inlay-hints NormalIdle .* rust-analyzer-inlay-hints
    hook window -group rust-inlay-hints InsertIdle .* rust-analyzer-inlay-hints
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window rust-inlay-hints
    }
}

hook global WinSetOption filetype=markdown %{
    set buffer formatcmd 'prettier --parser markdown'
    def render -docstring 'render current buffer' %{
        exec ": connect-terminal glow -s dark %val{buffile} | ${PAGER}<ret>"
    }
}

hook global WinSetOption filetype=python %{
    set global lsp_server_configuration pyls.plugins.jedi_completion.include_params=false
    lsp-engage
}

hook global WinSetOption filetype=nim %{
    set buffer gdb_program 'nim-gdb'
    set buffer formatcmd 'nimprettify'
    set buffer makecmd 'nimble build'
    no-tabs 2
    lsp-engage
}
