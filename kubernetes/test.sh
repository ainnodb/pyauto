#!/bin/bash
i=0
str='#'
ch=('|' '\' '-' '/')
index=0
while [ $i -le 25 ]
do
    printf "[%-25s][%d%%][%c]\r" $str $(($i*4)) ${ch[$index]}
    str+='#'
    let i++
    let index=i%4
    sleep 0.1
done
printf "\n"
echo "...."
