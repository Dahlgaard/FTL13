
/////////////////////////////////////////////
//////// Attach a trail to any object, that spawns when it moves (like for the jetpack)
/// just pass in the object to attach it to in set_up
/// Then do start() to start it and stop() to stop it, obviously
/// and don't call start() in a loop that will be repeated otherwise it'll get spammed!
/////////////////////////////////////////////

/datum/effect_system/trail_follow
	var/turf/oldposition
	var/processing = 1
	var/on = 1

/datum/effect_system/trail_follow/set_up(atom/atom)
	attach(atom)
	oldposition = get_turf(atom)

/datum/effect_system/trail_follow/Destroy()
	oldposition = null
	return ..()

/datum/effect_system/trail_follow/proc/stop()
	processing = 0
	on = 0
	oldposition = null

/datum/effect_system/trail_follow/steam
	effect_type = /obj/effect/particle_effect/steam

/datum/effect_system/trail_follow/steam/start()
	if(!on)
		on = 1
		processing = 1
		if(!oldposition)
			oldposition = get_turf(holder)
	if(processing)
		processing = 0
		if(number < 3)
			var/obj/effect/particle_effect/steam/I = new /obj/effect/particle_effect/steam(oldposition)
			number++
			I.setDir(holder.dir)
			oldposition = get_turf(holder)
			spawn(10)
				qdel(I)
				number--
		spawn(2)
			if(on)
				processing = 1
				start()

/obj/effect/particle_effect/ion_trails
	name = "ion trails"
	icon_state = "ion_trails"
	anchored = 1

/obj/effect/particle_effect/ion_trails/flight
	icon_state = "ion_trails_flight"

/datum/effect_system/trail_follow/ion
	effect_type = /obj/effect/particle_effect/ion_trails
	var/fadetype = "ion_fade"
	var/fade = 1
	var/nograv_required = 1

/datum/effect_system/trail_follow/ion/start() //Whoever is responsible for this abomination of code should become an hero
	if(!on)
		on = 1
		processing = 1
		if(!oldposition)
			oldposition = get_turf(holder)
	if(processing)
		processing = 0
		var/turf/T = get_turf(holder)
		if(T != oldposition)
			if(!T.has_gravity() || !nograv_required)
				var/obj/effect/particle_effect/ion_trails/I = new effect_type(oldposition)
				set_dir(I)
				if(fade)
					flick(fadetype, I)
					I.icon_state = ""
				spawn(20)
					qdel(I)
			oldposition = T
		spawn(2)
			if(on)
				processing = 1
				start()

/datum/effect_system/trail_follow/ion/proc/set_dir(obj/effect/particle_effect/ion_trails/I)
	I.setDir(holder.dir)

/datum/effect_system/trail_follow/ion/flight
	effect_type = /obj/effect/particle_effect/ion_trails/flight
	fadetype = "ion_fade_flight"
	nograv_required = 0

/datum/effect_system/trail_follow/ion/flight/set_dir(obj/effect/particle_effect/ion_trails/I)
	if(istype(holder, /obj/item/device/flightpack))
		var/obj/item/device/flightpack/F = holder
		I.setDir(F.suit.user.dir)

/datum/effect_system/trail_follow/ion/spacepod
	var/turf/oldloc // secondary ion trail loc
	var/turf/currloc

/datum/effect_system/trail_follow/ion/spacepod/Destroy()
	oldloc = null
	currloc = null
	return ..()

/datum/effect_system/trail_follow/ion/spacepod/start()
	if(!src.on)
		src.on = 1
		src.processing = 1
	if(src.processing)
		src.processing = 0
		spawn(0)
			var/turf/T = get_turf(src.holder)
			if(currloc != T)
				switch(holder.dir)
					if(NORTH)
						src.oldposition = T
						src.oldposition = get_step(oldposition, SOUTH)
						src.oldloc = get_step(oldposition,EAST)
						//src.oldloc = get_step(oldloc, SOUTH)
					if(SOUTH) // More difficult, offset to the north!
						src.oldposition = get_step(holder,NORTH)
						src.oldposition = get_step(oldposition,NORTH)
						src.oldloc = get_step(oldposition,EAST)
						//src.oldloc = get_step(oldloc,NORTH)
					if(EAST) // Just one to the north should suffice
						src.oldposition = T
						src.oldposition = get_step(oldposition, WEST)
						src.oldloc = get_step(oldposition,NORTH)
						//src.oldloc = get_step(oldloc,WEST)
					if(WEST) // One to the east and north from there
						src.oldposition = get_step(holder,EAST)
						src.oldposition = get_step(oldposition,EAST)
						src.oldloc = get_step(oldposition,NORTH)
						//src.oldloc = get_step(oldloc,EAST)
				if(istype(T, /turf/open/space))
					var/obj/effect/particle_effect/ion_trails/I = new /obj/effect/particle_effect/ion_trails(effect_type, oldposition)
					var/obj/effect/particle_effect/ion_trails/II = new /obj/effect/particle_effect/ion_trails(effect_type, oldloc)
					//src.oldposition = T
					I.dir = src.holder.dir
					II.dir = src.holder.dir
					flick("ion_fade", I)
					flick("ion_fade", II)
					I.icon_state = ""
					II.icon_state = ""
					spawn( 20 )
						qdel(I)
						qdel(II)
			spawn(2)
				if(src.on)
					src.processing = 1
					src.start()
			currloc = T


//Reagent-based explosion effect

/datum/effect_system/reagents_explosion
	var/amount 						// TNT equivalent
	var/flashing = 0			// does explosion creates flash effect?
	var/flashing_factor = 0		// factor of how powerful the flash effect relatively to the explosion
	var/explosion_message = 1				//whether we show a message to mobs.

/datum/effect_system/reagents_explosion/set_up(amt, loca, flash = 0, flash_fact = 0, message = 1)
	amount = amt
	explosion_message = message
	if(isturf(loca))
		location = loca
	else
		location = get_turf(loca)

	flashing = flash
	flashing_factor = flash_fact

/datum/effect_system/reagents_explosion/start()
	if(explosion_message)
		location.visible_message("<span class='danger'>The solution violently explodes!</span>", \
								"<span class='italics'>You hear an explosion!</span>")
	if (amount < 1)
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(2, 1, location)
		s.start()

		for(var/mob/living/L in viewers(1, location))
			if(prob(50 * amount))
				to_chat(L, "<span class='danger'>The explosion knocks you down.</span>")
				L.Knockdown(rand(20,100))
		return
	else
		dyn_explosion(location, amount, flashing_factor)
