-- [Objects] --

local service = {}

service = {
    install = function(url)
        local manifestContent = http.get(url .. "manifest.lua").readAll

        if not manifestContent then
            printError("Could not connect to the URL website and fetch manifest.")
            return nil
        end

        local tempFolder = fs.makeDir("/tempInstall/")

        local tempManifest = fs.open("/tempInstall/manifest.lua", "w")
        tempManifest.write(manifestContent)
        tempManifest.close()

        local tempManifest = require("/tempInstall/manifest")

        local installationDirectory = tempManifest.directory

        local installed = fs.exists(installationDirectory)

        if installed then
            local installedManifest = require(installationDirectory .. "manifest")

            if tempManifest.version == installedManifest.version then
                print(string.format("%s is installed and up to date.", installedManifest.name))
                fs.delete("/tempInstall/")
                return true
            else
                print(string.format("A new release for %s is found.\nVersion: %s>%s\nWould you like to install it? (y/n)", installedManifest.name, installedManifest.version, tempManifest.version))
                local answer = service.getAnswer()

                if not answer then
                    fs.delete("/tempInstall/")
                    return true
                end
            end
        else
            print(string.format("%s is going to be installed.\nVersion: %s\nWould you like to install it? (y/n)", tempManifest.name, tempManifest.version))
            local answer = service.getAnswer()

            if not answer then
                fs.delete("/tempInstall/")
                return true
            end
        end

        local contents = {}

        for i, content in pairs(tempManifest.files) do
            contents[i] = http.get(url .. content[1]).readAll()
        end

        local installation = fs.open(fileManifest.directory, "w")
        installation.write(fs.open("/tempInstall/temp.lua", "r").readAll())
        installation.close()

        fs.delete("/tempInstall/")

        service.printFancy(string.format("%s %s successfully installed.", fileManifest.name, fileManifest.version))
    end,

    getDate = function()
        return os.date("%d/%m/%Y %T")
    end,

    getWirelessModem = function()
        service.printFancy("yellow", "Searching for Wireless Modem...")

        local WirelessModem = peripheral.find("modem", function(name, modem) return modem.isWireless() end)

        if WirelessModem then
            service.printFancy("green", "Wireless Modem found.")
        else
            printError("Wireless Modem not found.")
        end
    end,

    getWiredModem = function()
        service.printFancy("yellow", "Searching for Wired Network...")

        local WiredModem = peripheral.find("modem", function(name, modem) return not modem.isWireless() end)

        if WiredModem then
            service.printFancy("green", "Wired Modem found.")
        else
            printError("Wired Modem not found.", 0)
        end
    end,

    getAnswer = function()
        local answer
        repeat
            answer = read()
            answer = string.lower(answer)
            if answer ~= "y" and answer ~= "n" then
                printError("Invalid answer. (y/n)")
            end
        until answer == "y" or answer == "n"
        
        return answer == "y" and true or false
    end,

    printFancy = function(color, string)
        term.setTextColor(colors[color])
        print(string)
        term.setTextColor(colors.white)
    end,

    printData = function(data, nest)
        nest = nest == nil and 0 or nest

        if type(data) == "table" then
            for name, subData in pairs(data) do
                local tab = ""
                for i = 1, nest do
                    tab = tab .. "\t"
                end

                print(string.format("%s%s : %s", tab, name, subData))

                if type(subData) == "table" then
                    nest = nest + 1
                    service.printData(subData, nest)
                end
            end
        end
    end,

    printManifest = function(manifest)
        service.printFancy("green", string.format("\n%s loaded.", manifest.name))
        service.printFancy("green", string.format("Version: %s", manifest.version))
    end,
}

-- [Setup] --

service.install("https://github.com/TopraksuK/shadowcraft/releases/latest/download/")

service.printManifest(service.manifest)

return service