//Programs that interact with other programs or nanites directly, or have other special purposes.
/datum/nanite_program/viral
	name = "Viral Replica"
	desc = "The nanites constantly send encrypted signals attempting to forcefully copy their own programming into other nanite clusters."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/toxic)
	extra_settings = list("Program Overwrite","Cloud Overwrite")

	var/sync_programs = TRUE
	var/sync_overwrite = FALSE
	var/overwrite_cloud = FALSE
	var/set_cloud = 0

/datum/nanite_program/viral/set_extra_setting(user, setting)
	if(setting == "Program Overwrite")
		var/overwrite_type = input("Choose what to do with the target's programs", name) as null|anything in list("Overwrite","Add To","Ignore")
		if(!overwrite_type)
			return
		switch(overwrite_type)
			if("Ignore") //Do not affect programs (if you only want to set the cloud ID)
				sync_programs = FALSE
				sync_overwrite = FALSE
			if("Add To") //Add to existing programs (so the target does not notice theirs are missing)
				sync_programs = TRUE
				sync_overwrite = FALSE
			if("Overwrite") //Replace target's programs with the source
				sync_programs = TRUE
				sync_overwrite = TRUE
	if(setting == "Cloud Overwrite")
		var/overwrite_type = input("Choose what to do with the target's Cloud ID", name) as null|anything in list("Overwrite","Disable","Keep")
		if(!overwrite_type)
			return
		switch(overwrite_type)
			if("Keep") //Don't change the cloud ID
				overwrite_cloud = FALSE
				set_cloud = 0
			if("Disable") //Set the cloud ID to disabled
				overwrite_cloud = TRUE
				set_cloud = 0
			if("Overwrite") //Set the cloud ID to what we choose
				var/new_cloud = input(user, "Choose the Cloud ID to set on infected nanites (1-100)", name, null) as null|num
				if(isnull(new_cloud))
					return
				overwrite_cloud = TRUE
				set_cloud = clamp(round(new_cloud, 1), 1, 100)

/datum/nanite_program/viral/get_extra_setting(setting)
	if(setting == "Program Overwrite")
		if(!sync_programs)
			return "Ignore"
		else if(sync_overwrite)
			return "Overwrite"
		else
			return "Add To"
	if(setting == "Cloud Overwrite")
		if(!overwrite_cloud)
			return "None"
		else if(set_cloud == 0)
			return "Disable"
		else
			return set_cloud

/datum/nanite_program/viral/copy_extra_settings_to(datum/nanite_program/viral/target)
	target.overwrite_cloud = overwrite_cloud
	target.set_cloud = set_cloud
	target.sync_programs = sync_programs
	target.sync_overwrite = sync_overwrite

/datum/nanite_program/viral/active_effect()
	for(var/mob/M in orange(host_mob, 5))
		if(prob(5))
			if(sync_programs)
				SEND_SIGNAL(M, COMSIG_NANITE_SYNC, nanites, sync_overwrite)
			if(overwrite_cloud)
				SEND_SIGNAL(M, COMSIG_NANITE_SET_CLOUD, set_cloud)

/datum/nanite_program/monitoring
	name = "Monitoring"
	desc = "The nanites monitor the host's vitals and location, sending them to the suit sensor network."
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/monitoring/enable_passive_effect()
	. = ..()
	SSnanites.nanite_monitored_mobs |= host_mob
	host_mob.hud_set_nanite_indicator()

/datum/nanite_program/monitoring/disable_passive_effect()
	. = ..()
	SSnanites.nanite_monitored_mobs -= host_mob
	host_mob.hud_set_nanite_indicator()

/datum/nanite_program/triggered/self_scan
	name = "Host Scan"
	desc = "The nanites display a detailed readout of a body scan to the host."
	unique = FALSE
	trigger_cost = 3
	trigger_cooldown = 50
	rogue_types = list(/datum/nanite_program/toxic)

	extra_settings = list("Scan Type")
	var/scan_type = "Medical"

/datum/nanite_program/triggered/self_scan/set_extra_setting(user, setting)
	if(setting == "Scan Type")
		var/list/scan_types = list("Medical","Chemical","Wound","Nanite")
		var/new_scan_type = input("Choose the scan type", name) as null|anything in scan_types
		if(!new_scan_type)
			return
		scan_type = new_scan_type

/datum/nanite_program/triggered/self_scan/get_extra_setting(setting)
	if(setting == "Scan Type")
		return scan_type

/datum/nanite_program/triggered/self_scan/copy_extra_settings_to(datum/nanite_program/triggered/self_scan/target)
	target.scan_type = scan_type

