#!/bin/bash

## no argument will find ./proc/buddyinfo
## if there is no ./proc/buddyinfo in current path, then it will show system's /proc/buddyinfo
## specific path/file with argument will be supported

bin=$(basename "$0")
if [ "$#" -ne 1 ];then
  if [ -e "./proc/buddyinfo" ]; then
    buddyinfofile="./proc/buddyinfo"
  else
    buddyinfofile="/proc/buddyinfo"
  fi
else
  buddyinfofile="$1"
fi

if [ -d "$buddyinfofile" ];then
  echo "directory is not allowed"
  exit 1
fi

if [ ! -e "$buddyinfofile" ];then
  echo "check the file $1 exists"
  exit 1
fi

tmpfile="/tmp/buddy$$"
cp "$buddyinfofile" "$tmpfile"
if [ "$?" -ne 0 ];then
  echo "copying file failed"
  ls -l "$buddyinfofile" "$tmpfile"
  exit 2
fi

#Node 0, zone      DMA      2      1      1      1      1      0      1      0      1      1      3 
#Node 0, zone    DMA32     10      9     11     11      9      8      9     13     11      6     96 
#Node 0, zone   Normal  14944   1796     12      0      0      0      0      0      0      0      0 
#Node 1, zone   Normal  51371   4073    316     58     19      7      3      4      1      0      0 
#Node 2, zone   Normal     89   2304   1122    477      2      2      0      1      1      0      0 
#Node 3, zone   Normal  12660     22      1      0      2      2      0      1      1      0      0 

echo -e "READING FILE: [ $buddyinfofile ]\n"
cat "$tmpfile" | while read ONELINE
do
  if [ ! -z "$ONELINE" ]; then
    echo "$ONELINE" | awk '{printf "%s:%s %s:%s\n",$1,$2,$3,$4}'
    value=$(echo "$ONELINE" | awk '{print $5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}')
    order=0 ;sum=0 ; eachsum=0

    for free in $value
    do
      eachsum=$((free*$((2**order))))
      sum=$((sum + eachsum))
      case "$order" in
         0) arr0=$eachsum;; 1) arr1=$eachsum;; 2) arr2=$eachsum;; 3) arr3=$eachsum;; 4) arr4=$eachsum;;
         5) arr5=$eachsum;; 6) arr6=$eachsum;; 7) arr7=$eachsum;; 8) arr8=$eachsum;; 9) arr9=$eachsum;; 10) arr10=$eachsum;;
      esac
      let order+=1
    done

    order=0; free=0; eachsum=0; frag=0; sumfrag=0; overallfrag=0
    printf "Order \t Block \t FreePages \t EachSum \t Frag [%%]\n"

    for free in $value
    do
      block=$((2**order))
      eachsum=$((free*$((2**order))))
      case "$order" in
         0) frag=$((((sum-arr0-arr1-arr2-arr3-arr4-arr5-arr6-arr7-arr8-arr9-arr10)*100/sum)))  ;;
         1) frag=$((((sum-arr1-arr2-arr3-arr4-arr5-arr6-arr7-arr8-arr9-arr10)*100/sum))) ;;
         2) frag=$((((sum-arr2-arr3-arr4-arr5-arr6-arr7-arr8-arr9-arr10)*100/sum))) ;;
         3) frag=$((((sum-arr3-arr4-arr5-arr6-arr7-arr8-arr9-arr10)*100/sum))) ;;
         4) frag=$((((sum-arr4-arr5-arr6-arr7-arr8-arr9-arr10)*100/sum))) ;;
         5) frag=$((((sum-arr5-arr6-arr7-arr8-arr9-arr10)*100/sum))) ;;
         6) frag=$((((sum-arr6-arr7-arr8-arr9-arr10)*100/sum))) ;;
         7) frag=$((((sum-arr7-arr8-arr9-arr10)*100/sum))) ;;
         8) frag=$((((sum-arr8-arr9-arr10)*100/sum))) ;;
         9) frag=$((((sum-arr9-arr10)*100/sum))) ;;
        10) frag=$((((sum-arr10)*100/sum))) ;;
      esac
      printf "%3d \t %5d \t %9d \t %7d \t %5d %%\n" "$order" "$block" "$free" "$eachsum" "$frag"
      let order+=1
      sumfrag=$((sumfrag + frag))
    done
    overallfrag=$((sumfrag/11))

    printf "TotalFreePages: %d\n" "$sum"
    printf "Overall Fragmentation: %d %%\n\n" "$overallfrag"
  fi
done
rm -f "$tmpfile"
