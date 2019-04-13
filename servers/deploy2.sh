#!/bin/bash
apt-get update -y && apt-get upgrade -y
apt-get install -y htop
apt-get -y install \
  apt-transport-https \
  ca-certificates \
  curl
# Install docker 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
 
add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
 
apt-get update
 
apt-get -y install docker-ce

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# deploy dockerui

docker run --restart unless-stopped -d -p 9000:9000 -v /var/run/docker.sock:/docker.sock --name dockerui abh1nav/dockerui:latest -e="/docker.sock"

# docker-enter
cat > /usr/bin/docker-enter <<- "EOF"
#!/bin/bash 
EXPECTED_NUM_ARGS=1;
if [ "$#" -ne $EXPECTED_NUM_ARGS ]; then
    # user didn't specify which container ID, assume the latest one
    CONTAINER_ID=`/usr/bin/docker ps -q --no-trunc | /bin/sed -n 1p`
    /usr/bin/docker exec -it $CONTAINER_ID env TERM=xterm bash
elsesudo chmod +x /usr/bin/docker-enter
    # enter the container the user specified
    /usr/bin/docker exec -it $1 env TERM=xterm bash
fi
EOF

sudo chmod +x /usr/bin/docker-enter

# deploy-runner
docker run -d \
--name gitlab-runner \
--restart always \
-v $HOME/gitlab-runner-volume/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest

# register runner
docker exec -i gitlab-runner gitlab-runner register -n --url https://gitlab.com/ --registration-token GmVZvfR54H2uFZecDPNy --executor docker --description "My Docker Runner" --docker-image "docker:latest" --docker-volumes /var/run/docker.sock:/var/run/docker.sock
