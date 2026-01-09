function down --wraps='cd ~/mistral/dashboard/infra/local && docker-compose down' --description 'alias down=cd ~/mistral/dashboard/infra/local && docker-compose down'
  cd ~/mistral/dashboard/infra/local && docker-compose down $argv;
  cd -;
end