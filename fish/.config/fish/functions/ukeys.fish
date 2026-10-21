function ukeys --description 'Commit tracked dotfile changes and push'
    git -C ~/dotfiles add -u
    and git -C ~/dotfiles commit -m "Update: $(date)"
    and git -C ~/dotfiles push
end
