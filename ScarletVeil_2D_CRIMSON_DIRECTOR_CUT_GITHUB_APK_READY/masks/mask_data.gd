class_name MaskData
extends RefCounted

const DEFINITIONS := {
	"veilbound": {
		"name": "VEILBOUND",
		"description": "Heartglass dampens incoming Veilfire. 20% less damage.",
		"defense": 0.80,
		"attack_speed": 1.0,
		"damage": 1.0,
		"grapple_range": 1.0,
		"accent": Color("eee3db")
	},
	"hunter": {
		"name": "HUNTER",
		"description": "A predatory Heartglass cut. Faster attacks and stronger dash.",
		"defense": 1.0,
		"attack_speed": 0.72,
		"damage": 1.15,
		"grapple_range": 1.0,
		"accent": Color("f0a1a1")
	},
	"echo": {
		"name": "ECHO",
		"description": "Reveals hidden Memory Shards and distant Threadblade anchors.",
		"defense": 0.92,
		"attack_speed": 0.92,
		"damage": 1.0,
		"grapple_range": 1.28,
		"accent": Color("cfb8ec")
	}
}

static func get_mask(id: String) -> Dictionary:
	return DEFINITIONS.get(id, DEFINITIONS["veilbound"])
