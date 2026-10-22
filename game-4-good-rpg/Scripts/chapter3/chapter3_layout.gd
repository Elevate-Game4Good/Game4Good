extends RefCounted
## All positions are measured at the feet of a character or prop.
## Keep the old map origin so existing Chapter 3 saves stay in the same area.

const ORIGIN := Vector2(2857.5, 211.0)
const BOUNDS := Rect2(-1440, -1020, 2880, 2040)
const SPAWN := Vector2(0, 700)
const FOUNTAIN := Vector2(0, 35)
const STAGE := Vector2(-650, -300)
const FOOD := Vector2(650, 270)
const RITUAL := Vector2(80, -620)
const COUNCIL := Vector2(950, -330)
const CELEBRATION := Vector2(0, 390)
const CREW := Vector2(-330, 390)

const HOUSEHOLD_POSITIONS := {
	"Advaita": Vector2(80, -410),
	"Sarina": Vector2(-650, -70),
	"Aurora": Vector2(650, 460),
}

const REGION_LABELS := {
	"RITUAL GARDEN": Vector2(80, -830),
	"MUSIC & DANCE": Vector2(-650, -560),
	"SHARED FOOD": Vector2(650, 45),
	"COUNCIL HOUSE": Vector2(950, -630),
}

static func phase_from_state(state: Node) -> int:
	if state.chapter3_quest5_celebration_done:
		return 3
	if state.chapter3_quest4_town_dialogue_done:
		return 2
	if state.chapter3_quest3_festival_setup_done:
		return 1
	return 0
