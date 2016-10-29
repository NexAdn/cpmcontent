-- Copyright (C) 2016 Adrian Schollmeyer

-- INFO: Licenses can be found in the COPYING-Folder.
--
-- cpm.lua is part of CPM.
--
--  CPM is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License and the GNU General Public License for more details.
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- User specific configuration
local tConfig = {
	-- Server URL to connect to
	sPackageServer = "https://raw.githubusercontent.com",
	-- Path to main repository directory
	sPackageDirectory = "/nexadn/cpmcontent/master"
}

-- Static configuration (DO NOT CHANGE)
local tStatic = {
    sVersion = "0.3",
    
    sPackagesFile       = "/packages",
    sDependenciesFile   = "/dependencies",
    sVersionFile        = "/version",
    sMainLua            = "/main.lua"
}

local tMsg = {
    usageMessage = "Syntax: cpm install [package]\n        cpm update\n        cpm cpmupdate",
    wrongURL = "Wrong URL",
    generalError = "Unkown error occured!",
    updateSuccess = "Successfully updated CPM",
    installPackage = "Unpacking ",
    installedPackage = "Unpacked ",
    done = "Done",
    packageNotFound = "Couldn't find package",
    packageUptodate = "Package already up-to-date",
    readPackageLists = "Reading package lists...",
    updatePkgList = "Updating package lists...",
    writePkgData = "Writing package data..."
}

local tData = {
    aPackageList = {},
    aVersionList = {},
    installed = {
        package = {},
        version = {}
    }
}

local tArgs = { ... }

function checkInitial()
    if fs.isDir(".cpm.d") and fs.isDir(".cpm.d/install.d/") then
        readPackageLists()
        return 0
    else
        initConfDir()
        --checkInitial()
        readPackageLists()
        return 0
    end
end

-- Initialize .cpm.d --
function initConfDir()
    fs.makeDir(".cpm.d/")
    fs.makeDir(".cpm.d/install.d/")
end

function readPackageLists()
    print(tMsg.readPackageLists)
    
    if fs.exists(".cpm.d/plist") == false or fs.exists(".cpm.d/pvlist") == false then
        cpmUpdate()
    end
    
    local plist = fs.open(".cpm.d/plist", "r")
    local pvlist = fs.open(".cpm.d/pvlist", "r")
    
    local buf = nil
    local it = 1
    
    while true do
        buf = plist.readLine()
        
        if buf == nil then
            break
        end
        
        tData.aPackageList[it] = buf
        tData.aVersionList[it] = pvlist.readLine()
        
        it = it + 1
    end
    
    plist.close()
    pvlist.close()
    
    buf = nil
    local file = nil
    it = 1
    
    local ls = fs.list(".cpm.d/install.d/")
    
    for k,v in pairs(ls) do
        if v == nil then
            break
        end
        
        file = fs.open(".cpm.d/install.d/"..v, "r")
        buf = file.readLine()
        file.close()
        
        tData.installed.package[k] = v
        tData.installed.version[k] = buf
    end
    
    print(tMsg.done)
end

function findInstalledPackage(sPackage)
    for k,v in pairs(tData.installed.package) do
        if v == sPackage then
            if tData.installed.version[k] ~= nil then
                return tData.installed.version[k]
            end
        end
    end
    return nil
end

function findListedPackage(sPackage)
    for k,v in pairs(tData.aPackageList) do
        if v == sPackage then
            if tData.aVersionList[k] ~= nil then
                return tData.aVersionList[k]
            end
        end
    end
    return nil
end

function fetchArgs()
    checkInitial()
    
    if tArgs[1] == "update" then
           cpmUpdate()
    elseif tArgs[1] == "install" then
        if #tArgs < 2 then
            print(tMsg.usageMessage)
        end
        local res = cpmInstall(tArgs[2])
        if res == -1 then
            print(tMsg.generalError) 
        else
            print(tMsg.done)
        end
    elseif tArgs[1] == "upgrade" then
        cpmUpgrade()
    elseif tArgs[1] == "cpmupdate" then
        local res = downloadFile("https://raw.githubusercontent.com/NexAdn/cpm/master/cpm.lua")
        if res == nil then
            print(tMsg.generalError)
        else
            local buf = nil
            local file = fs.open("cpm", "w")
            while true do
                buf = res.readLine()
                if buf == nil then
                    break
                end
                file.writeLine(buf)
            end
            file.close()
            print(tMsg.updateSuccess)
        end
    else
        print(tMsg.usageMessage)
    end
