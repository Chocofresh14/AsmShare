if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ "$(dpkg -l | awk '/ansible/ {print }'|wc -l)" -ge 1 ]; then
  echo "Success : Dep installed"
else
  echo "Error : Dep not installed"
  apt install make git
fi

git clone https://github.com/Chocofresh14/AsmShare.git
cd AsmShare
make build

mv asmshare /usr/local/bin/
