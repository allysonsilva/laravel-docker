[program:laravel-horizon]
process_name=%(program_name)s
command=php artisan horizon --env=%(ENV_APP_ENV)s
directory=%(ENV_REMOTE_SRC)s
user=%(ENV_USER_NAME)s
autostart=true
autorestart=true
numprocs=1
startretries=2

redirect_stderr=true
stdout_logfile=%(ENV_REMOTE_SRC)s/storage/logs/horizon.out.log

; (120 seconds) timeout to give jobs time to finish
; Graceful shutdown
stopwaitsecs=120
