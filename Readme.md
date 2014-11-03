# amqp_client

###Routing 4

##Consumer:

```consumer_worker:receive_logs_direct(["error","wrong message"])```

```consumer_worker:receive_logs_direct(["info","default message"])```

##Producer:

```producer_worker:emit_log_direct(["error"])```

```producer_worker:emit_log_direct(["info"])```
