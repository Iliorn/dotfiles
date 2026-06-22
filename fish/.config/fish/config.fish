set -g fish_greeting ""

if status is-interactive
    # Prompt
    if type -q starship
        starship init fish | source
    end

    # Direnv
    if type -q direnv
        direnv hook fish | source
    end

    # Zoxide
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end

    # Fuzzy file and directory selection. Atuin keeps ownership of Ctrl-R.
    if type -q fzf
        set -gx FZF_CTRL_R_COMMAND ""
        set -gx FZF_CTRL_T_OPTS "--walker-skip .git,node_modules,target --preview 'bat --color=always --style=numbers --line-range=:500 {}'"
        fzf --fish | source
    end

    # Search shell history with context-aware filtering.
    if type -q atuin
        atuin init fish | source
    end

    # Better ls
    if type -q eza
        alias ls='eza --icons --group-directories-first -1'
    end

    # Fastfetch: small greeting every terminal
    if type -q fastfetch
        echo
        fastfetch
    end
end
set -gx EDITOR helix
fish_add_path ~/.local/bin

alias lg='lazygit'


# Added by Antigravity CLI installer
set -gx PATH "/home/mark/.local/bin" $PATH
