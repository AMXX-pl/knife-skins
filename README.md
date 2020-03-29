# Knife skins
Adds knife skins to the server, mainly meant for jailbreak mod.
Saves the chosen knife in nvault.

### Instalation
1. Download the knife_skins.sma file.
2. Compile it locally.
3. Upload the file to cstrike/addons/amxmodx/plugins.
4. Put 'knife_skins.amxx' into plugins.ini (preferably plugins-jb.ini, under the jail_api_jailbreak plugin).

### Optional
If you want the plugin to be compatibile with jailbreak api, you need to uncomment 16th line.
Then add forward 'OnFight' to the jail_api_jailbreak plugin; OnFight(status)