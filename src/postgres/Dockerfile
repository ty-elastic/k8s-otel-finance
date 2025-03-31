FROM postgres

RUN ln -sf /dev/stdout /var/lib/postgresql/data/log/postgresql.json

CMD ["postgres", "-c", "log_statement=all", "-c", "logging_collector=on", "-c", "log_destination=jsonlog", "-c", "log_filename=postgresql.json"]
