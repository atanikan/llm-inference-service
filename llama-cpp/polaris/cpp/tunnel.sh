# Get the remote host from qstat
remote_host=$(qstat -x -f $(qstat -u $USER | tail -1 | sed "s/\..*$//g") | grep exec_host | sed "s/exec_host\ =\ //g" | sed "s/\/0\*64.*$//g" | sed 's/^[ \t]*//;s/[ \t]*$//;s/[ \t]\+/ /g')

echo "hi $remote_host"
# Check if there's an existing SSH tunnel running and kill it

existing_tunnel_pid=$(ps aux | grep "ssh -L 8080:localhost:8080 $remote_host" | grep -v grep | awk '{print $2}')
if [[ ! -z "$existing_tunnel_pid" ]]; then
    echo "Killing existing SSH tunnel with PID $existing_tunnel_pid..."
    kill -9 "$existing_tunnel_pid"
fi

# Establish a new tunnel
echo "Establishing SSH tunnel to $remote_host with port forwarding for 8080"
ssh -L 8080:localhost:8080 "$remote_host" -N -f

if [[ $? -eq 0 ]]; then
    echo "SSH tunnel established successfully."
else
    echo "Failed to establish SSH tunnel."
fi