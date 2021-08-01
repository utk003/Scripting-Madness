#!/usr/local/bin/bash
# !/bin/bash

# --------------------------------------------------------------------------------------------- #
# File Size Change Tracker                                                                      #
# @author Utkarsh Priyam (utk003)                                                               #
# @version Wednesday, June 30, 2021                                                             #
# --------------------------------------------------------------------------------------------- #
# This script compares the files present in 2 different locations (both provided as arguments). #
# It compares the relative sizes of corresponding files and indicates whether any given file    #
# has increased in size, decreased in size, or neither. If it has changed, the resulting table  #
# also includes the amount (in the most appropriate units) by which the file size has changed.  #
# Additionally, the last row of the table includes an overall change, which can help judge      #
# whether most of the changes were actual additions and removals or just from moved files.      #
#                                                                                               #
# NOTE: This script assumes that all of the files are located at the same paths relative to     #
# the provided locations. Each mismatched/moved file will appear twice in the resulting table,  #
# indicated that the file is missing in one location and new in another.                        #
# --------------------------------------------------------------------------------------------- #

# ------------------------------------------------------------------------------ #
# LICENSE:                                                                       #
# ------------------------------------------------------------------------------ #
# MIT License                                                                    #
#                                                                                #
# Copyright (c) 2021 Utkarsh Priyam                                              #
#                                                                                #
# Permission is hereby granted, free of charge, to any person obtaining a copy   #
# of this software and associated documentation files (the "Software"), to deal  #
# in the Software without restriction, including without limitation the rights   #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      #
# copies of the Software, and to permit persons to whom the Software is          #
# furnished to do so, subject to the following conditions:                       #
#                                                                                #
# The above copyright notice and this permission notice shall be included in all #
# copies or substantial portions of the Software.                                #
#                                                                                #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  #
# SOFTWARE.                                                                      #
# ------------------------------------------------------------------------------ #

# save current working dir
curr=`pwd`

[ -z "$1" ] && echo "old path not specified" && exit
[ -z "$2" ] && echo "new path not specified" && exit

[ ! -d "$1" ] && echo "old directory does not exist" && exit
[ ! -d "$2" ] && echo "new directory does not exist" && exit

newLine=$'\n'

echo "Comparing $1 (old)${newLine}to $2 (new)"

cd $1
old=$(find . -type f -exec du -cs {} + | awk '{print $2,$1}' | sort)

cd $2
new=$(find . -type f -exec du -cs {} + | awk '{print $2,$1}' | sort)

cd $curr

declare -A changes
onFileName=true
id=""

for out in $old
do
    if $onFileName; then
        id="$out"
        onFileName=false
    else
        changes["$id"]=$((0-$out))
        onFileName=true
    fi
done
for out in $new
do
    if $onFileName; then
        id="$out"
        onFileName=false
    else
        changes["$id"]=$((${changes["$id"]}+$out))
        onFileName=true
    fi
done

# changes contains change amounts in multiples of 512 bytes

res=""
noColor='\033[0m'
for id in "${!changes[@]}"; do
    abs=${changes[$id]}
    col=''
    if (($abs < 0)); then
        abs=$((0-$abs))
        col='\033[0;31m'
    elif (($abs > 0)); then
        col='\033[0;32m'
    else
        col=$noColor
    fi
    if [ $id != "total" ]; then
        res="$abs ${changes[$id]} $id $col $noColor$newLine$res"
    fi
done

res=$(echo "$res" | sed 's/^.$//')
res=$(echo "$res" | sort -nr | awk '{
    if ($2 == 0)
        $2 = "0 bytes"
    else {
        abs = $2 < 0 ? -$2 : $2;
        
        abs = abs * 512;
        start = "   ";
        end = "";
        
        if (abs < 1000) {
            start = "≈ ";
            end = " bytes";
        } else if ((abs /= 1000) < 1000)
            end = " KB";
        else if ((abs /= 1000) < 1000)
            end = " MB";
        else if ((abs /= 1000) < 1000)
            end = " GB";
        else if ((abs /= 1000) < 1000)
            end = " TB";
        else {
            abs /= 1000;
            end = " PB";
        }
        
        abs = int(10 * abs + 0.5) / 10.0;
        $2 = start ($2 < 0 ? "-" : "+") abs end;
    }
    
    if(length($3) > 80)
        print "..." $4 substr($3,length($3)-76,77) "`" $2 $5;
    else
        print $4 $3 "`" $2 $5;
}')

echo "----------------------------------------------------------------------------------------------"
echo "Relative File Path                                                             Size Difference"
echo "----------------------------------------------------------------------------------------------"

res=$(echo "$res" | column -s '`' -t)
echo -e "$res"

echo "----------------------------------------------------------------------------------------------"
col=''
if ((${changes["total"]} < 0)); then
    col='\033[0;31m'
elif ((${changes["total"]} > 0)); then
    col='\033[0;32m'
else
    col=$noColor
fi

padding="    "
sign="+"
delta=${changes["total"]}
if (($delta < 0)); then
    delta=$((0-$delta))
    sign="-"
fi

approx=""
units=""
if (($delta == 0)); then
    padding=""
    sign=""
    units="bytes"
else
    delta=$(($delta * 512))
    if (($delta < 1000)); then
        units="bytes"
        approx="≈ "
    else
        delta=$(($delta / 1000))
        if (($delta < 1000)); then
            units="KB"
        else
            delta=$(($delta / 1000))
            if (($delta < 1000)); then
                units="MB"
            else
                delta=$(($delta / 1000))
                if (($delta < 1000)); then
                    units="GB"
                else
                    delta=$(($delta / 1000))
                    if (($delta < 1000)); then
                        units="TB"
                    else
                        delta=$(($delta / 1000))
                        units="PB"
                    fi
                fi
            fi
        fi
    fi
fi

echo -e "${col}Total                                                                            $padding$approx$sign$delta $units$noColor"
echo "----------------------------------------------------------------------------------------------"

