# docker-coreos

## TL;DR

I hacked something together in order to create a Swarm cluster on CoreOS (or Container Linux) using Vagrant and Ansible.

If you keep reading, I’m going to talk to you about Swarm, CNM, runc, containerd, Infrastructure as Code and Ansible testing strategies. It’s gonna be super fun.

If you want to try it:

    git clone https://github.com/sebiwi/docker-coreos
    cd docker-coreos
    make up

This will spin up 6 VMs: Three Swarm Manager nodes (one Leader), and three Swarm Worker nodes. You can modify the size of the cluster by hacking on the Vagrantfile and the Ansible inventory.

You will need Ansible 2.2, Vagrant and Virtualbox. You will also need molecule and docker-py, if you want to run the tests.

## You can find the articles related to this repository below:

- [Swarm general architecure](https://sebiwi.github.io/blog/how-does-it-work-docker-1/): https://sebiwi.github.io/blog/how-does-it-work-docker-1/
- [Swarm networking](https://sebiwi.github.io/blog/how-does-it-work-docker-2/): https://sebiwi.github.io/blog/how-does-it-work-docker-2/
- [Swarm load balancing, service discovery and security](https://sebiwi.github.io/blog/how-does-it-work-docker-3/): https://sebiwi.github.io/blog/how-does-it-work-docker-3/
- [Control your swarm!](https://sebiwi.github.io/blog/how-does-it-work-docker-4/): https://sebiwi.github.io/blog/how-does-it-work-docker-4/
- [Get some work(ers) done!](https://sebiwi.github.io/blog/how-does-it-work-docker-5/): https://sebiwi.github.io/blog/how-does-it-work-docker-5/


# Let's play

$ vagrant ssh swarm-manager-01

[root@swarm-manager-01 vagrant]# docker node ls
ID                           HOSTNAME          STATUS  AVAILABILITY  MANAGER STATUS
k3hafap9qze2pph7h7ddlm6s9    swarm-worker-01   Ready   Active        
w7yspfuv8y0xmsgg07k33h5yb    swarm-worker-02   Ready   Active        
zwyq37lspf3m41qrkvsj78a6p *  swarm-manager-01  Ready   Drain         Leader

[root@swarm-manager-01 vagrant]# docker service create --replicas 1 --name redis --update-delay 10s redis:3.0.6
ek6y1b8q4nvm4cs7o5dr0i7qd

[root@swarm-manager-01 vagrant]# docker service ls
ID            NAME   MODE        REPLICAS  IMAGE
ek6y1b8q4nvm  redis  replicated  1/1       redis:3.0.6

[root@swarm-manager-01 vagrant]# docker service ps redis
ID            NAME     IMAGE        NODE             DESIRED STATE  CURRENT STATE               ERROR  PORTS
u3q0i3qkz1nd  redis.1  redis:3.0.6  swarm-worker-01  Running        Running about a minute ago         

-- Scale up/down
[root@swarm-manager-01 vagrant]# docker service scale redis=6
redis scaled to 6

[root@swarm-manager-01 vagrant]# docker service ps redis
ID            NAME      IMAGE        NODE             DESIRED STATE  CURRENT STATE           ERROR  PORTS
u3q0i3qkz1nd  redis.1   redis:3.0.6  swarm-worker-01  Running        Running 6 minutes ago          
vgd92hgbrd82  redis.16  redis:3.0.6  swarm-worker-02  Running        Running 25 seconds ago         
z1r6oe5qf3vo  redis.18  redis:3.0.6  swarm-worker-01  Running        Running 33 seconds ago         
lb2rih5lt137  redis.19  redis:3.0.6  swarm-worker-02  Running        Running 20 seconds ago         
zptwntt15doq  redis.24  redis:3.0.6  swarm-worker-01  Running        Running 35 seconds ago         
q0ou3yxsdkrc  redis.48  redis:3.0.6  swarm-worker-02  Running        Running 26 seconds ago        

[root@swarm-manager-01 vagrant]# docker service update --image redis:3.0.7 redis

[root@swarm-manager-01 vagrant]# docker service ps redis
ID            NAME          IMAGE        NODE             DESIRED STATE  CURRENT STATE                   ERROR  PORTS
u3q0i3qkz1nd  redis.1       redis:3.0.6  swarm-worker-01  Running        Running 8 minutes ago                  
uedwp251vwpa  redis.16      redis:3.0.7  swarm-worker-02  Running        Running 22 seconds ago                 
vgd92hgbrd82   \_ redis.16  redis:3.0.6  swarm-worker-02  Shutdown       Shutdown 30 seconds ago                
d3h3847nka0t  redis.18      redis:3.0.7  swarm-worker-01  Running        Running less than a second ago         
z1r6oe5qf3vo   \_ redis.18  redis:3.0.6  swarm-worker-01  Shutdown       Shutdown 10 seconds ago                
lb2rih5lt137  redis.19      redis:3.0.6  swarm-worker-02  Running        Running 3 minutes ago                  
zptwntt15doq  redis.24      redis:3.0.6  swarm-worker-01  Running        Running 3 minutes ago                  
q0ou3yxsdkrc  redis.48      redis:3.0.6  swarm-worker-02  Running        Running 3 minutes ago     

[root@swarm-manager-01 vagrant]# docker service inspect --pretty redis

ID:     ek6y1b8q4nvm4cs7o5dr0i7qd
Name:       redis
Service Mode:   Replicated
 Replicas:  6
UpdateStatus:
 State:     updating
 Started:   About a minute
 Message:   update in progress
Placement:
UpdateConfig:
 Parallelism:   1
 Delay:     10s
 On failure:    pause
 Max failure ratio: 0
ContainerSpec:
 Image:     redis:3.0.7@sha256:730b765df9fe96af414da64a2b67f3a5f70b8fd13a31e5096fee4807ed802e20
Resources:
Endpoint Mode:  vip

[root@swarm-manager-01 vagrant]# docker service create --name amazing-web-server --publish 8080:80 --replicas 2 nginx
coa7sj1x8u412i9gpijau7jo2

[root@swarm-manager-01 vagrant]# docker service ps amazing-web-server
ID            NAME                  IMAGE         NODE             DESIRED STATE  CURRENT STATE               ERROR  PORTS
i34kame1pjp0  amazing-web-server.1  nginx:latest  swarm-worker-01  Running        Running about a minute ago         
clsarofp800a  amazing-web-server.2  nginx:latest  swarm-worker-02  Running        Running about a minute ago         


## Prometheus and Grafana

Clone into manager node
$ git clone https://github.com/vegasbrianc/prometheus

Start Prometheus Stack
$ HOSTNAME=$(hostname) docker stack deploy -c docker-stack.yml prom
Error: unsupported Compose file version: 3.7
Update docker-stack.yml - version 3.1

Check Stack
$ docker stack ps prom

