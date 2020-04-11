#!/bin/bash
#Use awk to do the heavy lifting.
#For lines with UID>=1000 (field 3) grab the home directory (field 6)
usrInfo=$(awk -F: '{if ($3 >= 1000 && $6 != "/nonexistent") print $6}' < /etc/passwd)

IFS=$'\n' #Use newline as delimiter for for-loop
for usrLine in $usrInfo
do
  #Do processing on each line
  echo $usrLine
  echo $(getent passwd $USER | cut -d : -f 5) $usrLine
  w $usrLine
  echo -ne '\e[0;34m' Disk: '\e[m' "$(df -h $usrLine)" "\n"
  ls -ltr --block-size=KB $usrLine
  echo aa=$($usrInfo | cut -d: -f5)
  ps -u $aa
  ps --sort=-pcpu | head -n 6
done
own=$(id -nu)
cpus=$(lscpu | grep "^CPU(s):" | awk '{print $2}')

for user in $(who | awk '{print $1}' | sort -u)
do
    # print other user's CPU usage in parallel but skip own one because
    # spawning many processes will increase our CPU usage significantly
    if [ "$user" = "$own" ]; then continue; fi
    (top -b -n 1 -u "$user" | awk -v user=$user -v CPUS=$cpus 'NR>7 { sum += $9; } END { print user, sum, sum/CPUS; }') &
    # don't spawn too many processes in parallel
    sleep 0.05
done
wait
echo "----------------------------------------------------------"
echo "Total CPU and MEMORY usage in a concise format:"
# print own CPU usage after all spawned processes completed
echo "User|%CPU|Memory"
top -b -n 1 -u "$own" | awk -v user=$own -v CPUS=$cpus 'NR>7 { sum += $9; } END { print user, sum, sum/CPUS; }'

