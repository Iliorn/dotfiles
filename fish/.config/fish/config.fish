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

    # Shell colours: Nord
    set -g fish_color_normal D8DEE9
    set -g fish_color_command 88C0D0
    set -g fish_color_param D8DEE9
    set -g fish_color_keyword 81A1C1
    set -g fish_color_error BF616A
    set -g fish_color_comment 6B7688
    set -g fish_color_quote A3BE8C
    set -g fish_color_autosuggestion 4C566A
    set -g fish_color_operator 8FBCBB
    set -g fish_color_redirection B48EAD
    set -g fish_color_escape EBCB8B
    set -g fish_color_end 81A1C1
    set -g fish_color_option D8DEE9
    set -g fish_color_cwd 88C0D0
    set -g fish_color_user A3BE8C
    set -g fish_color_host 81A1C1
    set -g fish_color_valid_path --underline
    set -g fish_color_match --background=434C5E
    set -g fish_color_search_match --background=434C5E
    set -g fish_color_selection --background=434C5E
    set -g fish_pager_color_prefix 88C0D0 --bold
    set -g fish_pager_color_completion D8DEE9
    set -g fish_pager_color_description 6B7688
    set -g fish_pager_color_progress 6B7688
    set -g fish_pager_color_selected_background --background=434C5E
    set -g fish_pager_color_selected_prefix 88C0D0 --bold
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
