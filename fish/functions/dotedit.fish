function dotedit --wraps='cd ~/dotfiles && cursor .' --description 'alias dot=cd ~/dotfiles && cursor .'
  cd ~/dotfiles;
  cursor . $argv;
end