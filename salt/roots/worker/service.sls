resque worker service:
  cmd.run:
    - name: 'nohup bundle exec rake resque:work > /vagrant/log/resque.log 2> /vagrant/log/resque.err < /dev/null &'
    - cwd: /vagrant
    - unless: pgrep -fa resque
    - env:
      - DB_HOST: 192.168.69.10
      - REDIS_HOST: 192.168.69.10
      - SERVER_HOST: 192.168.69.10
      - DOCKER_URL: 'unix:///run/docker.sock'
      - RAILS_ENV: development
      - QUEUE: docker
