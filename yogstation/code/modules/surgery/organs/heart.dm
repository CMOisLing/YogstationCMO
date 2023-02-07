/obj/item/organ/heart/nanite
	name = "Nanite heart"
	desc = "A specialized heart constructed from nanites that helps coordinate nanites allowing them to regenerate quicker inside the body without any ill effects. Caution this organ will fall apart without nanites to sustain itself!"
	icon_state = "heart-nanites"
	organ_flags = ORGAN_SYNTHETIC
	var/nanite_boost = 3
	var/volume_boost = 200

/obj/item/organ/heart/nanite/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE,special_zone = null)
	if(SEND_SIGNAL(M, COMSIG_HAS_NANITES))
		SEND_SIGNAL(M, COMSIG_NANITE_ADJUST_MAX_VOLUME, volume_boost)

/obj/item/organ/heart/nanite/Remove(mob/living/carbon/M, special = FALSE)
	if(SEND_SIGNAL(M, COMSIG_HAS_NANITES))
		SEND_SIGNAL(M, COMSIG_NANITE_ADJUST_MAX_VOLUME, -volume_boost)

/obj/item/organ/heart/nanite/emp_act()
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return .
	Stop()

/obj/item/organ/heart/nanite/on_life()
	. = ..()
	if(SEND_SIGNAL(owner, COMSIG_HAS_NANITES))
		SEND_SIGNAL(owner, COMSIG_NANITE_ADJUST_VOLUME, nanite_boost)
	else
		if(owner)
			to_chat(owner, span_userdanger("You feel your heart collapse in on itself!"))
			Remove(owner) //the heart is made of nanites so without them it just breaks down
		qdel(src)
