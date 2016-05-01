fn printLevel str level = (
	if level <= g_debugMode do (
		print ((str) as string);
	)
)

fn printDebug str = (
	printLevel str 1;
)