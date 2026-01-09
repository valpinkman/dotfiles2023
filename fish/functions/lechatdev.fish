function lechatdev --wraps='cd ~/mistral/dashboard/ts && pnpm i && npx turbo watch dev -F le-chat-web' --description 'alias dev=cd ~/mistral/dashboard/ts && pnpm i && npx turbo watch dev -F le-chat-web'
  cd ~/mistral/dashboard/ts && pnpm i && npx turbo watch dev -F le-chat-web $argv;
end