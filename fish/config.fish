if status is-interactive
    # Commands to run in interactive sessions can go here
end

# USER CONFIG
set CASE_SENSITIVE true
set ENABLE_CORRECTION true
set COMPLETION_WAITING_DOTS true
set EDITOR hx

set -gx GPG_TTY (tty)
# set -gx JAVA_HOME "$(/usr/libexec/java_home)"
set -gx JOBS max
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
# set -gx PNPM_HOME $HOME/Library/pnpm
set -gx SSH_KEY_PATH $HOME/.ssh/

# ANDROID SETUP
# set -gx ANDROID_HOME $HOME/Library/Android/sdk
# set -gx ANDROID_SDK_ROOT $ANDROID_HOME
# set -gx ANDROID_AVD_HOME $HOME/.android/avd


# PATH
set -gx PATH $PATH /usr/local/sbin
set -gx PATH $PATH /usr/local/bin
set -gx PATH $PATH /usr/sbin
set -gx PATH $PATH /usr/bin
set -gx PATH $PATH /sbin
set -gx PATH $PATH /bin
set -gx PATH $PATH $HOME/.local/bin
# set -gx PATH $PATH $ANDROID_HOME/cmdline-tools/latest/bin
# set -gx PATH $PATH $ANDROID_HOME/emulator
# set -gx PATH $PATH $ANDROID_HOME/tools
# set -gx PATH $PATH $ANDROID_HOME/tools/bin
# set -gx PATH $PATH $ANDROID_HOME/platform-tools
# set -gx PATH $PATH $HOME/.cargo/bin

# secrets (gitignored)
test -f (status dirname)/secrets.fish; and source (status dirname)/secrets.fish

# node
set -gx NODE_OPTIONS "--max-old-space-size=7168"

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

rbenv init - fish | source
starship init fish | source

# proto
set -gx PROTO_HOME "$HOME/.proto"
set -gx PATH "$PROTO_HOME/bin:$PROTO_HOME/shims" $PATH

# pnpm
set -gx PNPM_HOME "/Users/valpinkman/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/valpinkman/.lmstudio/bin
# End of LM Studio CLI section

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# Secretive ssh setup
set -x SSH_AUTH_SOCK /Users/valpinkman/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"

# Pi
fish_add_path "/Users/valpinkman/.proto/tools/node/24.4.0/bin"

# Added for cooklang-project (Android/KMP toolchain)
set -gx JAVA_HOME /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
set -gx ANDROID_HOME /opt/homebrew/share/android-commandlinetools
set -gx ANDROID_SDK_ROOT $ANDROID_HOME
fish_add_path $JAVA_HOME/bin
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin

# kimi-code
fish_add_path -g "/Users/valpinkman/.kimi-code/bin"
