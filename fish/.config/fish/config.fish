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
        set -gx FZF_DEFAULT_OPTS "--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#616E88,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#81A1C1"
        fzf --fish | source
    end

    # Search shell history with context-aware filtering.
    if type -q atuin
        atuin init fish | source
    end

    # Shell colours: the terminal's own 16, so they follow theme.sh through
    # alacritty's theme.toml, live, and over SSH too. Highlights are reversed,
    # not a grey background: some palettes' grey is too light to read text on.
    set -g fish_color_normal normal
    set -g fish_color_command cyan
    set -g fish_color_param normal
    set -g fish_color_keyword blue
    set -g fish_color_error red
    set -g fish_color_comment brblack
    set -g fish_color_quote green
    set -g fish_color_autosuggestion brblack
    set -g fish_color_operator brcyan
    set -g fish_color_redirection magenta
    set -g fish_color_escape yellow
    set -g fish_color_end blue
    set -g fish_color_option normal
    set -g fish_color_cwd cyan
    set -g fish_color_user green
    set -g fish_color_host blue
    set -g fish_color_valid_path --underline
    set -g fish_color_match --reverse
    set -g fish_color_search_match --reverse
    set -g fish_color_selection --reverse
    set -g fish_pager_color_prefix cyan --bold
    set -g fish_pager_color_completion normal
    set -g fish_pager_color_description brblack
    set -g fish_pager_color_progress brblack
    set -g fish_pager_color_selected_background --reverse
    set -g fish_pager_color_selected_prefix cyan --bold
    set -g fish_pager_color_selected_completion ECEFF4
    set -g fish_pager_color_selected_description D8DEE9

    alias lg='lazygit'

    # Better ls
    if type -q eza
        alias ls='eza --icons --group-directories-first -1'
    end

    # Superfile wrapper: return to the last Superfile directory on quit.
    if type -q spf
        function spf
            set os (uname -s)
            set spf_last_dir ""

            if test "$os" = "Linux"
                set spf_last_dir "$HOME/.local/state/superfile/lastdir"
            else if test "$os" = "Darwin"
                set spf_last_dir "$HOME/Library/Application Support/superfile/lastdir"
            end

            command spf $argv

            if test -n "$spf_last_dir"; and test -f "$spf_last_dir"
                source "$spf_last_dir"
                rm -f -- "$spf_last_dir" >/dev/null
            end
        end
    end

    # Fastfetch greets a new terminal only, not subshells or zellij panes.
    if type -q fastfetch; and test "$SHLVL" -le 1; and not set -q ZELLIJ
        echo
        fastfetch
    end
end
set -gx EDITOR helix
set -gx VISUAL helix
fish_add_path ~/.local/bin
