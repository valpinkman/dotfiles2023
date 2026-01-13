if status is-interactive
    # Commands to run in interactive sessions can go here
end

set --erase --universal fish_key_bindings

# USER CONFIG
set CASE_SENSITIVE true
set ENABLE_CORRECTION true
set COMPLETION_WAITING_DOTS true
set EDITOR hx

# Ensure that GPG Agent is used as the SSH agent
set -e SSH_AUTH_SOCK
set -U -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)

# GPG Agent
# Start or re-use a gpg-agent.
gpgconf --launch gpg-agent

set -gx GPG_TTY (tty)
set -gx JOBS max
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx SSH_KEY_PATH $HOME/.ssh/

# ANDROID SETUP
# set -gx ANDROID_HOME $HOME/Library/Android/sdk
# set -gx ANDROID_SDK_ROOT $ANDROID_HOME
# set -gx ANDROID_AVD_HOME $HOME/.android/avd

# Claude Mistral
set -gx CLAUDE_CODE_USE_VERTEX 1
set -gx CLOUD_ML_REGION global
set -gx ANTHROPIC_VERTEX_PROJECT_ID code-model-vertex
set -gx ANTHROPIC_MODEL "claude-sonnet-4-5@20250929"
set -gx ANTHROPIC_SMALL_FAST_MODEL "claude-haiku-4-5@20251001"

# PATH
set -gx PATH $PATH /Users/valentin.dealmeida/mistral/dashboard/ts/node_modules/.bin
set -gx PATH $PATH /usr/local/sbin
set -gx PATH $PATH /usr/local/bin
set -gx PATH $PATH /usr/sbin
set -gx PATH $PATH /usr/bin
set -gx PATH $PATH /sbin
set -gx PATH $PATH /bin
# set -gx PATH $PATH $ANDROID_HOME/cmdline-tools/latest/bin
# set -gx PATH $PATH $ANDROID_HOME/emulator
# set -gx PATH $PATH $ANDROID_HOME/tools
# set -gx PATH $PATH $ANDROID_HOME/tools/bin
# set -gx PATH $PATH $ANDROID_HOME/platform-tools
# set -gx PATH $PATH $HOME/.cargo/bin

# node
set -gx NODE_OPTIONS "--max-old-space-size=7168"

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# rbenv init - fish | source
starship init fish | source

# proto
set -gx PROTO_HOME "$HOME/.proto"
set -gx PATH "$PROTO_HOME/bin:$PROTO_HOME/shims" $PATH

# pnpm
set -gx PNPM_HOME "~/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# uv
fish_add_path "/Users/valentin.dealmeida/.local/bin"