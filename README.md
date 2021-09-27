# Description

This script counts 4XX and 5XX errors in the log for last 15 minute, and reports to email if there is more than 100 errors.

## Usage

Feel free to edit script if you like.

To test, you can build docker image (if you using linux you can skip that part, just make sure you have awscli installed):
```
docker build . -t script
```

Run container:
```
docker run -ti script /bin/bash
```

Now you might want to login into your AWS account (We send emails using aws ses, if there is more then 100 errors)
```
aws configure
```
To run script, you need to pass two parameters:
```
bash main.sh path_to_log_file last_minutes_to_check
```
You can run script using demo data, it's quite old, and if you want to see script running, extend amount of minutes you want to check:
```
bash main.sh apache_logs 10000000
```