/datum/nanite_program/triggered/self_scan/trigger()
	if(!..())
		return
	if(host_mob.stat == DEAD)
		return
	switch(scan_type)
		if("Medical")
			healthscan(host_mob, host_mob)
		if("Chemical")
			chemscan(host_mob, host_mob)
		if("Wound")
			woundscan(host_mob, host_mob)
		if("Nanite")
			SEND_SIGNAL(host_mob, COMSIG_NANITE_SCAN, host_mob, TRUE)

/datum/nanite_program/stealth
	name = "Stealth"
	desc = "The nanites hide their activity and programming from superficial scans."
	rogue_types = list(/datum/nanite_program/toxic)
	use_rate = 0.2

/datum/nanite_program/stealth/enable_passive_effect()
	. = ..()
	nanites.stealth = TRUE

/datum/nanite_program/stealth/disable_passive_effect()
	. = ..()
	nanites.stealth = FALSE

/datum/nanite_program/relay
	name = "Relay"
	desc = "The nanites receive and relay long-range nanite signals."
	rogue_types = list(/datum/nanite_program/toxic)

	extra_settings = list("Relay Channel")
	var/relay_channel = 1

/datum/nanite_program/relay/set_extra_setting(user, setting)
	if(setting == "Relay Channel")
		var/new_channel = input(user, "Set the relay channel (1-9999):", name, null) as null|num
		if(isnull(new_channel))
			return
		relay_channel = clamp(round(new_channel, 1), 1, 9999)

/datum/nanite_program/relay/get_extra_setting(setting)
	if(setting == "Relay Channel")
		return relay_channel

/datum/nanite_program/relay/copy_extra_settings_to(datum/nanite_program/relay/target)
	target.relay_channel = relay_channel

/datum/nanite_program/relay/enable_passive_effect()
	. = ..()
	SSnanites.nanite_relays |= src

/datum/nanite_program/relay/disable_passive_effect()
	. = ..()
	SSnanites.nanite_relays -= src

/datum/nanite_program/relay/proc/relay_signal(code, relay_code, source)
	if(!activated)
		return
	if(!host_mob)
		return
	if(relay_code != relay_channel)
		return
	SEND_SIGNAL(host_mob, COMSIG_NANITE_SIGNAL, code, source)

/datum/nanite_program/relay/proc/relay_comm_signal(comm_code, relay_code, comm_message)
	if(!activated)
		return
	if(!host_mob)
		return
	if(relay_code != relay_channel)
		return
	SEND_SIGNAL(host_mob, COMSIG_NANITE_COMM_SIGNAL, comm_code, comm_message)

/datum/nanite_program/research
	name = "Distributed Computing"
	desc = "The nanites aid the research servers by performing a portion of its calculations, increasing research point generation."
	use_rate = 0.2
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/research/active_effect()
	if(!iscarbon(host_mob))
		return
	var/points = 1
	if(!host_mob.client) //less brainpower
		points *= 0.25
	SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = points))

/datum/nanite_program/researchplus
	name = "Neural Network"
	desc = "The nanites link the host's brains together forming a neural research network, that becomes more efficient with the amount of total hosts."
	use_rate = 0.3
	rogue_types = list(/datum/nanite_program/brain_decay)
	var/points

/datum/nanite_program/researchplus/enable_passive_effect()
	. = ..()
	if(!iscarbon(host_mob))
		return

	points = host_mob.client ? 1 : 0.25
	SSnanites.neural_network_count += points

/datum/nanite_program/researchplus/disable_passive_effect()
	. = ..()
	if(!iscarbon(host_mob))
		return

	SSnanites.neural_network_count -= points

/datum/nanite_program/researchplus/active_effect()
	if(!iscarbon(host_mob))
		return
	var/mob/living/carbon/C = host_mob
	var/points = round(SSnanites.neural_network_count / 12, 0.1)
	if(!C.client) //less brainpower
		points *= 0.25
	SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = points))

/datum/nanite_program/triggered/access
	name = "Subdermal ID"
	desc = "The nanites store the host's ID access rights in a subdermal magnetic strip. Updates when triggered, copying the host's current access."
	rogue_types = list(/datum/nanite_program/skin_decay)
	var/access = list()

//Syncs the nanites with the cumulative current mob's access level. Can potentially wipe existing access.
/datum/nanite_program/triggered/access/trigger()
	var/list/new_access = list()
	var/obj/item/current_item
	current_item = host_mob.get_active_held_item()
	if(current_item)
		new_access += current_item.GetAccess()
	current_item = host_mob.get_inactive_held_item()
	if(current_item)
		new_access += current_item.GetAccess()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		current_item = H.wear_id
		if(current_item)
			new_access += current_item.GetAccess()
	else if(isanimal(host_mob))
		var/mob/living/simple_animal/A = host_mob
		current_item = A.access_card
		if(current_item)
			new_access += current_item.GetAccess()
	access = new_access

