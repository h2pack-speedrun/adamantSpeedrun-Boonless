package.path = "./?.lua;./?/init.lua;" .. package.path

dofile("tests/test_ui.lua")
dofile("tests/test_behaviors.lua")

print("Boonless tests passed")
