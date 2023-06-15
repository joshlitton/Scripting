#Import your modules

# Define your constants
$odbc = "SYNERGETIC"

# Create our table for storing records
$DataTable = New-Object System.Data.DataTable
$DataTable.Columns.Add("Staff_ID", "System.String")
$DataTable.Columns.Add("First_Name", "System.String")
$DataTable.Columns.Add("Last_Name", "System.String")
$DataTable.Columns.Add("Email", "System.String")
$DataTable.Columns.Add("Phone", "System.String")
$DataTable.Columns.Add("Job_Title", "System.String")
$DataTable.Columns.Add("Active", "System.Boolean")
$DataTable.Columns.Add("ExistInAD", "System.Boolean")

# Create an ODBC connection
$conn = New-Object -ComObject ADODB.Connection
# Open 64-bit ODBC connection
$conn.Open("$odbc")
# Define the query
$query = "Select StaffID, StaffSurname, StaffGiven1, StaffOccupEmail, OccupDesc, OccupPhone, ActiveFlag
from dbo.vStaff
left join dbo.Community
ON dbo.vStaff.StaffID=dbo.Community.ID
WHERE ActiveFlag = 1"


# Execute a query
$results = $conn.Execute("$query")

while ($results.EOF -ne $True){
    # Next entry, new row in table
    $DataRow = $DataTable.NewRow()
    foreach ($field in $results.Fields){
        switch ($field.Name) {
            # "Synergetic Field" {$DataRow.TableField = $field.Value}
            "StaffID" {[string]$DataRow.Staff_ID = $field.Value}
            "StaffGiven1" {[string]$DataRow.First_Name = $field.Value}
            "StaffSurname" {[string]$DataRow.Last_Name = $field.Value}
            "StaffOccupEmail" {[string]$DataRow.Email = $field.Value}
            "OccupPhone" {[string]$DataRow.Phone = $field.Value}
            "OccupDesc" {[string]$DataRow.Job_Title = $field.Value}
            "ActiveFlag" {[bool]$DataRow.Active = $field.Value}
        }
    }
    # Add the row to our table
    $DataTable.Rows.Add($DataRow)
    $results.MoveNext()
}
$conn.Close()