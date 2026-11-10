if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

missing=""
for dep in git make; do
  command -v "$dep" >/dev/null 2>&1 || missing="$missing $dep"
done

if [ -z "$missing" ]; then
  echo "Success : Dep installed"
else
  echo "Error : missing$missing"
  apt install -y $missing
fi

git clone https://github.com/Chocofresh14/AsmShare.git
cd AsmShare
make build

mv asmshare /usr/local/bin/
