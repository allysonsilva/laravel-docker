[program:laravel-horizon]
process_name=%(program_name)s
command=php artisan horizon
directory=%(ENV_REMOTE_SRC)s
autostart=true
autorestart=true
redirect_stderr=true
stderr_logfile=%(ENV_REMOTE_SRC)s/storage/logs/horizon.err.log
stdout_logfile=%(ENV_REMOTE_SRC)s/storage/logs/horizon.out.log
numprocs=1
startretries=2
user=%(ENV_DEFAULT_USER)s
; environment=REDIS_HOST="{{REDIS_HOST}}",REDIS_PASSWORD="{{REDIS_PASSWORD}}",REDIS_PORT="{{REDIS_PORT}}",REDIS_QUEUE="{{REDIS_QUEUE}}"
