/* 
Ninja Ripper 1.1.2b7a2 3D Max Importer
Importer version 1.3 beta7 alpha2

Changes:

2016.04.25 (1.3 beta7 alpha2) by Dave Newson


2013.03.03 (1.3 beta7 alpha1) by CarLuver69
- You can now flip on the XZ axis if your models appear inverted!
- Added progress bar
- Removed a lot of unnecessary information being printed
- End of script will show a popup message with how long it took to import
- "Debug" mode allows you to turn on useless print messages, VERY SLOW.
- Program no longer hangs when importing many objects :D
- Imports are now 50 - 75% faster. I was able to import 2,001 objects in 1 minute and 30 seconds!


2013.01.09 (1.3 beta7):
- added uv Scale function
- improved model Scale function
 */

try (destroydialog nr_rollout) catch()

-- allow ~ 40 MB instead of just 7.5 MB. Prevents "Runtime Error: Out of scripter memory"
if (heapSize < 200000) then
	heapSize = 2000000
		
-- force useing one CPU core
if SysInfo.CPUCount == 1 then
     TargetAffinity = 1
    else (
     TargetAffinity = 0
     for CoreID = 2 to SysInfo.CPUCount do
      TargetAffinity = (Bit.Set TargetAffinity CoreID true)
    )
    SysInfo.ProcessAffinity = TargetAffinity

-- Enable redraw at start. Helps with crash recovery
enableSceneRedraw()

---Constants
global RipSignature   = 0xDEADC0DE
global RipFileVersion = 4


---Global vars
global g_ImportType = 1       --- Group/Single/List  (0,1,2)
global g_InputSrc   = ""      --- Source Dir/File
global g_VertexFormatRecog = 0 --- Auto/Manual  (0,1)

global g_PosX_Idx = 0
global g_PosY_Idx = 0
global g_PosZ_Idx = 0
global g_NormX_Idx = 0
global g_NormY_Idx = 0
global g_NormZ_Idx = 0
global g_Tc0_U_Idx = 0
global g_Tc0_V_Idx = 0
global g_Tc1_U_Idx = 0
global g_Tc1_V_Idx = 0

--Globals additional
global g_ninjaScale = 100
global g_ninjarotX = 90
global g_ninjarotY = 0
global g_ninjarotZ = 0
global g_flipUV = 1
global g_flipXZAxis = 0
global g_uvScale = 100

global g_coll_prefix = "col_"
global g_skip_dupe = false

--Debug mode
global g_debugMode = 0

-- fn NinjaRotationMatrix =
-- (
-- 	local angles = eulerAngles 0 -0 -90
-- 	--local angles = eulerAngles g_ninjarotZ -g_ninjarotY -g_ninjarotX
-- 	return angles as matrix3
-- )

fn isNumSeqNR str = ((trimLeft str ".0123456789").count == 0)

fn ReadStr bstream =
(
   local str = ""
   while true do
   (
      str0 = ReadByte bstream #unsigned
	  if str0 == 0 then exit
      str+= bit.intAsChar str0
   )
   str
)


fn  StringClear OrigStr =
(
	local Str = ""

	for j = 1 to OrigStr.count do (
		if OrigStr[ j ] != " " then(
			Str = Str + OrigStr[ j ]
		)
	)
   Str
)


fn  CreateMeshName Num =
(
	local Str = "Mesh_"
	local StrNum = ""
	r0 = Num as Integer
	StrNum = formattedPrint r0 format:"#04u"

	Str = Str + StrNum as String
	Str = Str + ".rip"

	Str
)

fn printLevel str level = (
	if level <= g_debugMode do (
		print ((str) as string);
	)
)

fn printDebug str = (
	printLevel str 1;
)

