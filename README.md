# Knife skins
Adds knife skins to the server, mainly meant for jailbreak mod.
Saves the chosen knife in nvault.

### Instalation
1. Download the knife_skins.sma and knife_skins.cfg files.
2. Compile it locally.
3. Upload the file to cstrike/addons/amxmodx/plugins.
4. Put 'knife_skins.amxx' into plugins.ini (preferably plugins-jb.ini, under the jail_api_jailbreak plugin).
5. Put 'knife_skins.cfg' into cstrike/addons/amxmodx/configs and continue with the instructions inside the file.

### Adding skins
1. Open knife_skins.sma
2. Add your skin to the SkinsData const as in the example in the code.

### Optional
If you want the plugin to be compatibile with jailbreak api, you need to uncomment 16th line.
Then add forward 'OnFight' to the jail_api_jailbreak plugin; OnFight(status)