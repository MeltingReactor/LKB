#!/usr/bin/env bash

echo ""
set -e

# Detect distro
. /etc/os-release
DISTRO=$ID

echo "Detected distro: $DISTRO"
echo ""

# Install dependencies
case "$DISTRO" in
    ubuntu|debian)
        sudo apt update -qq
        sudo apt install -y curl unzip wget zsh kitty \
            zsh-autosuggestions zsh-syntax-highlighting
        AUTOSUG=/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        SYNTAX=/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
    fedora)
        sudo dnf install -y curl unzip wget zsh kitty \
            zsh-autosuggestions zsh-syntax-highlighting
        AUTOSUG=/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        SYNTAX=/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
    arch)
        sudo pacman -Sy --noconfirm curl unzip wget zsh kitty \
            zsh-autosuggestions zsh-syntax-highlighting
        AUTOSUG=/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        SYNTAX=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
    opensuse*|suse)
        sudo zypper install -y curl unzip wget zsh kitty \
            zsh-autosuggestions zsh-syntax-highlighting
        AUTOSUG=/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        SYNTAX=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
    alpine)
        sudo apk add curl unzip wget fontconfig zsh kitty-terminfo
        rm -rf ~/.zsh-autosuggestions ~/.zsh-syntax-highlighting
        git clone -q https://github.com/zsh-users/zsh-autosuggestions ~/.zsh-autosuggestions
        git clone -q https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-syntax-highlighting
        AUTOSUG=~/.zsh-autosuggestions/zsh-autosuggestions.zsh
        SYNTAX=~/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
esac

echo "Installing..."

# Install zsh-autocomplete (overwrite-safe)
rm -rf ~/.zsh-autocomplete
git clone -q --depth 1 https://github.com/marlonrichert/zsh-autocomplete ~/.zsh-autocomplete

# IMPORTANT FIX: remove its internal .zshrc to prevent auto-loading
rm -f ~/.zsh-autocomplete/.zshrc

# Create directories
mkdir -p ~/.local/share/fonts ~/.config/kitty ~/.config

# Install SpaceMono Nerd Font (silent)
wget -q -O ~/.local/share/fonts/SpaceMono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SpaceMono.zip

unzip -qq -o ~/.local/share/fonts/SpaceMono.zip -d ~/.local/share/fonts
fc-cache -f >/dev/null 2>&1

# Write Kitty config
cat > ~/.config/kitty/kitty.conf <<EOF
font_family SpaceMono Nerd Font
font_size 15.0
cursor_trail 100
hide_window_decorations no
tab_bar_style powerline
tab_bar_min_tabs 1
tab_powerline_style round
shell /usr/bin/zsh
EOF

# Install Starship (silent)
curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1
starship preset catppuccin-powerline -o ~/.config/starship.toml >/dev/null 2>&1

# Remove old plugin block
sed -i '/# ZSH Plugins/,$d' ~/.zshrc 2>/dev/null || true

# Add plugin block
cat >> ~/.zshrc <<EOF

# ZSH Plugins
source $AUTOSUG
source $SYNTAX
source ~/.zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Starship prompt
eval "\$(starship init zsh)"
EOF

# Set ZSH as default shell
chsh -s "$(which zsh)"

echo ""
echo "To complete, log out then log back in."
echo "Done."
