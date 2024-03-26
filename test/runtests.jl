using GlobalBrain
using Test


for testfile in readdir(".")
	if endswith(testfile, ".jl") && testfile != "runtests.jl"
		include(testfile)
	end
end

