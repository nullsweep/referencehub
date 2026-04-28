#!/usr/bin/env bash
# =============================================================================
#  Personal Linux Mint / Ubuntu Setup Script — Interactive Edition
#  Asks which tools you want at each stage before installing anything
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✔]${NC} $1"; }
info()    { echo -e "${BLUE}[→]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
skip()    { echo -e "${YELLOW}[–]${NC} Skipped: $1"; }
section() {
  echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${NC}"
}

if [[ $EUID -eq 0 ]]; then
  echo -e "${RED}Do not run as root.${NC}"; exit 1
fi

# ── ask yes/no for a whole stage ─────────────────────────────────────────────
ask_stage() {
  echo -e "\n${BOLD}${BLUE}Run stage: $1?${NC} [Y/n] "
  read -r ans; [[ "${ans,,}" != "n" ]]
}

# ── pick_tools: numbered checklist, sets SELECTED array ──────────────────────
SELECTED=()
pick_tools() {
  local label="$1"; shift
  local tools=("$@")
  SELECTED=()

  echo -e "\n${BOLD}${CYAN}${label}${NC}"
  for (( i=0; i<${#tools[@]}; i++ )); do
    echo -e "  ${GREEN}[$((i+1))]${NC} ${tools[$i]}"
  done
  echo -e "\n${YELLOW}Enter numbers to SKIP (space-separated), Enter = install ALL, 'none' = skip all:${NC}"
  read -r skip_input

  if [[ "${skip_input,,}" == "none" ]]; then
    return
  fi

  local skip_nums=($skip_input)
  for (( i=0; i<${#tools[@]}; i++ )); do
    local skip_this=false
    for s in "${skip_nums[@]:-}"; do
      [[ "$s" == "$((i+1))" ]] && skip_this=true && break
    done
    if [[ "$skip_this" == "false" ]]; then
      SELECTED+=("${tools[$i]}")
    else
      skip "${tools[$i]}"
    fi
  done
}

in_selected() {
  for s in "${SELECTED[@]:-}"; do [[ "$s" == "$1" ]] && return 0; done
  return 1
}

INSTALLED_STAGES=()

# ── BANNER ───────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${BLUE}"
echo "  ██████╗ ███████╗████████╗██╗   ██╗██████╗ "
echo "  ██╔═══╝ ██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
echo "  ███████╗█████╗     ██║   ██║   ██║██████╔╝"
echo "  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ "
echo "  ██████╔╝███████╗   ██║   ╚██████╔╝██║     "
echo "  ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
echo -e "${NC}"
echo -e "${BOLD}  Personal Linux Mint / Ubuntu Deployment Script${NC}"
echo -e "  Interactive — choose tools at each stage\n"
echo -e "${YELLOW}  Tip: Press Enter at any selection to install ALL items.${NC}\n"

# =============================================================================
#  STAGE 1 — SYSTEM ESSENTIALS
# =============================================================================
section "Stage 1 · System Essentials"
if ask_stage "System Essentials"; then
  INSTALLED_STAGES+=("System Essentials")
  info "Running apt update & upgrade..."
  sudo apt update && sudo apt upgrade -y

  pick_tools "Core system packages" \
    "curl" "wget" "git" "gpg" "ca-certificates" "apt-transport-https" \
    "build-essential" "software-properties-common" \
    "ufw" "fail2ban" \
    "flameshot" "timeshift" "keepassxc" \
    "htop" "btop" "neofetch" \
    "tmux" "fzf" "ripgrep" "bat" "fd-find" \
    "python3" "python3-pip" "python3-venv" \
    "net-tools" "dnsutils" "traceroute" "netcat-openbsd"

  [[ ${#SELECTED[@]} -gt 0 ]] && sudo apt install -y "${SELECTED[@]}" && log "System packages installed"

  if in_selected "ufw"; then
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    log "UFW enabled"
  fi
else
  skip "Stage 1"
fi

# =============================================================================
#  STAGE 2 — SHELL
# =============================================================================
section "Stage 2 · Shell (Zsh + Oh My Zsh + Powerlevel10k)"
if ask_stage "Shell setup"; then
  INSTALLED_STAGES+=("Shell")

  pick_tools "Shell components" \
    "zsh" \
    "oh-my-zsh" \
    "powerlevel10k theme" \
    "plugin: zsh-autosuggestions" \
    "plugin: zsh-syntax-highlighting" \
    "write .zshrc (with all aliases)" \
    "set zsh as default shell"

  if in_selected "zsh"; then
    sudo apt install -y zsh && log "Zsh installed"
  fi

  if in_selected "oh-my-zsh"; then
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
      RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
      log "Oh My Zsh installed"
    else
      warn "Oh My Zsh already present"
    fi
  fi

  if in_selected "powerlevel10k theme"; then
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    [[ ! -d "$P10K_DIR" ]] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    log "Powerlevel10k installed"
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if in_selected "plugin: zsh-autosuggestions"; then
    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
      git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log "zsh-autosuggestions installed"
  fi
  if in_selected "plugin: zsh-syntax-highlighting"; then
    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log "zsh-syntax-highlighting installed"
  fi

  if in_selected "write .zshrc (with all aliases)"; then
    cat > "$HOME/.zshrc" << 'ZSHRC'
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting sudo z fzf)
source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# export ANTHROPIC_API_KEY="your_key_here"
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
alias scan='sudo nmap -sV -O'
alias update='sudo apt update && sudo apt upgrade -y'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias nse='ls /usr/share/nmap/scripts/ | grep'
alias storage="df -h --total | grep -E 'Filesystem|/dev/sd|/dev/nvme|total'"
alias hist='history | grep'
alias please='sudo $(fc -ln -1)'
alias zshrc='nano ~/.zshrc && source ~/.zshrc'
alias tmuxconf='nano ~/.tmux.conf'
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
ZSHRC
    log ".zshrc written"
  fi

  if in_selected "set zsh as default shell"; then
    sudo chsh -s "$(which zsh)" "$USER"
    log "Default shell set to zsh"
  fi
else
  skip "Stage 2"
fi

# =============================================================================
#  STAGE 3 — TERMINAL
# =============================================================================
section "Stage 3 · Terminal (Kitty + Tmux)"
if ask_stage "Terminal emulator & multiplexer"; then
  INSTALLED_STAGES+=("Terminal")

  pick_tools "Terminal components" \
    "kitty" \
    "kitty config (Catppuccin Mocha)" \
    "tmux" \
    "tmux config (mouse + vim keys + status bar)"

  if in_selected "kitty"; then
    sudo apt install -y kitty && log "Kitty installed"
  fi

  if in_selected "kitty config (Catppuccin Mocha)"; then
    mkdir -p "$HOME/.config/kitty"
    cat > "$HOME/.config/kitty/kitty.conf" << 'KITTY'
font_family      MesloLGS NF
font_size        12.0
cursor_shape     beam
scrollback_lines 10000
enable_audio_bell no
background            #1e1e2e
foreground            #cdd6f4
selection_background  #313244
color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8
KITTY
    log "Kitty config written"
  fi

  if in_selected "tmux"; then
    sudo apt install -y tmux && log "Tmux installed"
  fi

  if in_selected "tmux config (mouse + vim keys + status bar)"; then
    cat > "$HOME/.tmux.conf" << 'TMUXCONF'
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g history-limit 50000
set -g escape-time 10
set -sg repeat-time 600
set -g status-style bg='#1e1e2e',fg='#cdd6f4'
set -g status-left '#[fg=#89b4fa,bold] #S '
set -g status-right '#[fg=#a6e3a1] %H:%M #[fg=#89b4fa] %d-%b '
set -g status-right-length 50
set -g status-left-length 20
setw -g window-status-current-style fg='#f38ba8',bold
bind r source-file ~/.tmux.conf \; display "Reloaded!"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
TMUXCONF
    log "Tmux config written"
  fi
else
  skip "Stage 3"
fi

# =============================================================================
#  STAGE 4 — RICE
# =============================================================================
section "Stage 4 · Desktop Rice"
if ask_stage "Desktop Rice (icons, Conky)"; then
  INSTALLED_STAGES+=("Rice")

  pick_tools "Rice components" \
    "papirus-icon-theme" \
    "apply Papirus-Dark icons (Cinnamon)" \
    "conky-all" \
    "conky config (CPU/RAM/net/storage)"

  if in_selected "papirus-icon-theme"; then
    sudo apt install -y papirus-icon-theme && log "Papirus installed"
  fi

  if in_selected "apply Papirus-Dark icons (Cinnamon)"; then
    command -v gsettings &>/dev/null && \
      gsettings set org.cinnamon.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || \
      warn "Set icons manually: System Settings → Themes"
  fi

  if in_selected "conky-all"; then
    sudo apt install -y conky-all && log "Conky installed"
  fi

  if in_selected "conky config (CPU/RAM/net/storage)"; then
    mkdir -p "$HOME/.config/conky"
    cat > "$HOME/.config/conky/conky.conf" << 'CONKY'
conky.config = {
  alignment='top_right', background=false, border_width=0,
  cpu_avg_samples=2, double_buffer=true, draw_borders=false,
  draw_shades=false, gap_x=20, gap_y=50, minimum_width=220,
  net_avg_samples=2, no_buffers=true, own_window=true,
  own_window_type='desktop', own_window_transparent=true,
  own_window_argb_visual=true, own_window_argb_value=0,
  update_interval=2, use_xft=true, font='MesloLGS NF:size=9',
  default_color='89b4fa', color1='cdd6f4', color2='a6e3a1',
};
conky.text = [[
${color1}SYSTEM
${color2}OS:${color1}    ${distro} ${machine}
${color2}Uptime:${color1} ${uptime_short}

${color1}RESOURCES
${color2}CPU:${color1}   ${cpu cpu0}% ${cpubar cpu0 6,120}
${color2}RAM:${color1}   $mem / $memmax ${membar 6,120}

${color1}NETWORK
${color2}IP:${color1}    ${addr eth0}${addr wlan0}
${color2}Up:${color1}    ${upspeed}
${color2}Down:${color1}  ${downspeed}

${color1}STORAGE
${color2}/:${color1}     ${fs_used /} / ${fs_size /} ${fs_bar 6,120 /}
]];
CONKY
    log "Conky config written"
  fi
else
  skip "Stage 4"
fi

# =============================================================================
#  STAGE 5 — PENTEST TOOLS
# =============================================================================
section "Stage 5 · Pentest Tools"
if ask_stage "Pentest Tools"; then
  INSTALLED_STAGES+=("Pentest")

  pick_tools "Recon & OSINT" \
    "nmap" "netdiscover" "whois" "dnsutils" "masscan"
  RECON=("${SELECTED[@]:-}")

  pick_tools "Web Application Testing" \
    "nikto" "sqlmap" "dirb" "gobuster"
  WEB=("${SELECTED[@]:-}")

  pick_tools "Network Analysis" \
    "wireshark" "tcpdump" "netcat-openbsd" "proxychains4"
  NET=("${SELECTED[@]:-}")

  pick_tools "Password & Hash Cracking" \
    "john" "hashcat" "hydra"
  CRACK=("${SELECTED[@]:-}")

  pick_tools "Wireless" \
    "aircrack-ng"
  WIRELESS=("${SELECTED[@]:-}")

  pick_tools "Exploitation & Misc" \
    "exploitdb" "smbclient" "metasploit-framework"
  EXPLOIT=("${SELECTED[@]:-}")

  pick_tools "Virtualisation (for Kali VM)" \
    "virtualbox" "virtualbox-ext-pack"
  VM=("${SELECTED[@]:-}")

  ALL_PT=(
    "${RECON[@]:-}" "${WEB[@]:-}" "${NET[@]:-}"
    "${CRACK[@]:-}" "${WIRELESS[@]:-}" "${VM[@]:-}"
  )

  STD_PKGS=()
  for pkg in "${ALL_PT[@]:-}"; do
    STD_PKGS+=("$pkg")
  done

  # Remove metasploit from standard install
  FINAL_PKGS=()
  for pkg in "${STD_PKGS[@]:-}"; do
    [[ "$pkg" != "metasploit-framework" ]] && FINAL_PKGS+=("$pkg")
  done

  [[ ${#FINAL_PKGS[@]} -gt 0 ]] && sudo apt install -y "${FINAL_PKGS[@]}" && log "Pentest packages installed"

  # Metasploit via official repo
  for pkg in "${EXPLOIT[@]:-}"; do
    if [[ "$pkg" == "metasploit-framework" ]]; then
      curl -fsSL https://apt.metasploit.com/metasploit-framework.gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/metasploit.gpg
      echo "deb [signed-by=/usr/share/keyrings/metasploit.gpg] https://apt.metasploit.com/ buster main" \
        | sudo tee /etc/apt/sources.list.d/metasploit.list
      sudo apt update && sudo apt install -y metasploit-framework
      log "Metasploit installed"
    fi
  done

  # Wireshark non-root
  for pkg in "${NET[@]:-}"; do
    [[ "$pkg" == "wireshark" ]] && sudo usermod -aG wireshark "$USER" 2>/dev/null || true
  done
else
  skip "Stage 5"
fi

# =============================================================================
#  STAGE 6 — NODE.JS
# =============================================================================
section "Stage 6 · Node.js via NVM"
if ask_stage "Node.js (NVM + LTS + Claude Code)"; then
  INSTALLED_STAGES+=("Node.js")

  pick_tools "Node components" \
    "nvm (Node Version Manager)" \
    "Node.js LTS" \
    "claude-code (@anthropic-ai/claude-code)"

  if in_selected "nvm (Node Version Manager)"; then
    if [[ ! -d "$HOME/.nvm" ]]; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
      log "NVM installed"
    else
      warn "NVM already present"
    fi
  fi

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

  if in_selected "Node.js LTS"; then
    nvm install --lts && nvm use --lts
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    log "Node.js LTS installed"
  fi

  if in_selected "claude-code (@anthropic-ai/claude-code)"; then
    npm install -g @anthropic-ai/claude-code
    log "Claude Code installed"
  fi
else
  skip "Stage 6"
fi

# =============================================================================
#  STAGE 7 — VSCODIUM
# =============================================================================
section "Stage 7 · VSCodium"
if ask_stage "VSCodium (open-source VSCode, no telemetry)"; then
  INSTALLED_STAGES+=("VSCodium")
  if ! command -v codium &>/dev/null; then
    info "Fetching latest VSCodium .deb from GitHub..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/VSCodium/vscodium/releases/latest \
      | grep tag_name | cut -d '"' -f 4)
    wget -q --show-progress -O /tmp/codium.deb \
      "https://github.com/VSCodium/vscodium/releases/download/${LATEST_TAG}/codium_${LATEST_TAG}_amd64.deb"
    sudo dpkg -i /tmp/codium.deb && rm /tmp/codium.deb
    log "VSCodium ${LATEST_TAG} installed"
  else
    warn "VSCodium already installed"
  fi
else
  skip "Stage 7"
fi

# =============================================================================
#  STAGE 8 — DOCKER
# =============================================================================
section "Stage 8 · Docker"
if ask_stage "Docker (isolated research environments)"; then
  INSTALLED_STAGES+=("Docker")
  if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    log "Docker installed (re-login required)"
  else
    warn "Docker already installed"
  fi
else
  skip "Stage 8"
fi

# =============================================================================
#  STAGE 9 — EXTRAS
# =============================================================================
section "Stage 9 · Extras"
if ask_stage "Extras (Neovim/LazyVim, Obsidian)"; then
  INSTALLED_STAGES+=("Extras")

  pick_tools "Extra tools" \
    "neovim" \
    "LazyVim starter config" \
    "obsidian (flatpak)"

  if in_selected "neovim"; then
    sudo apt install -y neovim && log "Neovim installed"
  fi

  if in_selected "LazyVim starter config"; then
    if [[ ! -d "$HOME/.config/nvim" ]]; then
      git clone https://github.com/LazyVim/starter "$HOME/.config/nvim" --depth=1
      log "LazyVim installed"
    else
      warn "~/.config/nvim exists — skipping"
    fi
  fi

  if in_selected "obsidian (flatpak)"; then
    if command -v flatpak &>/dev/null; then
      flatpak install -y flathub md.obsidian.Obsidian || warn "Obsidian install failed — try obsidian.md"
    else
      warn "Flatpak not available — install Obsidian manually from obsidian.md"
    fi
  fi
else
  skip "Stage 9"
fi

# =============================================================================
#  SUMMARY
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}══════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Setup Complete!${NC}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Stages completed:${NC}"
if [[ ${#INSTALLED_STAGES[@]} -gt 0 ]]; then
  for s in "${INSTALLED_STAGES[@]}"; do echo -e "  ${GREEN}✔${NC} $s"; done
else
  echo "  None"
fi
echo ""
echo -e "${YELLOW}Post-install checklist:${NC}"
echo "  1. Log out and back in (shell change, docker/wireshark groups)"
echo "  2. Open new terminal → run: p10k configure"
echo "  3. Set ANTHROPIC_API_KEY in ~/.zshrc"
echo "  4. Kali VM image → kali.org/get-kali/#kali-virtual-machines"
echo "  5. Install MesloLGS NF font for Powerlevel10k glyphs"
echo "  6. Add conky to startup: System Settings → Startup Applications"
echo ""
echo -e "${CYAN}  Reboot recommended.${NC}"
echo ""
