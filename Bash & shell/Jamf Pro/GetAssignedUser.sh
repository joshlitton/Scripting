url="https://motherteresa.jamfcloud.com"
client_id="646584ef-d7a5-4c05-a742-6de1214274a6"
client_secret="SHL0TcJttNSOIa-QeiZTOIBXiV8Hg7DpQvK-xenFaF_KW7yTCcxcqC8hpfAPKW1N"
grant_type="client_credentials"

# Input CSV must have columns: serial_number,device_type
csv="/Users/josh.litton/Desktop/WT712MTCL004 - Lease Return.csv"
output="/Users/josh.litton/Desktop/export.csv"
echo "serial_number, assigned_user" > "$output"



endpoint="${url}/api/v1/oauth/token"
token_response=$(curl -s -X POST "$endpoint" \
  -H "accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$client_id&client_secret=$client_secret&grant_type=$grant_type")

access_token=$(echo "$token_response" | jq -r '.access_token')

# Provide URL, Token, Serial as params
GetDeviceAssignedUser () {
  filter="section=USER_AND_LOCATION&filter=serialNumber==$3"
  endpoint="${1}/api/v2/mobile-devices/detail?$filter"
  
  response=$(curl -s -X GET "$endpoint" \
  -H "accept: application/json" \
  -H "Authorization: Bearer $2") 
  
  count=$(echo $response | jq '.totalCount')
  if [[ $count -eq 0 ]]; then
    echo "Mobile Device not found"
  else
    assignedUser=$(echo $response | jq -r '.results[0].userAndLocation.realName')
    if [[ -z ${assignedUser} || ${assignedUser} == null ]]; then
      echo "No User Found"
    else
      echo "$assignedUser"
    fi
  fi
}

GetComputerAssignedUser () {
  filter="section=USER_AND_LOCATION&filter=hardware.serialNumber==$3"
  endpoint="$1/api/v2/computers-inventory?$filter"
  
  response=$(curl -s -X GET "$endpoint" \
  -H "accept: application/json" \
  -H "Authorization: Bearer $2") 
  
  count=$(echo $response | jq '.totalCount')
  if [[ $count -eq 0 ]]; then
    echo "Computer not found"
  else
    assignedUser=$(echo $response | jq -r '.results[0].userAndLocation.realname')
    if [[ -z ${assignedUser} || ${assignedUser} == null ]]; then
      echo "No User Found"
    else
      echo "$assignedUser"
    fi
  fi
}


{
  read -r header
  while IFS=',' read -r serial_number device_type; do
    device=$(printf '%q\n' "$device_type")
    device=$(echo $device_type | tr -d '\r' | xargs | tr '[:upper:]' '[:lower:]')
    echo "Processing: $serial_number | $device"

    
    [[ -z "$serial_number" || "$serial_number" == "serial_number" ]] && continue
    
    case "$device" in 
      computer)
        user=$(GetComputerAssignedUser $url $access_token $serial_number)
      ;;
      device)
        user=$(GetDeviceAssignedUser $url $access_token $serial_number)
      ;;
      *) 
        user="Unknown_Device_Type"
        esac
        echo $serial_number,$user >> "$output"
      done
} < "$csv"
        

#serial="T7VKXHW2FY"
#GetDeviceAssignedUser $url $access_token $serial
#
#serial="FVFZV218LYWJ"
#GetComputerAssignedUser $url $access_token $serial