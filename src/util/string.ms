
fn isNumSeqNR str = (
    (trimLeft str ".0123456789").count == 0
)

fn StringClear OrigStr =
(
	local Str = ""

	for j = 1 to OrigStr.count do (
		if OrigStr[ j ] != " " then(
			Str = Str + OrigStr[ j ]
		)
	)
   Str
)

fn CreateMeshName Num =
(
	local Str = "Mesh_"
	local StrNum = ""
	r0 = Num as Integer
	StrNum = formattedPrint r0 format:"#04u"

	Str = Str + StrNum as String
	Str = Str + ".rip"

	Str
)