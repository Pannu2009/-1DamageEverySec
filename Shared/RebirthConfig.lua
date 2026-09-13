local module = {}

module.Data = {}
module.MaxRebirth = 20

for i = 1, module.MaxRebirth do
	module.Data[i] = {
		Multi = 2 + ((i - 1) * 0.5),
		WinsReq = math.floor(10 * (i ^ 1.5))
	}
end

return module
