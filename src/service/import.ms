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

			-- IDX from a UV map?
			for i = 1 to UV_Idx_array.count do (

				if (j == UV_Idx_array[i][1]) then (
					texUv[i][1] = z as Float;
				)
				if (j == UV_Idx_array[i][2]) then (
					texUv[i][2] = z as Float * g_flipUV;
					if (g_flipUV == -1) then (
						texUv[i][2] = texUv[i][2] + 1; -- move up to the top right Quadrant
					)
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
	i = 1;
	while (UV_array[i] != undefined) do (
		-- Discard UVs without verts
		if (UV_array[i].count < 1) then (
			deleteItem UV_array i
			i -= 1
		)
		i+=1
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


