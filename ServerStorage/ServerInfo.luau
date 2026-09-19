local ServerInfo = {}

ServerInfo.ServerId = game.JobId
ServerInfo.BossCount = 0
ServerInfo.PlayerCount = 0
ServerInfo.ServerTotalDamage = 0 -- add up everyone damage
ServerInfo.ServerStartTime = os.time()


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.PlayerAdded:Connect(function(plr)
	ServerInfo.PlayerCount += 1
	task.wait(30) -- wait 30sec for things to be loaded
	ServerInfo.ServerTotalDamage += plr.Utils.Damage.Value
	print({Count = ServerInfo.PlayerCount,StartTime = ServerInfo.ServerStartTime,TotalDamage = ServerInfo.ServerTotalDamage})
end)




-- just Information for admins 







return ServerInfo