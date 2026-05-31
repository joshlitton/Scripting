#!/bin/bash

# Path to SwiftDialog binary
DIALOG="/usr/local/bin/dialog"

# Function to check if SwiftDialog is running
is_dialog_running() {
    pgrep -f "dialog" > /dev/null
}

# Loop to keep the dialog running during the lockdown period
while true; do
    # Get current time in HHMM format
    CURRENT_TIME=$(date +"%H%M")

    # If time is between 15:30 (1530) and 08:30 (0830 next day)
    
    if [[ "$CURRENT_TIME" -ge 1530 || "$CURRENT_TIME" -lt 830 ]]; then
        if ! is_dialog_running; then
            "$DIALOG" --fullscreen \
                      --button1text "Dismiss" \
                      --title "Notification" \
                      --message "This is a fullscreen SwiftDialog window." &  # Run in background
        fi
    else
        # If outside lockdown hours, kill SwiftDialog if running
        pkill -f "dialog"
    fi

    # Sleep for 60 seconds before checking again
    sleep 60
done