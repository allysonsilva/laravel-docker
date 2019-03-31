[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php artisan queue:work {{QUEUE_CONNECTION}} --queue=high,{{REDIS_QUEUE}},low --memory={{QUEUE_MEMORY}} --env=%(ENV_APP_ENV)s --sleep={{QUEUE_SLEEP}} --tries={{QUEUE_TRIES}} --timeout={{QUEUE_TIMEOUT}}
directory=%(ENV_REMOTE_SRC)s
autostart=true
autorestart=true
; redirect_stderr=true
; stderr_logfile=%(ENV_REMOTE_SRC)s/storage/logs/worker-queue.err.log
; stdout_logfile=%(ENV_REMOTE_SRC)s/storage/logs/worker-queue.out.log
numprocs=6
startretries=2 ; The number of serial failure attempts that supervisord will allow when attempting to start the program before giving up and putting the process into an FATAL state.
user=%(ENV_DEFAULT_USER)s

stdout_events_enabled=true
stderr_events_enabled=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0   ; Set this value to 0 to indicate an unlimited log size.
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0   ; Set this value to 0 to indicate an unlimited log size.
