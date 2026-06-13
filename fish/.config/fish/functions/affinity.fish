function affinity
    pkill -f wineserver 2>/dev/null; true
    command affinity $argv
end
