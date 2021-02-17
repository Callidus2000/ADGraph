@{
	'Add-ADGraphEdge.Start'              = "[{0}] Getting edges for startObjectDN {1}, linkAttribute={2}" # ($recursionLevel), $startObjectDN, $linkAttribute
	'Add-ADGraphEdge.startObject'        = "startObject={0}" # $startObject
	'Add-ADGraphEdge.differentTimeline'  = "Different timeline Epoche: {0} und {1}" # $startObjectDN, $linkDN
	'Get-ADGraphElapsedTime.Message1'    = "Start Stopwatch" #
	'Get-ADGraphElapsedTime.Message2'    = "[{0}]  {1}" # $global:stopwatch.Elapsed.TotalSeconds, $Message
	'New-ADGraphExcelFile.Start'          = "Ermittle Verknüpfungen der Start-Objekte: {0}, LinkAttribute {1}, RemoveUsers={2}" #($StartObjectDN -join ';'),($LinkAttribute -join ';'),$RemoveUsers
	'New-ADGraphExcelFile.changeLabel'    = "Change label from {0} to t{1}"
	'New-ADGraphExcelFile.startObject'    = "startObject={0}" # $startObject
	'New-ADGraphExcelFile.circleRelation' = "Error, circle reference!"
	'New-ADGraphGroupGraph.CreateGraph'   = "Creating graph from {0} startObjects with {1} relations" # $measurement.Count, $allEdgeObjects.count
}