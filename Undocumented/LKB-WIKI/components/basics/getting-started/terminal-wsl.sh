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
    arch)
        # Refreshed system upgrade to prevent GUI dependency issues
        sudo pacman -Syu --noconfirm curl unzip wget git fontconfig zsh kitty \
            zsh-autosuggestions zsh-syntax-highlighting
        AUTOSUG=/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        SYNTAX=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
    *)
        echo "Error: This optimized script variant is configured for Arch Linux."
        exit 1
        ;;
esac

echo "Installing plugins..."

# Install zsh-autocomplete (overwrite-safe)
rm -rf ~/.zsh-autocomplete
git clone -q --depth 1 https://github.com ~/.zsh-autocomplete
rm -f ~/.zsh-autocomplete/.zshrc

# Create directories
mkdir -p ~/.local/share/fonts ~/.config/kitty ~/.config

# Install SpaceMono Nerd Font (silent)
wget -q -O ~/.local/share/fonts/SpaceMono.zip \
    https://github.com

unzip -qq -o ~/.local/share/fonts/SpaceMono.zip -d ~/.local/share/fonts
fc-cache -f >/dev/null 2>&1

# Write Kitty config optimized for WSLG rendering
cat > ~/.config/kitty/kitty.conf <<EOF
font_family SpaceMono Nerd Font
font_size 14.0
cursor_trail 100
hide_window_decorations yes
confirm_os_window_close 0
tab_bar_style powerline
tab_bar_min_tabs 2
tab_powerline_style round
shell /usr/bin/zsh
linux_display_server wayland
EOF

# Install Starship (silent)
curl -sS https://starship.rs | sh -s -- -y >/dev/null 2>&1
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

# Fix home and end keybinds in zsh
bindkey '\e[H' beginning-of-line
bindkey '\e[F' end-of-line
bindkey '\e[1;5D' backward-word
bindkey '\e[1;5C' forward-word
EOF

# Set ZSH as default shell
chsh -s "$(which zsh)"

echo ""
echo "Setup complete!"
echo "Please close your current WSL terminal window completely."
