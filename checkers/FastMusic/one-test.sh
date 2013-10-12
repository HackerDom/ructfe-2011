#!/bin/bash

key=$RANDOM-$RANDOM-$RANDOM
value=$RANDOM$RANDOM$RANDOM$RANDOM=

echo ruby1.9.1 fastmusic.checker.rb put 127.0.0.1 $key $value
newid=`ruby1.9.1 fastmusic.checker.rb put 127.0.0.1 $key $value`
echo $?

echo ruby1.9.1 fastmusic.checker.rb check 127.0.0.1
ruby1.9.1 fastmusic.checker.rb check 127.0.0.1
echo $?

echo ruby1.9.1 fastmusic.checker.rb get 127.0.0.1 $newid $value
ruby1.9.1 fastmusic.checker.rb get 127.0.0.1 $newid $value
echo $?

