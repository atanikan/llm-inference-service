import sys
import os
import re
import openai
import json
import requests
import time
import pandas as pd

start_time = time.time()
df = pd.read_csv('proteins.csv', header=None, names=['search_words'])

print(df.head())

with open("prompt_chat_gpt.output.txt","w") as f:

    openai.api_key = "<replace>"
    model_engine = "gpt-3.5-turbo" 
    # This specifies which GPT model to use, as there are several models available, each with different capabilities and performance characteristics.

    # open the input file and read its contents
    depth = 30
    w_list =[] # work list of proteins not prompted yet
    s_list =[] # seen list of proteins we have already prompted


    argument = sys.argv[1]

    if (not argument):
        with open('prompts.txt', 'r') as ff:
            strings = ff.readlines()
            print("no arguments")
            for string in strings:
                w_list.append(string.strip())
    else:
        w_list.append(argument.strip())            

    w_list = list(set(w_list))        
    print(w_list,file=f)
    leng = len(w_list)
    print("leng>",leng)
    while depth > 0 and leng > 0:
        depth = depth - 1
        target = w_list[0]
        s_list.append(target)
        del w_list[0]
        print("------------------------------------------",file=f)
        print("Target -->", target,file=f)
        model_start_time = time.time()
        response = openai.ChatCompletion.create(
            model='gpt-3.5-turbo',
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "We are interested in protein interactions.  Based on the documents you have been trained with, can you provide any information on which proteins might interact with " + target},
            ])
        model_end_time = time.time()
        elapsed_model_time = model_end_time - model_start_time
        print('Total model execution time:', elapsed_model_time, 'seconds')                        
        result = ''
        print(f'The response of openai model for target {target} is {response.choices}')
        for choice in response.choices:
            result += choice.message.content
            
            print(result, file=f)
            
            # Define the string to be searched
            search_string = result
    
            # Define an empty list to store the matches
            matches = []
    
            # Loop through the words in the DataFrame
            for word in df['search_words']:
                # Check if the word is in the search string
                pattern = r"\b{}\b".format(word)
                match = re.search(pattern, search_string)
                if match:
                    # If it is, append the word to the matches list
                    matches.append(word)
            
                # Convert the matches list into a new DataFrame
            matches_u = list(set(matches))        
            matches_df = pd.DataFrame({'match_words': matches_u})

            # Print the new DataFrame
            matches_df = matches_df.drop_duplicates()
            for word in matches_df['match_words']:
                if target != word:
                    print(target,"-->", word)
                    w_list.append(word)
            w_list = list(set(w_list)) # remove duplicates before removing previously seen
            for item in s_list:
                if item in w_list:
                    w_list.remove(item)
            print(w_list, file=f)
            print("-----------------------------------------------",file=f)
            print(" ",file=f)
# get the end time
end_time = time.time()

# get the execution time
elapsed_time = end_time - start_time
print('Total block execution time:', elapsed_time, 'seconds')                        
