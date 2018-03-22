#!/usr/bin/env bash

# make sure installer script isnt run as root
if [ "$(id -u)" = "0" ]
then
  echo -e "\nThis script must not be run as root\n" 1>&2
  exit 1

  # debian usage warning
  if [[ $(lsb_release -is) != 'Debian' ]]
  then
    echo -e "\nThis script was designed for Debian-based distributions. Press [Enter] to proceed. Otherwise, press Ctrl+c to exit installer.\n";
    read;
  fi
fi

# update apt index
sudo apt-get update;

# check for chomper dir, in case script is run multiple times
if [ -d ~/chomper ]
then
  echo -e "\nChomper directory detected. Remove the directory with '$ rm -rf ~/chomper' to use this script.\n";
  exit 1;
else
  echo -e "\nInstalling dependencies...\n";
  sudo apt-get install git build-essential curl zlib1g-dev libbz2-dev libsqlite3-dev libreadline-dev libncurses5-dev libssl-dev libgdbm-dev python-pip libnss3-tools screen -y;
fi

cd ~/ && git clone https://github.com/aniketpanjwani/chomper.git;
cd chomper;

if [ ":$PATH:" != *":/home/$USER/chomper/bin"* ]
then
  export PATH=$PATH:/home/$USER/chomper/bin
  echo 'export PATH=$PATH:/home/$USER/chomper/bin' >> ~/.bashrc
  echo -e "\nAdded Chomper to PATH.\n"
else
  echo -e "\nChomper is already on PATH.\n"
fi

# Install pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo  -e '\nif command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
exec "$SHELL"
source ~/.bashrc
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
pyenv install 3.6.4

# Install pipenv and virtual environment
sudo -H pip install -U pipenv # Install pipenv
pipenv install --dev --python 3.6.4 # Install packages

# Install certificates
screen -d -m pipenv run mitmdump
sleep 2
pkill -f mitmdump # Generate certificates
openssl x509 -outform der -in /home/$USER/.mitmproxy/mitmproxy-ca.pem -out /home/$USER/.mitmproxy/mitmproxy-ca.crt
sudo cp /home/$USER/.mitmproxy/mitmproxy-ca.crt /usr/local/share/ca-certificates/mitmproxy-ca.crt # Install root certificates
sudo update-ca-certificates
sudo sh ./chomper/certs.sh # Make browsers recognize root certificates

# Enable ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1 # Enable ipv4 forwarding
sudo sysctl -w net.ipv6.conf.all.forwarding=1 # Enable ipv6 forwarding
sudo sysctl -p # Lock in new ip forwarding settings.