/datum/nanite_program/spreading
	name = "Infective Exo-Locomotion"
	desc = "The nanites gain the ability to survive for brief periods outside of the human body, as well as the ability to start new colonies without an integration process; \
			resulting in an extremely infective strain of nanites."
	use_rate = 1.50
	rogue_types = list(/datum/nanite_program/aggressive_replication, /datum/nanite_program/necrotic)

/datum/nanite_program/spreading/active_effect()
	if(prob(10))
		var/list/mob/living/target_hosts = list()
		for(var/mob/living/L in oview(5, host_mob))
			if(!(MOB_ORGANIC in L.mob_biotypes) && !(MOB_UNDEAD in L.mob_biotypes) && !isipc(L))
				continue
			target_hosts += L
		if(!target_hosts.len)
			return
		var/mob/living/infectee = pick(target_hosts)
		if(prob(100 - (infectee.get_permeability_protection() * 100)))
			//this will potentially take over existing nanites!
			infectee.AddComponent(/datum/component/nanites, 10)
			SEND_SIGNAL(infectee, COMSIG_NANITE_SYNC, nanites)
			infectee.investigate_log("was infected by spreading nanites by [key_name(host_mob)] at [AREACOORD(infectee)].", INVESTIGATE_NANITES)

/datum/nanite_program/dermal_button
	name = "Dermal Button"
	desc = "Displays a button on the host's skin, which can be used to send a signal to the nanites."
	extra_settings = list("Sent Code","Button Name","Icon","Color")
	unique = FALSE
	var/datum/action/innate/nanite_button/button
	var/button_name = "Button"
	var/icon = "power"
	var/color = "green"
	var/sent_code = 0

/datum/nanite_program/dermal_button/set_extra_setting(user, setting)
	if(setting == "Sent Code")
		var/new_code = input(user, "Set the sent code (1-9999):", name, null) as null|num
		if(isnull(new_code))
			return
		sent_code = clamp(round(new_code, 1), 1, 9999)
	if(setting == "Button Name")
		var/new_button_name = stripped_input(user, "Choose the name for the button.", "Button Name", button_name, MAX_NAME_LEN)
		if(!new_button_name)
			return
		button_name = new_button_name
	if(setting == "Icon")
		var/new_icon = input("Select the icon to display on the button:", name) as null|anything in list("one","two","three","four","five","plus","minus","power")
		if(!new_icon)
			return
		icon = new_icon
	if(setting == "Color")
		var/new_color = input("Select the color of the button's icon:", name) as null|anything in list("green","red","yellow","blue")
		if(!new_color)
			return
		color = new_color

/datum/nanite_program/dermal_button/get_extra_setting(setting)
	if(setting == "Sent Code")
		return sent_code
	if(setting == "Button Name")
		return button_name
	if(setting == "Icon")
		return capitalize(icon)
	if(setting == "Color")
		return capitalize(color)

/datum/nanite_program/dermal_button/copy_extra_settings_to(datum/nanite_program/dermal_button/target)
	target.sent_code = sent_code
	target.button_name = button_name
	target.icon = icon
	target.color = color

/datum/nanite_program/dermal_button/enable_passive_effect()
	. = ..()
	if(!button)
		button = new(src, button_name, icon, color)
	button.target = host_mob
	button.Grant(host_mob)

/datum/nanite_program/dermal_button/disable_passive_effect()
	. = ..()
	if(button)
		button.Remove(host_mob)

/datum/nanite_program/dermal_button/on_mob_remove()
	. = ..()
	qdel(button)

/datum/nanite_program/dermal_button/proc/press()
	if(activated)
		host_mob.visible_message(span_notice("[host_mob] presses a button on [host_mob.p_their()] forearm."),
								span_notice("You press the nanite button on your forearm."), null, 2)
		SEND_SIGNAL(host_mob, COMSIG_NANITE_SIGNAL, sent_code, "a [name] program")

/datum/action/innate/nanite_button
	name = "Button"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	button_icon_state = "power_green"
	var/datum/nanite_program/dermal_button/program

/datum/action/innate/nanite_button/New(datum/nanite_program/dermal_button/_program, _name, _icon, _color)
	..()
	program = _program
	name = _name
	button_icon_state = "[_icon]_[_color]"

/datum/action/innate/nanite_button/Activate()
	program.press()
