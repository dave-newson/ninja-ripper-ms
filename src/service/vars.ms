
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