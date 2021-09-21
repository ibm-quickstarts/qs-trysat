
# Install make
wget http://mirror.us-midwest-1.nexcess.net/gnu/make/make-4.3.tar.gz
tar -xvf make-4.3.tar.gz
cd make-4.3
./configure
sh build.sh
./make install
./make --version
mkdir ../bin
mv make ../bin
cd ..
export PATH=$(pwd)/bin:$PATH
make --version
