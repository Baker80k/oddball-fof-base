SHELL=/bin/bash

.DEFAULT_GOAL := all

# The pathing in this project gets a little funny because the valve compilation tools
# are really particular about where they're executed, so in order to preserve the custom folder strcuture
# we need to do some pathing shenanigans
# Set these ABSOLUTE PATHS in your .bashrc
# PROJ_DIR // Wherever this project is installed
# FOF_INSTALL_DIR // sdk things like vpk and studiomdl
# FOF_SERVER_DIR // sourcemod things like spcomp and includes
# WEAPON_MODEL_DIR // Assumes each weapon type has a folder with its name containing all viewmodel, worldmodel, and material files

# This is for my setup where I have a windows machine with the game,
# while my dev environment and fof server is on wsl
# For your own use, set these things in your .bashrc to whatever
VPK="$(FOF_INSTALL_DIR)/sdk/bin/vpk.exe"
STUDIOMDL="$(FOF_INSTALL_DIR)/sdk/bin/studiomdl.exe"
SPCOMP="$(FOF_SERVER_DIR)/fof/addons/sourcemod/scripting/spcomp"

override sourcemod_incs_dir="$(FOF_SERVER_DIR)/fof/addons/sourcemod/scripting/include"
override plugins_dir=fof/addons/sourcemod/plugins
override custom_dir=fof/custom

# plugin refers to the .sp files
# scripts, models, and sounds are for custom .vpk's
# other is for anything else that needs to get put in the right spot

override sourcemod_incs=$(shell find $(sourcemod_incs_dir) -name '*.inc' 2>/dev/null)

override customguns_sps=$(shell find customguns-fof/scripting -name '*.sp' 2>/dev/null)
override customguns_incs=customguns-fof/scripting/include $(sourcemod_incs)
override customguns_inc_flags=$(addprefix -i ,$(customguns_incs))
override customguns_inc_files=$(shell find customguns-fof/scripting/include -name '*.inc')

customguns_plugin: $(customguns_sps:customguns-fof/scripting/%.sp=$(plugins_dir)/%.smx)

$(plugins_dir)/%.smx: customguns-fof/scripting/%.sp $(customguns_incs) $(customguns_inc_files)
	mkdir -p fof/addons/sourcemod/plugins
	@$(SPCOMP) $< -o $@ $(customguns_inc_flags) -O2 -v2

# Other
customguns_other: fof/addons/sourcemod/gamedata/customguns.txt fof/addons/sourcemod/configs/customguns_styles.txt
	
fof/addons/sourcemod/gamedata/customguns.txt: customguns-fof/gamedata/customguns.txt
	mkdir -p fof/addons/sourcemod/gamedata
	cp customguns-fof/gamedata/customguns.txt fof/addons/sourcemod/gamedata/customguns.txt

fof/addons/sourcemod/configs/customguns_styles.txt: customguns-fof/configs/customguns_styles.txt
	mkdir -p fof/addons/sourcemod/configs
	cp customguns-fof/configs/customguns_styles.txt fof/addons/sourcemod/configs/customguns_styles.txt

customguns: customguns_plugin customguns_other

# gungame_plugin:


override oddball_txts=$(shell find scripts -name '*.txt' 2>/dev/null)

override oddball_weapon_mdls=$(shell find $(WEAPON_MODEL_DIR) -name '*.mdl' 2>/dev/null)
override oddball_weapon_vtxs=$(shell find $(WEAPON_MODEL_DIR) -name '*.vtx' 2>/dev/null)
override oddball_weapon_phys=$(shell find $(WEAPON_MODEL_DIR) -name '*.phy' 2>/dev/null)
override oddball_weapon_vvds=$(shell find $(WEAPON_MODEL_DIR) -name '*.vvd' 2>/dev/null)

override oddball_weapon_smds=$(shell find $(WEAPON_MODEL_DIR) -name '*.smd' 2>/dev/null)

override oddball_weapon_vmts=$(shell find $(WEAPON_MODEL_DIR) -name '*.vmt' 2>/dev/null)
override oddball_weapon_vtfs=$(shell find $(WEAPON_MODEL_DIR) -name '*.vtf' 2>/dev/null)

