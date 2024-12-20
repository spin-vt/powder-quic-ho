set -ex
COMMIT_HASH=$1
BINDIR=`dirname $0`
ETCDIR=/local/repository/etc
source $BINDIR/common.sh

if [ -f $SRCDIR/srs-setup-complete ]; then
  echo "setup already ran; not running again"
  exit 0
fi

# use latest UHD from Ettus PPA; 4.6.0 as of 06/2024.
# there seems to be an issue with 4.4 that affects the x310.
sudo add-apt-repository -y ppa:ettusresearch/uhd
sudo apt-get update
sudo apt-get install -y libuhd-dev uhd-host

sudo apt-get install -y \
  cmake \
  make \
  gcc \
  g++ \
  iperf3 \
  pkg-config \
  libboost-dev \
  libfftw3-dev \
  libmbedtls-dev \
  libsctp-dev \
  libyaml-cpp-dev \
  libgtest-dev \
  numactl \
  ppp


## SRCDIR and SRS_PROJECT_REPO configured in common.sh
cd $SRCDIR
git clone $SRS_PROJECT_REPO
cd srsRAN_Project
# git checkout $COMMIT_HASH
mkdir build
cd build
cmake ../
make -j $(nproc)

echo configuring nodeb...
mkdir -p $SRCDIR/etc/srsran
cp -r $ETCDIR/srsran/* $SRCDIR/etc/srsran/
LANIF=`ip r | awk '/192\.168\.1\.0/{print $3}'`
if [ ! -z $LANIF ]; then
  LANIP=`ip r | awk '/192\.168\.1\.0/{print $NF}'`
  echo LAN IFACE is $LANIF IP is $LANIP.. updating nodeb config
  find $SRCDIR/etc/srsran/ -type f -exec sed -i "s/LANIP/$LANIP/" {} \;
  IPLAST=`echo $LANIP | awk -F. '{print $NF}'`
  find $SRCDIR/etc/srsran/ -type f -exec sed -i "s/GNBID/$IPLAST/" {} \;
else
  echo No LAN IFACE.. not updating nodeb config
fi
echo configuring nodeb... done.

touch $SRCDIR/srs-setup-complete
