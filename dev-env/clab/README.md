# Setup local bridges
```
ip link add name sw1 type bridge
ip link set dev sw1 up
```
# Containerlab

Install [link](https://containerlab.dev/install/)

```
sudo containerlab deploy
kind export kubeconfig --name k00
```

# Deploy Metallb

```
# root folder
inv dev-env -i ipv4 -b frr -l all --name k00
```

# Run BPG graceful restart with BFD demo

```
# inside cd dev-env/clab/

kubectl apply -f graceful/red-peering.yaml

kubectl apply -f graceful/red-pod-two.yaml

tmux new-window -n clients
tmux send-keys -t clients.0 "docker exec -it clab-vlab-sidecar-gw1 /bin/bash" C-m C-m C-m
tmux send-keys -t clients.0 "ip vrf exec red /bin/bash" C-m C-m C-m
tmux send-keys -t clients.0 "curl -sf http://6.6.6.1:5555/hostname" C-m C-m C-m
tmux send-keys -t clients.0 "while true;do curl -sf http://6.6.6.1:5555/hostname --connect-timeout 1 || printf \"%s \" \$(date +%s) ;sleep 1;echo; done" C-m
tmux split-window -v -t clients
tmux send-keys -t clients.1 "kubectl get pods -o wide" C-m C-m C-m
tmux split-window -v -t clients
tmux send-keys -t client.2 "watch -d -c -n 1 docker exec clab-vlab-gw1 vtysh -c \\\"show ip bgp vrf red\\\"" C-m
tmux split-window -v -t clients
tmux send-keys -t client.3 "# kubectl set image daemonset/speaker frr=quay.io/frrouting/frr:9.1.0 -n metallb-system; kubectl -n metallb-system get pods -o wide -w" C-m
tmux send-keys -t client.3 "docker exec -it k00-worker bash -c \"ip link set dev red down\""
tmux select-layout -t clients even-vertical

tmux new-window -n gateway
tmux send-keys -t gateway.0 "docker exec clab-vlab-gw1 tail -f /tmp/frr.log" C-m
tmux split-window -v -t gateway
tmux send-keys -t gateway.1 "sudo tcpdump -i sw1 -nnn tcp port 179 -w - | wireshark -k -i -"
```
