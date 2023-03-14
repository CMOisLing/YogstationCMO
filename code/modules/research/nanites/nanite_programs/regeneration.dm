/datum/nanite_program/metabolic_synthesis
	name = "Metabolic Synthesis"
	desc = "The nanites use the metabolic cycle of the host to speed up their replication rate, using their extra nutrition as fuel. Gains efficiency from cybernetic stomach."
	use_rate = -0.5 //generates nanites
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/metabolic_synthesis/check_conditions()
	if(!iscarbon(host_mob))
		return FALSE
	var/mob/living/carbon/C = host_mob
	if(C.nutrition <= NUTRITION_LEVEL_WELL_FED)
		return FALSE
	return ..()

/datum/nanite_program/metabolic_synthesis/active_effect()
	if(nanites.bonuses.Find("cyber_stomach"))
		host_mob.adjust_nutrition(-0.25)
	else
		host_mob.adjust_nutrition(-0.5)

/datum/nanite_program/mitosis
	name = "Mitosis"
	desc = "The nanites gain the ability to self-replicate, using bluespace to power the process, instead of drawing from a template. This rapidly speeds up the replication rate,\
			but it causes occasional software errors due to faulty copies. Not compatible with cloud sync."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/mitosis/active_effect()
	if(nanites.cloud_id)
		return
	var/rep_rate = round(nanites.nanite_volume / 50, 1) //0.5 per 50 nanite volume
	rep_rate *= 0.5
	nanites.adjust_nanites(null,rep_rate)
	if(prob(rep_rate))
		var/datum/nanite_program/fault = pick(nanites.programs)
		if(fault == src)
			return
		fault.software_error()

/datum/nanite_program/aggressive_replication
	name = "Aggressive Replication"
	desc = "Nanites will consume organic matter to improve their replication rate, damaging the host. The efficiency increases with the volume of nanites, requiring 200 to break even."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/necrotic)
	harmful = TRUE

/datum/nanite_program/aggressive_replication/active_effect()
	var/extra_regen = round(nanites.nanite_volume / 200, 0.1)
	nanites.adjust_nanites(null,extra_regen)
	host_mob.adjustBruteLoss(extra_regen / 2, TRUE)

/datum/nanite_program/toxic_replication
	name = "Toxic Replication"
	desc = "Nanites are constructed using alternative processes, increasing their replication rate, but creating toxic byproducts."
	use_rate = -0.5
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/toxic_replication/active_effect()
	host_mob.adjustToxLoss(0.5)

/datum/nanite_program/mitochondria_replication
	name = "Mitochondria Hijack"
	desc = "Nanites utilize the hosts mitochondira to replicate, this causes a large amount of fatigue for the host."
	use_rate = -2
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/mitochondria_replication/active_effect()
	if(iscarbon(host_mob) && !isdead(host_mob)) //No free nanites when your dead
		var/mob/living/carbon/C = host_mob
		var/max_stam_damage = 80
		if(nanites.bonuses.Find("upgraded_cyber_heart"))
			max_stam_damage = 40
		if(C.getStaminaLoss() < max_stam_damage)
			C.adjustStaminaLoss(5)
		if(prob(5))
			if(max_stam_damage < 80)
				to_chat(C, "<span class='warning'>You feel weak!")
			else
				to_chat(C, "<span class='warning'>You feel terribly weak!")

/datum/nanite_program/endothermic_replication
	name = "Endothermic Replication"
	desc = "Nanites replicate using a process that benefits from high temperatures, this process is endothermic and will cool the user down."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/endothermic_replication/active_effect()
	if(host_mob.bodytemperature >= BODYTEMP_HEAT_DAMAGE_LIMIT)
		var/regen = host_mob.bodytemperature / BODYTEMP_NORMAL
		host_mob.adjust_bodytemperature(-20) //might need to increase this later
		SEND_SIGNAL(host_mob, COMSIG_NANITE_ADJUST_VOLUME, regen)
		if(prob(5))
			to_chat(host_mob, span_notice("Your feel cold inside."))

/datum/nanite_program/solar_replication
	name = "Photochemical Replication"
	desc = "Nanites boost replication by turning the hosts skin into a solar collecter, using the energy gathered to fuel replication, this however weakens the hosts skin, and makes them vulnerable to lasers."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/solar_replication/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		H.physiology.armor.laser -= 20
		H.physiology.burn_mod *= 0.9
		H.physiology.brute_mod *= 0.9

/datum/nanite_program/solar_replication/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		H.physiology.armor.laser += 20
		H.physiology.burn_mod /= 0.9
		H.physiology.brute_mod /= 0.9

/datum/nanite_program/solar_replication/active_effect()
	var/light_amount = 0
	var/mob/living/carbon/C = host_mob
	if(isturf(C.loc))
		var/turf/T = C.loc
		light_amount = min(3, T.get_lumcount()) //Yolo
		SEND_SIGNAL(host_mob, COMSIG_NANITE_ADJUST_VOLUME, light_amount)

/datum/nanite_program/combustion_replication
	name = "Internal Combustion Replication"
	desc = "Nanites boost replication by burning hydrocarbons for energy, this heats up the user, losses efficiency at high temperatures cooling is recomended, also incompatable with endothermic replication."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/combustion_replication/check_conditions() // finish later
	. = ..()
	if(!iscarbon())
		return FALSE
	var/mob/living/carbon/C = host_mob
	if(host_mob.reagents.has_reagent(/datum/))


// -------------------------- mood based regen - emotional something something
