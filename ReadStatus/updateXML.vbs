' This script will be ran by BigFix to write the results (pass|fail) of a fixlet in a baseline to an XML document.
' It can be ran before an after a fixlet is run.
' It depends on qna.exe, which is installed with BigFix.  Each node in the XML document has a relevance ID.  The script is passes the relevance ID, identifies what node number the baseline is on, and then goes through each of the nodes up to the current one and calculates the results and writes them back to the XML document.
' This script functions with two arguments.
' Argument 0 = The Relevance ID number (relID).  This matches the fixlet to the item being updated.
' Argument 1 = Pre or Post.  If "Pre" then update nodes < the current node.  If "Post" then update nodes <= the current node.

Set objArgs = Wscript.Arguments
Set xmlDoc = CreateObject("Microsoft.XMLDOM")  
Set objFSO=CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

ProgramFilesx86 = objShell.ExpandEnvironmentStrings("%PROGRAMFILES(x86)%")
scrPath = Wscript.ScriptFullName
Set objFile = objFSO.GetFile(scrPath)
scrFolder = objFSO.GetParentFolderName(objFile)

xmlDoc.Async = "False"
xmlDoc.Load(scrFolder & "\status.xml")

dim xmlPath

'Search status.xml for the relevance ID matching the first argument.
xmlPathStatusID = "/root/results/statusItem/relevance[@relID=" & objArgs(0) & "]/.."
set relNode = xmlDoc.selectSingleNode(xmlPathStatusID)
attribute = relNode.getAttribute("ID")

'Set the array
'We include the current node depending on the argument to the script.
dim arrayInteger()
intCompare = StrComp(objArgs(1), "Pre", vbTextCompare)
If intCompare = 0 Then
    attribute=attribute-2
Else
    attribute=attribute-1
End If
Redim arrayInteger(attribute)
for i = 0 to UBound(arrayInteger)
	arrayInteger(i) = i+1
Next

'For each node, pass the relevance to a file, use qna.exe to evaluate it, then update status.xml with the output.
'The relevance in status.xml should produce a "pass" or "fail" result.
For each p in arrayInteger
	xmlPathRel = "/root/results/statusItem[@ID=" & p & "]/relevance"
	set relNode = xmlDoc.selectSingleNode(xmlPathRel)
	infile=".\rel.txt"
	set objRelFile = objFSO.CreateTextFile(infile,True)
	objRelFile.Write "q: " & relNode.Text
	objRelFile.Close()
	command = """" & ProgramFilesx86 & "\BigFix Enterprise\BES Client\qna.exe"" " & chr(34) & infile & chr(34) 
	Set objWshScriptExec = objShell.Exec(command)
	Set objStdOut = objWshScriptExec.StdOut
	While Not objStdOut.AtEndOfStream
		strLine = objStdOut.ReadLine
		If InStr(strLine,"A: ") Then
			strLine = Replace(strLine,"A: ","")
			xmlPathSuccess = "/root/results/statusItem[@ID=" & p & "]/status"
			set successNode = xmlDoc.selectSingleNode(xmlPathSuccess)
			successNode.Text = strLine  
		End If
	Wend
	
	objFSO.DeleteFile infile,true
Next
  
' Save the changes
xmlDoc.Save scrFolder & "\status.xml"  