----------------------------
fn ImportRip RipFilePath =
(
	f = fopen RipFilePath "rb"
	printDebug ( "*****ImportRip() File: " + RipFilePath as String )

	Signature     = readlong f #unsigned
	Version       = readlong f #unsigned

	if Version != RipFileVersion do(
		printDebug "Not RIP file"
		printLevel ("FileSig: " + Version as String) 2
		printLevel ("Sig : " + RipFileVersion as String) 2
		return 0
	)

	dwFacesCnt    = readlong f #unsigned
	dwVertexesCnt = readlong f #unsigned
	VertexSize    = readlong f #unsigned
	TextureFilesCnt= readlong f #unsigned
	ShaderFilesCnt= readlong f #unsigned
	VertexAttributesCnt= readlong f #unsigned

	printDebug ( "dwFacesCnt=" + dwFacesCnt as String )
	printDebug ( "dwVertexesCnt=" + dwVertexesCnt as String )
	printDebug ( "VertexAttributesCnt=" + VertexAttributesCnt as String )

	VertexAttribTypesArray= #()   ---Contain all types
	TextureFiles = #()
	ShaderFiles  = #()

	Face_array = #()
	Normal_array = #()
	Vert_array = #()
	UV_array = #()
	UV_Idx_array = #()

	TempPosIdx = 0      ---Get only first index attribute flag
	TempNormalIdx = 0
	TempTexCoordIdx = 0

	---Read vertex attributes
	for i = 1 to VertexAttributesCnt do (
		Semantic = ReadStr f
		SemanticIndex = readlong f #unsigned
		Offset = readlong f #unsigned
		Size   = readlong f #unsigned
		TypeMapElements = readlong f #unsigned
		for j = 1 to TypeMapElements do (
			TypeElement = readlong f #unsigned
			append VertexAttribTypesArray TypeElement
		)
		printDebug "------------"
		printDebug( "Semantic="+ Semantic )
		printDebug( "SemanticIndex=" + SemanticIndex as String )
		printDebug( "Offset=" + Offset as String )
		printDebug( "Size=" + Size as String )
		printDebug( "TypeMapElements=" + TypeMapElements as String )

		---Recognize semantic if "AUTO" set
		if (g_VertexFormatRecog == 0) then ( ---AUTO recognition
			if Semantic == "POSITION" do (  --- Get as "XYZ_"
				if TempPosIdx == 0 do (
					g_PosX_Idx = Offset / 4
					g_PosY_Idx = g_PosX_Idx + 1
					g_PosZ_Idx = g_PosX_Idx + 2

					TempPosIdx = TempPosIdx + 1
				)
			)

			if Semantic == "NORMAL" do (
				if TempNormalIdx == 0 do (
					g_NormX_Idx = Offset / 4
					g_NormY_Idx = g_NormX_Idx + 1
					g_NormZ_Idx = g_NormX_Idx + 2

					TempNormalIdx = TempNormalIdx + 1
				)
			)

			if Semantic == "TEXCOORD" do (
				tc_u_idx = Offset / 4;
				tc_v_idx = tc_u_idx + 1;
				append UV_Idx_array [tc_u_idx,tc_v_idx];
			)
		) else (
			-- Append UV Coordinates from manual
			append UV_Idx_array [g_Tc0_U_Idx,g_Tc0_V_Idx];
			append UV_Idx_array [g_Tc1_U_Idx,g_Tc1_V_Idx];
		)
	)

	printDebug "-----------------------------"

	-- Set up UV Array
	for i = 1 to UV_Idx_array.count do (
		UV_array[i] = #();
	)

	---Read texture files list to array ( if present )
	for i = 1 to TextureFilesCnt do (
		TexFile = ReadStr f
		append TextureFiles ( TexFile as String )
	)
	---Read shader files list to array ( if present )
	for i = 1 to ShaderFilesCnt do (
		ShaderFile = ReadStr f
		append ShaderFiles ( ShaderFile as String )
	)

	printDebug ( "Texture Files:" )
	for i = 1 to TextureFiles.count do (
		printDebug ( TextureFiles[ i ] as String )
	)
	printDebug ( "------------" )


	---Read indexes
	for x = 1 to dwFacesCnt do(
		i0 = readlong f #unsigned
		i1 = readlong f #unsigned
		i2 = readlong f #unsigned
		if g_flipXZAxis == 1 then (
			append Face_array[i2+1,i1+1,i0+1]
		) else (
			append Face_array[i0+1,i1+1,i2+1]
		)

    	printLevel ("idx0: " + i0 as String + " idx1: " + i1 as String + " idx2: " + i2 as String) 3
	)


	printDebug( "PosX idx: " + g_PosX_Idx as String )
	printDebug( "PosY idx: " + g_PosY_Idx as String )
	printDebug( "PosZ idx: " + g_PosZ_Idx as String )
	printDebug( "NormX idx: " + g_NormX_Idx as String )
	printDebug( "NormY idx: " + g_NormY_Idx as String )
	printDebug( "NormZ idx: " + g_NormZ_Idx as String )

	for i = 1 to UV_Idx_array.count do (
		printDebug( "Tex UV " + i as String )
		printDebug( "U idx: " + UV_Idx_array[i][1] as String )
		printDebug( "V idx: " + UV_Idx_array[i][2] as String )
	)


	---Read vertexes
	for k = 1 to dwVertexesCnt do(

	printLevel ("VertexIdx : " + (k-1) as String) 3

		vx = 0.0
		vy = 0.0
		vz = 0.0
		vw = 0.0
		nx = 0.0
		ny = 0.0
		nz = 0.0
		nw = 0.0

		texUv = #()
		for i = 1 to UV_Idx_array.count do (
			texUv[i] = #();
		)

		for j = 0 to VertexAttribTypesArray.count - 1 do(

			printLevel ("VertAttr Idx: " + j as String) 3
			ElementType = VertexAttribTypesArray[ j + 1 ]
			if ElementType == 0 then (  --- EFLOAT
				z = readfloat f
			)
			else if ElementType == 1 then (  ---EUINT
				z = readlong f #unsigned
			)
			else if ElementType == 2 then (  ---ESINT
				z = readlong f #signed
			)
			else (
				z = readlong f #unsigned
			)

			if j == g_PosX_Idx do vx = z
			if j == g_PosY_Idx do vy = z
			if j == g_PosZ_Idx do vz = z

			if j == g_NormX_Idx do nx = z
			if j == g_NormY_Idx do ny = z
			if j == g_NormZ_Idx do nz = z

			-- is the IDX one of the UV maps?
			for i = 1 to UV_Idx_array.count do (

				if (j == UV_Idx_array[i][1]) then (
					texUv[i][1] = z as Float;
				)
				if (j == UV_Idx_array[i][2]) then (
					texUv[i][2] = z as Float * g_flipUV;
				)
			)

			vx = vx as Float
			vy = vy as Float
			vz = vz as Float

			nx = nx as Float
			ny = ny as Float
			nz = nz as Float
		)

		-- Verts and Normals
		append Vert_array[(vx * g_ninjaScale),(vy * g_ninjaScale),(vz * g_ninjaScale)]
		append Normal_array [nz,ny,nx]

		-- UV Maps
		for i = 1 to texUv.count do (
			-- Skip texUv with no values. Yes this happens.
			if (texUv[i][1] == undefined or texUv[i][2] == undefined) then (continue;)

			append UV_array[i] [texUv[i][1],texUv[i][2],0];
		)

		printLevel ("vx: " + vx as String + " vy: " + vy as String + " vz: " + vz as String) 3
		printLevel ("UV Map Count: " + UV_Idx_array.count as String) 2
	)

	-- Tidy UV Collection, remove empties from bad UV channels as they cause errors for Max.
	for i = 1 to UV_array.count do (
		if (UV_array[i] == undefined) then (continue;)
		if (UV_array[i].count < 1) then (
			deleteItem UV_array i;
			i--;
		)
	)

	---Multi/sub Material
 	thenewmaterial = multimaterial numsubs:TextureFiles.count

	-- Map each texture file to a submap
	for i=1 to TextureFiles.count do (

		-- Get the filename. use "notexture.dds" if things go wrong
		if (TextureFiles[i] == undefined)
		then ( TexFile = "notexture.dds" )
		else ( TexFile = TextureFiles[i] )

		TexFileName = getFilenamePath RipFilePath
		TexFileName = TexFileName + TexFile

		printLevel ("Mat.SubTextureFile: " + TexFile) 2

		thenewsubmaterial = standardmaterial name:TexFile
		thenewsubmaterial.diffusemap = bitmaptexture name:TexFile
		thenewsubmaterial.diffusemap.filename = TexFileName
		thenewsubmaterial.diffusemap.coords.MapChannel = i
		thenewmaterial.materiallist[i] = thenewsubmaterial
		showtexturemap thenewsubmaterial thenewsubmaterial.diffusemap true
	)

	-- Create Mesh
	msh = mesh vertices:Vert_array faces:Face_array

	-- Set the number of UV Maps
	numMaps = UV_array.count + 1;
	printLevel ("UV Map Count: " + numMaps as String) 1
	meshop.setNumMaps msh numMaps keep:false

	for i = 1 to UV_array.count do (

		-- Set the number of Map Vers to expect
		meshop.setNumMapVerts msh i UV_array[i].count
		printLevel ("UV Map [" + i as String + "] vert count: " + UV_array[i].count as String) 1

		-- set positions of the UV map verts
		for j = 1 to UV_array[i].count do (
			meshop.setMapVert msh i j UV_array[i][j]
		)
		-- Rebuild the map on the mesh
		meshop.buildMapFaces msh i keep:false

		-- Apply the UV map to the Faces
		for f = 1 to Face_array.count do (
			meshop.setMapFace msh i f Face_array[f];
		)
	)

	--for i = 1 to Normal_array.count do (setNormal msh j Normal_array[j])

	-- Apply mesh rotation
	currentMatrix = msh.transform
	preRotate currentMatrix (eulertoquat (eulerAngles g_ninjarotX g_ninjarotY g_ninjarotZ))
	msh.transform = currentMatrix
	resetxform msh
	maxOps.CollapseNode msh off

	msh.name = getFilenameFile RipFilePath
	msh.material = thenewmaterial

	--Redraw screen
	-- windows.processPostedMessages() -- This prevents 3DS Max from hanging!
	--completeredraw()
	--gw.updateScreen()
)


