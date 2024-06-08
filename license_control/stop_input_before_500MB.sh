index=_internal earliest=-1@d sourcetype=splunkd source=*license_usage.log type=Usage
| eval MB_Used = b / 1024 / 1024
| stats sum(MB_Used)