end

function checkURL(sURL)
    if http.checkURL(sURL) == false then
        print(tMsg.wrongURL)
        return false
    end
    return true
end

function cpmUpdate()
    local sListURL = tConfig.sPackageServer .. tConfig.sPackageDirectory .. tStatic.sPackagesFile
    print(tMsg.updatePkgList)
    if checkURL(sListURL) then
        local tResPkglist = http.get(sListURL)
        if tResPkglist.getResponseCode() == 200 then
            local tFileList = {}
            local buf = nil
            local i = 0
            local cont = true
            while cont do
                i = i + 1
                buf = tResPkglist.readLine()
                if buf == nil then
                    cont = false
                else
                    tFileList[i] = buf
                    --print(tFileList[i])
                end
            end
            
            local tVersionList = {}
            for k,v in pairs(tFileList) do
                local res = http.get(tConfig.sPackageServer .. tConfig.sPackageDirectory .. "/" .. v ..  tStatic.sVersionFile)
                --print(tConfig.sPackageServer .. tConfig.sPackageDirectory .. "/" .. v  ..  tStatic.sVersionFile)
                if res.getResponseCode() ~= 200 then
                    print(tMsg.generalError)
                    return nil,nil
                end
                tVersionList[k] = res.readLine()
                --print(tVersionList[k])
            end
            
            local plist = fs.open(".cpm.d/plist", "w")
            local pvlist = fs.open(".cpm.d/pvlist", "w")

            local it = 1
            
            print(tMsg.writePkgData)
            while true do
                if tFileList[it] ~= nil then
                    --print(tFileList[it])
                    plist.writeLine(tFileList[it])
                    pvlist.writeLine(tVersionList[it])
                    
                    print("OK " .. tFileList[it] .. " " .. tVersionList[it])
                    
                    it = it + 1
                else
                    break
                end
            end
            plist.close()
            pvlist.close()
            readPackageLists()
        else
            print(tMsg.generalError)
        end
    else
        print(tMsg.wrongURL)
    end
end

function cpmUpgrade()
    return 0
end

function cpmInstall(sPackage)
    
    local version = findInstalledPackage(sPackage)
    local pVersion = findListedPackage(sPackage)
    
    if pVersion == nil then
        print(tMsg.packageNotFound)
        return 0
    end
    
    if version ~= nil and version == pVersion then
        print(sPackage .. " - " .. tMsg.packageUptodate)
        return 0
    end
    
    -- Recursive dependency installation
    print(sPackage .. "/dependencies\n")
    
    loadDependencies(sPackage)
    
    print(sPackage .. "/main\n") 
    
    local res = downloadFile(tConfig.sPackageServer .. tConfig.sPackageDirectory .. "/" .. sPackage .. tStatic.sMainLua)
    
    if res == nil then
        print(tMsg.generalError)
        return -1
    end
    
    local file = fs.open(sPackage, "w")
    
    local buf = nil
    
    print(tMsg.installPackage .. sPackage .. "...")
    
    while true do
        buf = res.readLine()
        if buf ~= nil then
            file.writeLine(buf)
        else
            break
        end
    end
    
    file.close()
    
    print(tMsg.installedPackage .. sPackage)
    
    local pkgfile = fs.open(".cpm.d/install.d/" .. sPackage, "w")
    
    pkgfile.writeLine(pVersion)
    pkgfile.close()
    
    return 1
end

function downloadFile(sURL)
    if checkURL(sURL) then
        local res = http.get(sURL)
        
        --print(res.getResponseCode())
        
        if res.getResponseCode() ~= 200 and res.getResponseCode() ~= 304 then
            return nil
        end
        
        return res
    else
        return nil
    end
end

function loadDependencies(sPackage)
    local res = downloadFile( tConfig.sPackageServer .. tConfig.sPackageDirectory .. "/" .. sPackage .. tStatic.sDependenciesFile )
    
    local buf = nil
    
    while true do
        buf = res.readLine()
        
        if buf == nil or buf == "NULL" then
            break
        end
        
        cpmInstall(buf)
    end
end

function main()
    textutils.slowPrint("CPM v" .. tStatic.sVersion .. "\n")
    --[[for k,v in pairs(tArgs) do
        print(k .. " " ..v)
    end]]
    fetchArgs()
end

main()
