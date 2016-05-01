-- Reset the UI
fn ui_reset = (
    try (destroydialog nr_rollout) catch()
)

-- Import rollout
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
	groupBox grp_vert "Vertex Structure" pos:[10, 130] width:220 height:160 columns:2

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
	groupBox grp_uv "UV Structure" pos:[240,130] width:230 height:160 columns:2

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

-- TODO: Guess mesh prefix feature
--	label label_guess_prefix "Prefix object names with guessed type" pos:[50,500] width:220 height:15 enabled:true
--	checkbox input_guess_prefix pos:[20,500] checked:false

-- TODO: Distribute imported meshes
--	label label_distribute "distribute imported meshes across the grid" pos:[50,520] width:220 height:15 enabled:true
--	checkbox input_distribute pos:[20,520] checked:false

	--Enable debug mode? (VERY SLOW)
    label lbldbgmde "Debug Level" pos:[10,610] width:77 height:30
    spinner inputDebugLevel "" pos:[80,610] width:45 height:16 range:[0,2,g_debugMode] type:#integer scale:1 enabled:true

	-- Import button
	button BtnImport "IMPORT" pos:[360,580] width:109 height:52

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
								t1 = 0
								t2 = (r1 - r0) + 1

								-- try/catch to fix rendering on fail
								try (
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
									util_redrawEnable();
								) catch (
									util_redrawEnable();
									messageBox("An error occurred.")
								)

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
