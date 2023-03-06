#!/bin/bash
R=./test
mkdir -pv $R
mkdir -pv $R/root
echo '#!/bin/bash' > $R/root/yiffosP2
echo 'KVER=$(bulge list | grep -e "^linux " | grep -oP "[\d\.]+-")' >> $R/root/yiffosP2
echo 'echo $KVER' >> $R/root/yiffosP2
