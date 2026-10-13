# Cache the output of `<tool> init`-style commands so we don't fork the tool in every shell.
# Usage: __source_cached_init <cmd> <args…>
# The cache key is the resolved (Cellar) path, so it regenerates on upgrade.
function __source_cached_init
    set -l cmd $argv[1]
    set -l stable /opt/homebrew/bin/$cmd
    test -x $stable; or return 1
    set -l resolved (path resolve $stable)
    set -l dir ~/.cache/fish/init
    set -l cache $dir/(string replace -a / _ -- $resolved).fish
    if not test -s $cache
        mkdir -p $dir
        command rm -f $dir/*_$cmd.fish
        $stable $argv[2..-1] | string replace -a -- $resolved $stable >$cache
    end
    source $cache
end

# ENV
set -gx EDITOR hx
set -gx JOBS max
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx NODE_OPTIONS "--max-old-space-size=7168"

# homebrew (static, instead of `brew shellenv`)
set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew

# proto / pnpm / rbenv
set -gx PROTO_HOME $HOME/.proto
set -gx PNPM_HOME $HOME/Library/pnpm
set -gx RBENV_SHELL fish

# android / java (cooklang-project)
set -gx JAVA_HOME /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
set -gx ANDROID_HOME /opt/homebrew/share/android-commandlinetools
set -gx ANDROID_SDK_ROOT $ANDROID_HOME

# Secretive ssh setup
set -gx SSH_AUTH_SOCK $HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

# PATH, built once. --move keeps Homebrew ahead of /usr/bin (system git).
# ~/.proto/tools/node/24.4.0/bin is where `pi` lives.
fish_add_path --global --move --path \
    ~/.rbenv/shims ~/.proto/shims ~/.proto/bin \
    /opt/homebrew/bin /opt/homebrew/sbin \
    $PNPM_HOME ~/.local/bin ~/.kimi-code/bin \
    ~/.proto/tools/node/24.4.0/bin \
    $JAVA_HOME/bin $ANDROID_HOME/platform-tools $ANDROID_HOME/cmdline-tools/latest/bin

# secrets (gitignored)
test -f (status dirname)/secrets.fish; and source (status dirname)/secrets.fish

# OrbStack: command-line tools and integration
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

if status is-interactive
    __source_cached_init starship init fish --print-full-init
end
