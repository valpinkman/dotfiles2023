#!/bin/bash
############################
# install.sh — re-runnable
############################
set -euo pipefail

dir=~/dotfiles
olddir=~/dotfiles_old

# link <src> <dest>: back up a real file/dir to $olddir, then (re)create the symlink
link() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local rel=${dest#"$HOME"/}
    mkdir -p "$olddir/$(dirname "$rel")"
    mv "$dest" "$olddir/$rel"
  fi
  ln -sfn "$src" "$dest"
  echo "linked $dest -> $src"
}

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing xcode-stuff"
  xcode-select --install
fi

if ! command -v brew >/dev/null; then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v proto >/dev/null; then
  echo "Installing proto..."
  curl -fsSL https://moonrepo.dev/install/proto.sh | bash
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Installing Brewfile..."
brew update
brew bundle --file "$dir/Brewfile"
brew cleanup

fish_bin=/opt/homebrew/bin/fish
if ! grep -qx "$fish_bin" /etc/shells; then
  echo "$fish_bin" | sudo tee -a /etc/shells
fi
[ "$SHELL" = "$fish_bin" ] || chsh -s "$fish_bin"

for file in gemrc gitconfig gitignore vimrc; do
  link "$dir/$file" ~/".$file"
done

mkdir -p ~/.ssh ~/.bin
link "$dir/config" ~/.ssh/config
link "$dir/fish" ~/.config/fish
link "$dir/starship.toml" ~/.config/starship.toml
link "$dir/aerospace.toml" ~/.config/aerospace/aerospace.toml
link "$dir/jj/config.toml" ~/.config/jj/config.toml

echo "AI coding setup"
for target in ~/.claude ~/.config/opencode ~/.gemini; do
  for name in skills agents; do
    link "$dir/ai/$name" "$target/$name"
  done
done

killall Finder || true
