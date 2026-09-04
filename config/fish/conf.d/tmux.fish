# tmux quality-of-life shortcuts
abbr -a tls 'tmux ls'                 # list running sessions

# t [name] — attach to session (or create it) ; plain `t` uses "main"
function t --description "attach to or create a tmux session"
    set -l name (count $argv > /dev/null; and echo $argv[1]; or echo main)
    tmux new-session -A -s $name
end
