#!/bin/sh

# 1. Find the Java PID
TARGET_PID=""
for pid in $(ls -d /proc/[0-9]* | sed "s|/proc/||"); do
  if grep -q "java" /proc/$pid/cmdline 2>/dev/null; then
    TARGET_PID=$pid
    break
  fi
done

if [ -z "$TARGET_PID" ]; then
  echo "Error: Could not find Java process."
  exit 1
fi

echo "Found Java PID: $TARGET_PID"

# 2. Identify ESTABLISHED TCP Sockets only
# We read /proc/net/tcp (IPv4) and tcp6 (IPv6)
# Column 4 is State (01 = ESTABLISHED). Column 10 is the Inode.
echo "Scanning for established external connections..."
EST_INODES=$(cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | awk '$4 == "01" {print $10}')

# 3. Match FDs to those Inodes
GDB_CMD="gdb -p $TARGET_PID -batch"
COUNT=0

# Loop through all sockets the process has open
# Format of ls -l output: ... 263 -> socket:[1138502]
for socket_link in $(ls -l /proc/$TARGET_PID/fd | grep "socket:\[" | awk '{print $9":"$11}'); do
  FD=$(echo $socket_link | cut -d: -f1)
  INODE=$(echo $socket_link | cut -d: -f3 | tr -d '[]')

  # Check if this socket's Inode is in our list of Established connections
  if echo "$EST_INODES" | grep -q "$INODE"; then
    echo "   - Targeting FD $FD (Inode $INODE) -> ESTABLISHED TCP"
    GDB_CMD="$GDB_CMD -ex \"call (int)close($FD)\""
    COUNT=$((COUNT+1))
  else
    # This is likely a Listening port or Unix socket - LEAVE IT ALONE
    echo "   - Skipping FD $FD (Inode $INODE) -> Listening or Internal"
  fi
done

if [ "$COUNT" -eq 0 ]; then
  echo "No targetable connections found."
else
  echo "Closing $COUNT connections..."
  eval $GDB_CMD
  echo "Connections closed."
fi

