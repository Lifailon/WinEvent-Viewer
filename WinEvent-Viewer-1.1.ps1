#region Functions
$path = "$env:USERPROFILE\Documents\WEV-srv-list.txt"

function srv-list {
if (!(Test-Path $path)) {
@("localhost") > $path
}
$srv_list = cat $path
$ListBox_Srv.Items.Clear()
foreach ($ForList in $srv_list) {
$ListBox_Srv.Items.ADD($ForList)
}
}

function table-columns {
$DataGridView.ColumnCount = 6
$DataGridView.Columns[0].Name = "Time"
$DataGridView.Columns[1].Name = "ID"
$DataGridView.Columns[2].Name = "Level"
$DataGridView.Columns[3].Name = "LogName"
$DataGridView.Columns[4].Name = "Provider"
$DataGridView.Columns[5].Name = "Message"
}

function Fun-WinEvent ($MaxEvents) {
$Log_Name = $ListBox_ListLog.selectedItem
$global:Log_Grid = Get-WinEvent -LogName $Log_Name -MaxEvents $MaxEvents
add-dgv $Log_Grid
}

function add-dgv ($pout) {
$DataGridView.ColumnCount = $null
table-columns

foreach ($ForList in $pout) {
$DataGridView.Rows.Add($ForList.TimeCreated,$ForList.ID,$ForList.LevelDisplayName,
$ForList.LogName,$ForList.ProviderName,$ForList.Message)
if ($ForList.Level -eq 4) {
$DataGridView.Rows[-2].Cells[2].Style.BackColor = "lightgreen"
} elseif ($ForList.Level -eq 3) {
$DataGridView.Rows[-2].Cells[2].Style.BackColor = "gold"
} elseif ($ForList.Level -eq 2) {
$DataGridView.Rows[-2].Cells[2].Style.BackColor = "red"
}
}

$Mcount = $pout.Count
$Status.Text = "Events count: $Mcount"
}
#endregion

#region Forms
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ="WinEvent-Viewer"
$main_form.Width = 1400
$main_form.Height = 875
$main_form.Font = "Arial,12"
$main_form.AutoSize = $false
$main_form.StartPosition = "CenterScreen"
$main_form.ShowIcon = $False
$main_form.FormBorderStyle = "FixedSingle"

$ListBox_Srv = New-Object System.Windows.Forms.ListBox
$ListBox_Srv.Location  = New-Object System.Drawing.Point(10,10)
$ListBox_Srv.Size = New-Object System.Drawing.Size(250,400)
$main_form.Controls.add($ListBox_Srv)

$ListBox_ListLog = New-Object System.Windows.Forms.ListBox
$ListBox_ListLog.Location  = New-Object System.Drawing.Point(10,415)
$ListBox_ListLog.Size = New-Object System.Drawing.Size(600,400)
$main_form.Controls.add($ListBox_ListLog)

$TextBox_Search = New-Object System.Windows.Forms.TextBox
$TextBox_Search.Location = New-Object System.Drawing.Point(265,10)
$TextBox_Search.Size = New-Object System.Drawing.Size(1120)
$main_form.Controls.Add($TextBox_Search)

$global:DataGridView = New-Object System.Windows.Forms.DataGridView
$DataGridView.Location = New-Object System.Drawing.Point(265,40)
$DataGridView.Size = New-Object System.Drawing.Size(1120,370)
$DataGridView.Font = "Arial,10"
$DataGridView.AutoSizeColumnsMode = "Fill" 
$DataGridView.AutoSize = $false
$DataGridView.MultiSelect = $false
$DataGridView.ReadOnly = $true
$DataGridView.TabIndex = 0
$main_form.Controls.Add($DataGridView)

$TextBox_Message = New-Object System.Windows.Forms.TextBox
$TextBox_Message.Location = New-Object System.Drawing.Point(615,415)
$TextBox_Message.Size = New-Object System.Drawing.Size(770,400)
$TextBox_Message.MultiLine = $True
$main_form.Controls.Add($TextBox_Message)

$VScrollBar = New-Object System.Windows.Forms.VScrollBar
$TextBox_Message.Scrollbars = "Vertical"

$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$Status = New-Object System.Windows.Forms.ToolStripStatusLabel
$main_form.Controls.Add($statusStrip)
$StatusStrip.Items.Add($Status)
$Status.Text = "Github: Lifailon"
#endregion

#region ContextMenu
$ContextMenu_srv = New-Object System.Windows.Forms.ContextMenu
$ListBox_Srv.ContextMenu = $ContextMenu_srv

$ContextMenu_srv.MenuItems.Add("View List Log",{
$global:srv = $ListBox_Srv.selectedItem
$global:ListLog = Get-WinEvent -cn $srv -ListLog *
$ListLog_Name = ($ListLog | where RecordCount -gt 0).LogName
$ListBox_ListLog.Items.Clear()
foreach ($ForList in $ListLog_Name) {
$ListBox_ListLog.Items.Add($ForList)
}
})

$ContextMenu_srv.MenuItems.Add("Change Server List",{
ii $path
})

$ContextMenu_srv.MenuItems.Add("Update Server List",{
srv-list
})

$ContextMenu_List = New-Object System.Windows.Forms.ContextMenu
$ListBox_ListLog.ContextMenu = $ContextMenu_List
$ContextMenu_List.MenuItems.Add("View 1000 events",{Fun-WinEvent 1000})
$ContextMenu_List.MenuItems.Add("View 5000 events",{Fun-WinEvent 5000})
$ContextMenu_List.MenuItems.Add("View 10000 events",{Fun-WinEvent 10000})
$ContextMenu_List.MenuItems.Add("View 20000 events",{Fun-WinEvent 20000})
$ContextMenu_List.MenuItems.Add("View 30000 events",{Fun-WinEvent 30000})

$ListBox_ListLog.add_click({
$Log_Name = $ListBox_ListLog.selectedItem
$status_count_listlog = $ListLog | where LogName -Like $Log_Name
$scl = $status_count_listlog.RecordCount 
$Status.Text = "Events count: $scl to $Log_Name"
})

$DataGridView.add_click({
$Column = 5
$RowIndex = @($dataGridView.SelectedCells.RowIndex)
$TextBox_Message.Text = $dataGridView.Rows[$RowIndex].Cells[$Column].FormattedValue
})

$TextBox_Search.Add_TextChanged({
$search_text = $TextBox_Search.Text
$search_out = @($Log_Grid | Where {$_.Message -match $search_text})
add-dgv $search_out
})
#endregion

srv-list
table-columns
$main_form.ShowDialog()