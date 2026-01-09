function up --wraps='cd ~/mistral/dashboard/infra/local && docker-compose up' --description 'alias up=cd ~/mistral/dashboard/infra/local && docker-compose up'
  cd ~/mistral/dashboard/infra/local && docker-compose up -d $argv;
  cd -;
end