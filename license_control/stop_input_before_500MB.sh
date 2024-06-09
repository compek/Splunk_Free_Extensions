#!/bin/bash
STOP_AT=490000000
BYTES=$(/opt/splunk/bin/splunk search ' index=_internal earliest=@d sourcetype=splunkd source=*license_usage.log type=Usage |stats sum(b)' 2>/dev/null | tail -n 1)
if [[ $BYTES >= $STOP_AT]]; then
  # splunk edit monitor your_input_name -disabled true
  # splunk disable listen port
fi
