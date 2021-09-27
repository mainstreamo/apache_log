#! /bin/bash

LOG_FILE=$1
TIME_LIMIT=$2
if [ -z "$LOG_FILE" ] || [ -z "$TIME_LIMIT" ]; then
    echo "Please pass paramters: bash main.sh path_to_log_file minutes_to_check"
    exit 1
fi

MAIL_LIST="1@email.com 2@email.com"

CODES=$(cat ${LOG_FILE} | awk '{print $9}')

#To prevent bash errors related to disappearing variables set/updated in piped loops we will use two files to track error counts.
touch /tmp/5XX
touch /tmp/4XX
# Define empty arrays
ERR_400=()
ERR_500=()

TIME_LIMIT=$(date  "+%s" -d "${TIME_LIMIT} min ago")

COUNT=0
# We using tac, it slower than cat, but on the really big files it will give us speed-up and will save resources.
tac ${LOG_FILE} | while IFS= read -r line; do 
    # tac reads file from the end, we convert date into epoch and checking if it's greater than ${TIME_LIMIT}.
    TIME_STAMP=$(echo $line | awk '{print $4}' | sed -e 's/\//-/g' -e 's/:/ /' -e 's/\[//g' | xargs -0 date +"%s" -d)
    if [[ ${TIME_STAMP} -gt ${TIME_LIMIT} ]]; then
        CODE=$(echo "${line}" | awk '{print $9}')
        #This is a bit dirty, but we check if exit code on the current log line fits into 400/599
        #We split those two ranges, to have more information in the final report.
        #We can split it even more, if we like, or maybe we can use something more flexible/reusable, like function.
        if [[ ${CODE} -gt 399 ]] && [[ ${CODE} -lt 500 ]]; then
            ERR_400+=(${CODE})
            echo "${#ERR_400[@]}" > /tmp/4XX 
        fi
        if [[ ${CODE} -gt 499 ]] && [[ ${CODE} -lt 600 ]]; then
            ERR_500+=(${CODE})
            echo "${#ERR_500[@]}" > /tmp/5XX
        fi
    else
        break
    fi
    printf "\r[$((COUNT=COUNT+1))]" # So called "status bar"
done
FIVES=$(cat /tmp/5XX)
FOURS=$(cat /tmp/4XX)
TOTAL_ERR=$((FIVES+FOURS))
echo -e "\r4XX: ${FOURS}, 5XX: ${FIVES}"
if [[ ${TOTAL_ERR} -gt 100 ]]; then
    aws ses send-email --from alert@logs.com --to "${MAIL_LIST}" --text "4XX: ${FOURS}, 5XX: ${FIVES}" --subject "Too many errors!"
    else
    echo "Everything is okay!"
fi
#Clean up
rm /tmp/5XX
rm /tmp/4XX