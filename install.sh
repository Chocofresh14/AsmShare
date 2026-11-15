#!/bin/bash
set -e

missing=""
for dep in git make nasm ld; do
  command -v "$dep" >/dev/null 2>&1 || missing="$missing $dep"
done

if [ -n "$missing" ]; then
  echo "Missing:$missing"
  sudo apt install -y git make nasm binutils
fi

if [ ! -d AsmShare ]; then
  git clone https://github.com/Chocofresh14/AsmShare.git
fi

cd AsmShare
make
sudo install -m 755 asmshare /usr/local/bin/asmshare

echo "Installed. Run 'asmshare' from a folder that contains a 'www' directory."
