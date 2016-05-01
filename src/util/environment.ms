
-- Enable redraw, and redraw the screen.
fn util_redrawEnable = (
    enableSceneRedraw()
    completeRedraw()
    gw.updateScreen()
)

-- Disable redraw. Speeds up heavy mesh activities.
fn util_redrawDisable = (
    disableSceneRedraw()
)

-- Modify CPU and Memory alloc
fn util_fixEnvironment = (

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
)
