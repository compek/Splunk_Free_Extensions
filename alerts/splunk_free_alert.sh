#!/bin/bash
#set -xe
set -e
NAME_OF_ALERT="Check license usage"
THROTTLE_PERIOD_IN_MIN=360
THROTTLE_FOLDER=/tmp
DEBUG=0

function call_alert() {
  if [ $DEBUG -eq 1]; then echo "Triggering Alert"; fi
  #swaks --to recipient@example.com --from your_email@example.com --server smtp.example.com --port 587 --auth LOGIN --auth-user your_username --auth-password your_password --header "Subject: Alerts" --body "The license usage is $BYTES bytes."
}

BYTES=$(/opt/splunk/bin/splunk search ' index=_internal earliest=@d sourcetype=splunkd source=*license_usage.log type=Usage |stats sum(b)' 2>/dev/null | tail -n 1)
if [ $DEBUG -eq 1 ]; then echo Bytes: $BYTES; fi
NAME_OF_ALERT_SANITIZED=$(echo "$NAME_OF_ALERT" | sed 's/[^A-Za-z0-9]/_/g')
if [ $DEBUG -eq 1 ]; then echo NAME_OF_ALERT_SANITIZED $NAME_OF_ALERT_SANITIZED; fi
if [[ $BYTES -gt 4900 ]]; then
  # check for throttle file, stop if it still active, delete is if it is expired
  REGEX="${THROTTLE_FOLDER}/throttle_${NAME_OF_ALERT_SANITIZED}_[0-9]+_[0-9]+\\.txt"
  MATCHING_THROTTLE_FILES=($(find $THROTTLE_FOLDER -maxdepth 1 -type f -regex "$REGEX"))
  if [ ${#MATCHING_THROTTLE_FILES[@]} -eq 0 ]; then
      if [ $DEBUG -eq 1 ]; then echo "No matching files found."; fi
      # create a throttle file. Format: name_timestamp-unix_timestamp-readable
      touch "${THROTTLE_FOLDER}/throttle_${NAME_OF_ALERT_SANITIZED}_$(date +%s)_$(date +'%Y%m%d%H%M%S').txt"
      call_alert
  elif [ ${#MATCHING_THROTTLE_FILES[@]} -eq 1 ]; then
      if [ $DEBUG -eq 1 ]; then echo "One matching file found." ${MATCHING_THROTTLE_FILES[0]}; fi
      UNIX_TIMESTAMP_REGEX="1[78][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
      if [[ ${MATCHING_THROTTLE_FILES[0]} =~ $UNIX_TIMESTAMP_REGEX ]]; then
          UNIX_TIMESTAMP="${BASH_REMATCH[0]}"
          if [ $DEBUG -eq 1 ]; then echo UNIX_TIMESTAMP of ${MATCHING_THROTTLE_FILES[0]} is $UNIX_TIMESTAMP; fi
          UNIX_TIMESTAMP_CURRENT=$(date +%s)
          UNIX_TIMESTAMP_THROTTLE_UNTIL=$(($UNIX_TIMESTAMP + $THROTTLE_PERIOD_IN_MIN * 60))
          if [ $UNIX_TIMESTAMP_CURRENT -gt $UNIX_TIMESTAMP_THROTTLE_UNTIL ]; then
              if [ $DEBUG -eq 1 ]; then echo UNIX_TIMESTAMP_CURRENT is larger than UNIX_TIMESTAMP_THROTTLE_UNTIL, deleting ${MATCHING_THROTTLE_FILES[0]} and calling alert; fi
              rm ${MATCHING_THROTTLE_FILES[0]};
              call_alert
          else
              if [ $DEBUG -eq 1 ]; then echo UNIX_TIMESTAMP_CURRENT is lesser than UNIX_TIMESTAMP_THROTTLE_UNTIL, do nothing ...; fi
          fi
      fi
  else
      if [ $DEBUG -eq 1 ]; then echo "Multiple matching files found:"; fi
      for file in "${MATCHING_THROTTLE_FILES[@]}"; do
          if [ $DEBUG -eq 1 ]; then echo "$file"; fi
      done
  fi
fi
