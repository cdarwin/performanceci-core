base:
  '*':
    - core
  'core':
    - core.db
    - core.redis
    - docker
    - rails
    - rails.db
    - rails.service
    - worker.docker
    - worker.service