rollout nr_rollout "Ninja Ripper Importer v1.3 beta7 alpha2" width:480 height:640
(
	-- Source select
	groupBox grp1 "Source Select" pos:[10,10] width:460 height:113
	radioButtons RadioImport "" pos:[20,35] width:300 height:16 labels:#("Group", "Single", "List File") default:2 columns:3

	label lblInputFile "Input .rip File" pos:[20,60] width:68 height:17 visible:true
	label lblInputDir "Input Dir" pos:[20,60] width:68 height:17 visible:false
	label lblInputLst "Input .lst File:" pos:[20,60] width:68 height:17 visible:false
	editText InputSrc "" pos:[90,56] width:330 height:20
	button SelectSrc "..." pos:[430,56] width:25 height:19 toolTip:""

	label lbl10 "RIP File Nums" pos:[20,85] width:69 height:18 enabled:false
	editText RipList "" pos:[90,82] width:365 height:20 enabled:false

	-- Vertex Format
	groupBox grp_vert "Vertex Layout" pos:[10, 130] width:220 height:160 columns:2

	--imgTag theImgTag "Bitmap" pos:[5,150] width:168 height:20 bitmap:(bitmap 80 50 color:gray) align:#right

	radioButtons RadioVertexFormat "" pos:[20,150] width:48 height:32 enabled:true labels:#("Auto", "Manual") default:1 columns:2

	label lbl_pos "Position" pos:[24,170] width:41 height:14 enabled:false
	spinner pos_x "x" pos:[21,195] width:38 height:20 type:#integer enabled:false
	spinner pos_y "y" pos:[21,225] width:38 height:20 type:#integer enabled:false
	spinner pos_z "z" pos:[21,256] width:38 height:20 type:#integer enabled:false

	label lbl_norm "Normal" pos:[78,170] width:37 height:14 enabled:false
	spinner norm_x "x" pos:[73,195] width:38 height:20 type:#integer enabled:false
	spinner norm_y "y" pos:[73,225] width:38 height:20 type:#integer enabled:false
	spinner norm_z "z" pos:[73,256] width:38 height:20 type:#integer enabled:false

	-- UV Format
	groupBox grp_uv "UV Layout" pos:[240,130] width:220 height:160 columns:2

	label lbl_tc0 "UV1" pos:[280,170] width:48 height:14 enabled:false
	spinner tc0_u "u" pos:[280,195] width:38 height:16 range:[0,500,0] type:#integer enabled:false
	spinner tc0_v "v" pos:[280,225] width:38 height:16 range:[0,500,0] type:#integer enabled:false

	label lbl_tc1 "UV2" pos:[340,170] width:48 height:14 enabled:false
	spinner tc1_u "u" pos:[340,195] width:38 height:16 range:[0,500,0] type:#integer enabled:false
	spinner tc1_v "v" pos:[340,225] width:38 height:16 range:[0,500,0] type:#integer enabled:false

	--Mesh Transform
	groupBox grp4 "Mesh Transformations" pos:[10,300] width:220 height:160

	label lblscale "Scale" pos:[20,320] width:77 height:15 enabled:true
	spinner spnscale "" pos:[120,320] width:45 height:16 range:[1,10000,g_ninjaScale] type:#integer scale:1 enabled:true

	label lblrotateX "Rotate X" pos:[20,350] width:77 height:15 enabled:true
	spinner spnrotateX "" pos:[120,350] width:45 height:16 range:[0,360,g_ninjarotX] type:#float scale:90 type:#integer enabled:true

	label lblrotateY "Rotate Y" pos:[20,380] width:77 height:15 enabled:true
	spinner spnrotateY "" pos:[120,380] width:45 height:16 range:[0,360,g_ninjarotY] type:#float scale:90 type:#integer enabled:true

	label lblrotateZ "Rotate Z" pos:[20,410] width:77 height:15 enabled:true
	spinner spnrotateZ "" pos:[120,410] width:45 height:16 range:[0,360,g_ninjarotZ] type:#float scale:90 type:#integer enabled:true

	--UV Transform
	groupBox grp5 "UV Transformations" pos:[240,300] width:230 height:160

	label uvscale "UV Scale" pos:[250,340] width:77 height:15 enabled:true
	spinner etuvscale "" pos:[360,340] width:45 height:16 range:[1,10000,g_uvScale] type:#integer scale:1 enabled:true

	label lblflipuv "Flip UV Vertical" pos:[250,360] width:70 height:15
 	checkbox checkerUV pos:[360,360] checked:false

    label lblflipXZ "Flip UV XZ Axis" pos:[250,380] width:77 height:15 enabled:true
    checkbox checkerXZAxis pos:[360,380] checked:false

	--Misc
	groupBox grp_misc "Misc" pos:[10,470] width:460 height:100

	label label_coll_prefix "Name prefix for mesh without UV" pos:[20,490] width:200 height:15 enabled:true
	editText input_coll_prefix "" pos:[190,487] width:100 height:20 enabled:false

	label label_skip_dupe "Skip duplicate meshes" pos:[50,520] width:130 height:15 enabled:true
	checkbox input_skip_dupe pos:[20,520] checked:false

	--Enable debug mode? (VERY SLOW)
    label lbldbgmde "Debug Level" pos:[10,610] width:77 height:30
    spinner inputDebugLevel "" pos:[80,610] width:45 height:16 range:[0,2,g_debugMode] type:#integer scale:1 enabled:true

	-- Import button
	button BtnImport "IMPORT" pos:[350,580] width:109 height:52

	on spnscale changed val do g_ninjaScale = val
	on spnrotateX changed val do g_ninjarotX = val
	on spnrotateY changed val do g_ninjarotY = val
	on spnrotateZ changed val do g_ninjarotZ = val

	--on nr_rollout open do etuvscale.text = "1"
	on nr_rollout open  do (

		---Init values
		pos_x.value = 0
		pos_y.value = 1
		pos_z.value = 2

		norm_x.value = 3
		norm_y.value = 4
		norm_z.value = 5

		tc0_u.value  = 6
		tc0_v.value  = 7

		tc1_u.value  = 8
		tc1_v.value  = 9
	)

	--debug mode
	on inputDebugLevel changed val do (
		if g_debugMode == 0 and val != 0 do (
			messageBox "WARNING: Debug mode will now be enabled!\n\nDebug mode prints data to the MaxScript Listener.\nThis can increase import times by up to 75%!"
		)
        g_debugMode = val
	)

	on checkerUV changed UVstate do (
		if checkerUV.checked == false do (
			g_flipUV  = 1
		)

		if checkerUV.checked == true then (
			g_flipUV  = -1
		)
	)

	on checkerXZAxis changed XZAxistate do (
		if checkerXZAxis.checked == false do (
			g_flipXZAxis = 0
		)

		if checkerXZAxis.checked == true then (
			g_flipXZAxis = 1
		)
	)

	on RadioVertexFormat changed state do
	(
		lbl_pos.enabled = not lbl_pos.enabled
		lbl_norm.enabled = not lbl_norm.enabled
		pos_x.enabled = not pos_x.enabled
		pos_y.enabled = not pos_y.enabled
		pos_z.enabled = not pos_z.enabled

		norm_x.enabled = not norm_x.enabled
		norm_y.enabled = not norm_y.enabled
		norm_z.enabled = not norm_z.enabled

		lbl_tc0.enabled = not lbl_tc0.enabled
		tc0_u.enabled = not tc0_u.enabled
		tc0_v.enabled = not tc0_v.enabled

		lbl_tc1.enabled = not lbl_tc1.enabled
		tc1_u.enabled = not tc1_u.enabled
		tc1_v.enabled = not tc1_v.enabled
	)

	on RadioImport changed state do
	(
		if RadioImport.state == 1 then (
			lbl10.enabled = true
			RipList.enabled = true
			lblInputFile.visible = false
			lblInputDir.visible = true
			lblInputLst.visible = false
			)
		else if RadioImport.state == 2 then (
			lbl10.enabled = false
			RipList.enabled = false
			lblInputFile.visible = true
			lblInputDir.visible = false
			lblInputLst.visible = false
			)
		else if RadioImport.state == 3 then (
			lbl10.enabled = false
			RipList.enabled = false
			lblInputFile.visible = false
			lblInputDir.visible = false
			lblInputLst.visible = true
			)
	)

	on SelectSrc pressed  do (
		if RadioImport.state == 1 then (	---Group
			g_InputSrc   = getSavePath caption:"Choose directory with .rip files" initialDir:"$scripts"
			if g_InputSrc != undefined do (
				g_InputSrc = g_InputSrc + "\\"
				g_ImportType  = 0
				InputSrc.text = g_InputSrc
				printDebug ( "Dir selected: " + g_InputSrc )
			)
		)
		else if RadioImport.state == 2 then (   ---Single
			g_InputSrc = getOpenFileName \
							caption:"Ninja Ripper File Select" \
							types:"Ninja Ripper File(*.rip)|*.rip" \
							historyCategory:"Ninja Ripper"
			if g_InputSrc != undefined do (
				g_ImportType = 1
				InputSrc.text = g_InputSrc
				printDebug ( "Single File selected: " + g_InputSrc )
			)
		)
		else if RadioImport.state == 3 then ( ---List file
			g_InputSrc = getOpenFileName \
							caption:"Ninja Ripper List File Select" \
							types:"Ninja Ripper List File(*.lst)|*.lst" \
							historyCategory:"Ninja Ripper"
			if g_InputSrc != undefined do(
				g_ImportType = 2
				InputSrc.text = g_InputSrc
				printDebug ( "List File selected: " + g_InputSrc )
			)
		)
	)

	--Import button
	on BtnImport pressed  do (

		if RadioVertexFormat.state == 1 then ( ---Auto
			printDebug "***Auto***"
			g_VertexFormatRecog = 0
			---Set default values
			g_PosX_Idx = 0
			g_PosY_Idx = 1
			g_PosZ_Idx = 2

			g_ninjarotX = spnrotateX.value
			g_ninjarotY = spnrotateY.value
			g_ninjarotZ = spnrotateZ.value

			meshscale = spnscale.value
		)

		else ( ---Manual
			printDebug "***Manual***"
			g_VertexFormatRecog = 1

			---Position
			g_PosX_Idx = ( pos_x.value as Integer )
			g_PosY_Idx = ( pos_y.value as Integer )
			g_PosZ_Idx = ( pos_z.value as Integer )

			---Normals
			g_NormX_Idx = ( norm_x.value as Integer )
			g_NormY_Idx = ( norm_y.value as Integer )
			g_NormZ_Idx = ( norm_z.value as Integer )

			---Tex coords
			g_Tc0_U_Idx = ( tc0_u.value as Integer )
			g_Tc0_V_Idx = ( tc0_v.value as Integer )
			g_Tc1_U_Idx = ( tc1_u.value as Integer )
            g_Tc1_V_Idx = ( tc1_v.value as Integer )

			g_ninjarotX = spnrotateX.value
			g_ninjarotY = spnrotateY.value
			g_ninjarotZ = spnrotateZ.value

			meshscale = spnscale.value
		)

		---Import part
		if g_ImportType == 1 then ( ---Single file import
			if g_InputSrc.count > 0 then (  ImportRip g_InputSrc )
			else ( messageBox "Please select a .RIP file" )
		)
		else if g_ImportType == 0 then ( ---Group import

			if InputSrc.text.count > 0 then (
				if RipList.text.count > 0 then (
					RipDir = getFilenamePath InputSrc.text
					printLevel ("RipDir: " + RipDir as String) 2

					tokens = filterString RipList.text ","
					FilteredTokens = #()

					---Remove token whitespaces
					for i = 1 to tokens.count do (
						printLevel ("Tokens: " + tokens[i] as String) 2
						local Str = StringClear tokens[i]
						append FilteredTokens ( Str as String )
					)

					---Import loop. Split tokens with "-"
					for i = 1 to FilteredTokens.count do (
						printDebug ( "Filtered Tokens: " + FilteredTokens[i] as String )
						RangeTokens = filterString FilteredTokens[ i ] "-"
						if RangeTokens.count == 1 then (  --Single element
							RipDir1 = RipDir
							ss = CreateMeshName RangeTokens[ 1 ]
							RipDir1 = RipDir1 + ss;
							printDebug ( "Single Import:" + RipDir1 as String )
							ImportRip RipDir1
						)
						else(  ---Range element
							r0 = RangeTokens[1] as Integer
							r1 = RangeTokens[2] as Integer
							if r0 < r1 then (
								t1 = r0
								t2 = r1

								messageBox("Screen redrawing has been disabled to help boost performance.")
								disableSceneRedraw()

								tStart = timestamp()

								doProcess = true
								setProgressCancel = false

								progressBarText = "Importing "+ (t2 as string) +" objects..."
								progressStart (progressBarText as string)

								for j = r0 to r1 while doProcess do(
									if getProgressCancel() == true do (
										doProcess = false
										setProgressCancel = true
									)
									if (getProgressCancel() == false) and (setProgressCancel == false) do (
										RipDir1 = RipDir
										ss = CreateMeshName j
										RipDir1 = RipDir1 + ss;
										printDebug ( "Group Import:" + RipDir1 as String )
										ImportRip RipDir1

										t1 = t1 + 1
										tp = (100.0*t1/t2)
										progressUpdate (tp)
									)
								)
								progressEnd()
								enableSceneRedraw()

								tEnd = timestamp()

								tTimer = ((tEnd-tStart)/1000.0)
								if (tTimer <= 1) do ( tTime = (((tTimer) as string)+" second"))
								if (tTimer >= 2) do ( tTime = (((tTimer) as string)+" seconds"))
								if (tTimer > 60) do ( tTime = ((((tTimer)/60) as string)+" minute"))
								if (tTimer > 120) do ( tTime = ((((tTimer)/60) as string)+" minutes"))

								if (doProcess == true) and (setProgressCancel == false) then (
									messageBox("Successfully imported "+ (t1 as string) +" objects in "+((tTime) as string)+"!")
								) else (
									messageBox("Import interrupted! "+ (t1 as string) +"/"+(t2 as string)+" objects imported.")
								)
								completeRedraw()
								gw.updateScreen()
							)
							else (
								printDebug( "Incorrect range: " + r0 as String + " to " + r1 as String )
							)
						)
					)

				)
				else(
					printDebug "Type file list"
				)
			)
			else (
				printDebug "Select dir"
			)
		)
		else(
			printDebug "Import from list file not realized"
		)
	)
)

createDialog nr_rollout 480 640 50 60