override oddball_weapon_wavs=$(shell find $(WEAPON_MODEL_DIR) -name '*.wav' 2>/dev/null)

override oddball_sps=$(shell find oddball -name '*.sp' 2>/dev/null)
override oddball_incs=$(sourcemod_incs)
override oddball_inc_flags=$(addprefix -i ,$(oddball_incs))

oddball_plugin: $(oddball_sps:oddball/%.sp=$(plugins_dir)/%.smx)

$(plugins_dir)/%.smx: oddball/%.sp $(oddball_incs) $(oddball_inc_files) $(customguns_incs)
	@$(SPCOMP) $< -o $@ $(oddball_inc_flags) $(customguns_inc_flags) -O2 -v2

$(custom_dir)/oddball_scripts.vpk: $(oddball_txts)
	mkdir -p fof/custom
	${RM} $(custom_dir)/oddball_scripts.vpk
	$(VPK) a $(custom_dir)/oddball_scripts.vpk $(oddball_txts)

oddball_models: $(oddball_weapon_mdls) $(oddball_weapon_smds) $(oddball_weapon_vtxs) $(oddball_weapon_phys) $(oddball_weapon_vvds)
oddball_materials: $(oddball_weapon_vmts) $(oddball_weapon_vtfs)

# TODO: this is extremely hacky, but VPK doesn't want to cooperate
$(WEAPON_MODEL_DIR)/../oddball_assets.vpk: oddball_models oddball_materials $(oddball_weapon_wavs) asset_makefile
	${RM} $(WEAPON_MODEL_DIR)/../oddball_assets.vpk
	(cd $(WEAPON_MODEL_DIR)/.. && make)

$(WEAPON_MODEL_DIR)/../Makefile: workflow/asset_Makefile
	cp -u workflow/asset_Makefile $(WEAPON_MODEL_DIR)/../Makefile

asset_makefile: $(WEAPON_MODEL_DIR)/../Makefile

oddball: $(custom_dir)/oddball_scripts.vpk $(WEAPON_MODEL_DIR)/../oddball_assets.vpk oddball_plugin

all: customguns oddball

# Copy only updated stuff to server and client
upload_server: all
	${RM} -r $(FOF_SERVER_DIR)/fof/custom/*.cache
	cp -r -u fof $(FOF_SERVER_DIR)

upload_client: all
	${RM} -r "$(FOF_INSTALL_DIR)/fof/custom/*.cache"
	cp -r -u fof/custom "$(FOF_INSTALL_DIR)/fof"

upload: upload_server upload_client
	cp -u $(WEAPON_MODEL_DIR)/../oddball_assets.vpk $(FOF_SERVER_DIR)/fof/custom/oddball_assets.vpk 
	cp -u $(WEAPON_MODEL_DIR)/../oddball_assets.vpk "$(FOF_INSTALL_DIR)/fof/custom/oddball_assets.vpk"

# # Make a zip folder containing everything
release_zip: all
	mkdir -p fof/custom
	cp -u $(WEAPON_MODEL_DIR)/../oddball_assets.vpk $(custom_dir)/oddball_assets.vpk 
	zip -r oddball.zip fof

clean:
	$(RM) fof/addons/sourcemod/configs/*.txt
	$(RM) fof/addons/sourcemod/gamedata/*.txt
	$(RM) fof/addons/sourcemod/plugins/*.smx
	$(RM) fof/custom/*.vpk
	$(RM) $(WEAPON_MODEL_DIR)/../oddball_assets.vpk
	$(RM) -r $(WEAPON_MODEL_DIR)/../oddball_assets
	$(RM) "$(FOF_INSTALL_DIR)/fof/custom/*.vpk"
	$(RM) $(FOF_SERVER_DIR)/fof/custom/*.vpk
	
dirs:
	@echo $(PROJ_DIR)

# TODO: working on 
test:
	@echo $(shell find $(WEAPON_MODEL_DIR) -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

