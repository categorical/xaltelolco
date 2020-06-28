
# The connection will be forwarded from local to remote through SSH.
# _0: local
# _1: remote machine
# _2: connection (destination)

PORT_0=30000
HOST_1=123.123.123.123
HOST_2=123.123.123.123
PORT_2=30000

source "`dirname "$0"`/`basename "$0"`.config"

CMD_FORWARD="ssh -f -N -L $PORT_0:$HOST_2:$PORT_2 $HOST_1"
# N.B. The L switch does port forwarding for a connection,
# and this forwarding is transparent to an application.
# The D switch does dynamic port forwarding (application level),
# and an application has to be configured to use the secure channel.
#
# The D switch enables SSH as a proxy (forwarding different connections),
# and the L switch forwards connections with a specified destination.


# L switch, curl localhost:30000 resolves as "GET /" on upstream proxy server;
# D switch (ssh -D 30000 123.123.123.123), curl localhost:30000 returns an empty response,
# curl -x socks5h:localhost:30000 localhost:30000 works.


PID_FILE=/var/run/ssh_forward.pid
pid()
{
    if [ -f "$PID_FILE" ]; then
        PID=$(sudo cat $PID_FILE)
        return 0  
    fi
    return 1
}
case $@ in
    "start")
    pid && [ ! -z $PID ] && echo "Already running with process ID: ${PID}." \
    || ($CMD_FORWARD && PID=$(lsof -i :$PORT_0 -sTCP:LISTEN -t|sudo tee $PID_FILE) \
    && echo "Started with process ID: ${PID}.")
    ;;
    "stop")
    pid && [ ! -z $PID ] && kill -9 $PID && sudo rm -f $PID_FILE && echo "Stopped." \
    || echo "Not running."
    ;;
    "status")
    pid && [ ! -z $PID ] && echo "Running with process ID: ${PID}." \
    || echo "Not running."
    ;;
    *) echo "start|stop|status";;
esac



