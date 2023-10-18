#!/bin/bash

arg=$1

if [ ! -d DIR.$arg ]; then
  mkdir DIR.$arg
fi

cp prompt_chat_GPT.py DIR.$arg
cp proteins.csv DIR.$arg
cd DIR.$arg

for i in {1..10}
do
    echo $i
    echo $arg
    python ./prompt_chat_GPT.py $arg > $i.output.txt;
    wc -l $i.output.txt
    wc -l prompt_chat_gpt.output.txt
    mv prompt_chat_gpt.output.txt $i.long.output.txt;
done

