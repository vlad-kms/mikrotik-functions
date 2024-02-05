### 1.

# Create a temp global variable
:global ABC ""

# Execute the ping in background and get the jobId
:local jobId [:execute {:global ABC [:ping count=5 192.168.88.1]}]

# Waits the job end
:while ([:len [:system script job find .id=$jobId]] > 0) do={
    :delay 1s;
}

# Use the result on the global variable
:put $ABC

### 2.
:global pingResult -1
{
    :local jobID [:execute ":set pingResult [:ping count=5 1.1.1.1]"]
    :while ([:len [/system script job find where .id=$jobID]] > 0) do={
        :delay 1s
    }
}
:put $pingResult
