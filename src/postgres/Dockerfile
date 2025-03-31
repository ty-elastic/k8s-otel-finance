FROM postgres

RUN touch /var/log/postgresql.json
RUN ln -sf /dev/stdout /var/log/postgresql.json

CMD ["postgres", "-c", "log_statement=all", "-c", "logging_collector=on", "-c", "log_destination=jsonlog", "-c", "log_directory=/var/log", "-c", "log_filename=postgresql.json"]
