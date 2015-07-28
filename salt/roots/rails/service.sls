rails server:
  cmd.run:
    - name: 'nohup bundle exec rails server > /vagrant/log/rails.log 2> /vagrant/log/rails.err < /dev/null &'
    - cwd: /vagrant
    - unless: pgrep -fa rails
    - env:
      - DB_HOST: 192.168.69.10
      - REDIS_HOST: 192.168.69.10
      - SERVER_HOST: 192.168.69.10
      - RAILS_ENV: development
      - GITHUB_ID: {{salt['pillar.get']('rails:github:id', '')}}
      - GITHUB_SECRET: {{salt['pillar.get']('rails:github:secret', '')}}
      - WEBHOOK_URL: {{salt['pillar.get']('rails:webhook:url', '')}}
