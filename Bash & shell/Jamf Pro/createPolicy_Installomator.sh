#!/bin/zsh
jamfURL="https://sbcwa.jamfcloud.com"
authBase64="amFtZl9hcGlfdXNlcjpYSkFCWm1jYkdwV0UzQTlK"
#jh="/Library/Application Support/Jamf/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
#Establish empty array
#matchedDevices=()

authToken=$(curl -sk ${jamfURL}/api/v1/auth/token -X POST -H "Authorization: Basic ${authBase64}")
api_token=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )

#response=$(curl -X 'GET' "${jamfURL}/JSSResource/policies" \
#-H "accept: application/xml" \
#-H "Authorization: Bearer ${api_token}")

xml="<policy>
	<general>
		<name>Install - Company Portal</name>
		<enabled>true</enabled>
		<trigger>EVENT</trigger>
		<trigger_checkin>false</trigger_checkin>
		<trigger_enrollment_complete>false</trigger_enrollment_complete>
		<trigger_login>false</trigger_login>
		<trigger_network_state_changed>false</trigger_network_state_changed>
		<trigger_startup>false</trigger_startup>
		<trigger_other>install-mscp</trigger_other>
		<frequency>Ongoing</frequency>
		<retry_event>none</retry_event>
		<retry_attempts>-1</retry_attempts>
		<notify_on_each_failed_retry>false</notify_on_each_failed_retry>
		<location_user_only>false</location_user_only>
		<target_drive>/</target_drive>
		<offline>false</offline>
		<category>
			<id>36</id>
			<name>_Student - MacOS - 1to1 Deployment</name>
		</category>
		<site>
			<id>-1</id>
			<name>None</name>
		</site>
	</general>
	<scope>
		<all_computers>false</all_computers>
		<computers/>
		<computer_groups>
			<computer_group>
				<id>21</id>
				<name>_Student - MacOS - 1to1 Deployment</name>
			</computer_group>
		</computer_groups>
		<buildings/>
	</scope>
	<self_service>
		<use_for_self_service>false</use_for_self_service>
		<self_service_display_name>Setup Your Mac - Student</self_service_display_name>
		<install_button_text>Install</install_button_text>
		<reinstall_button_text>Reinstall</reinstall_button_text>
		<self_service_description/>
		<force_users_to_view_description>false</force_users_to_view_description>
		<self_service_icon>
			<id>151</id>
			<filename>Main-Debt-Recovery-Services.png</filename>
			<uri>https://apse2.ics.services.jamfcloud.com/icon/hash_47262033da20e74bd531a12d91d828512c5c724a798343c16ffc8eb665d93f2b</uri>
		</self_service_icon>
		<feature_on_main_page>false</feature_on_main_page>
		<self_service_categories/>
		<notification>false</notification>
		<notification_type>Self Service</notification_type>
		<notification_subject>Setup Your Mac - Student</notification_subject>
		<notification_message/>
	</self_service>
	<scripts>
		<size>1</size>
		<script>
			<id>1</id>
			<name>Installomator_MultiLabel</name>
			<priority>After</priority>
			<parameter4>microsoftcompanyportal</parameter4>
			<parameter5>ignore</parameter5>
			<parameter6>silent</parameter6>
			<parameter7>INFO</parameter7>
			<parameter8>false</parameter8>
			<parameter9/>
			<parameter10/>
			<parameter11/>
		</script>
	</scripts>
</policy>"

response=$(curl -X 'POST' "${jamfURL}/JSSResource/policies/id/84" \
-H "accept: application/xml" \
-H "Content-Type: application/xml" \
-H "Authorization: Bearer ${api_token}" \
--data "${xml}")

echo $response

#read -p "Enter the device AssetID: " userEnteredTag
#userEnteredTag=$(osascript -e 'text returned of (display dialog "Enter the asset tag of lost device" default answer "JS100144" buttons {"Submit"} default button 1)')
#echo "User entered ${userEnteredTag}"

# Collect all of the IDs
#q=$(curl -sk -X GET "${jamfURL}/JSSResource/mobiledevices" \
#-H "accept: application/xml" \
#-H "Authorization: Bearer ${api_token}")

# Validate the data
#echo ${q} | xmllint --format -