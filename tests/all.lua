package.path = "./?.lua;./?/init.lua;" .. package.path

dofile("tests/test_ui.lua")

print("Boonless tests passed")
