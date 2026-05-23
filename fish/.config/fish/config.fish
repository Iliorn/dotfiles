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
set -gx EDITOR hx
atuin init fish | source
set -Ux EDITOR /usr/lib/helix/hx
