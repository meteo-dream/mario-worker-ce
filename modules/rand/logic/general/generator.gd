extends Node

enum LEVEL_THEMES {
	Overworld,
	Underground,
	Underwater,
	Overwater,
	Castle,
}

enum PATTERNS {
	START_PATCH,
	PIPE_UP,
	PIPE_MIDDLE,
	PIPE_DOWN,
	STAIR_BOTTOM_RIGHT,
	STAIR_BOTTOM_LEFT,
	STAIR_TOP_LEFT,
	STAIR_TOP_RIGHT,
	GROUND_LEFT,
	GROUND_MIDDLE,
	GROUND_RIGHT,
}

const LevelThemes: Array = [ "overworld", "underground", "underwater", "overwater", "castle" ]
const StageTemplates: Array = [
	"res://modules/rand/base_stages/overworld.tscn",
]

@onready var rnglvl = RandomNumberGenerator.new()

func generate_level(aseed: String = "testseed") -> void:
	#var _prevstate = rnglvl.state
	rnglvl.seed = hash(aseed)
	#rnglvl.state = _prevstate
	
	var level: Node = load(StageTemplates[LEVEL_THEMES.Overworld]).instantiate()
	
	_generate_tiles(level)
	
	
	
	save_level(level)


func _generate_tiles(level: Level) -> void:
	var tiles: TileMapLayer = level.get_node("Tiles")
	tiles.set_pattern(Vector2i(0, 13), tiles.tile_set.get_pattern(0))
	
	const HARD_BLOCK: int = 2
	
	var queue: PackedByteArray = []
	queue.resize(8)
	queue.fill(0)
	var queue_data: PackedStringArray = []
	queue_data.resize(8)
	queue_data.fill("")
	var queue_pos: PackedVector2Array = []
	queue_pos.resize(8)
	queue_pos.fill(Vector2.ZERO)
	
	var x_build_ban: int = 5
	var y_build_ban: int = 12
	
	var build_loop_limit := Vector2i(325, 14)
	var xindex: int = -1
	while xindex < build_loop_limit.x:
		xindex += 1
		if xindex < x_build_ban: continue
		var queue_modified: bool
		var queue_init: PackedByteArray = []
		queue_init.resize(8)
		queue_init.fill(0)
		
		var yindex: int = -1
		while yindex < build_loop_limit.y:
			yindex += 1
			#if yindex < 5: continue
			if yindex < y_build_ban: continue
			
			var qind: int = queue.find(0)
			if qind == -1:
				continue
			
			if yindex == 12 && rnglvl.randi_range(0, 5) == 0 && queue[7] == 0:
				queue_modified = true
				queue[7] = rnglvl.randi_range(2, 15)
				queue_data[7] = "ground"
				queue_pos[7] = Vector2(xindex, yindex)
				queue_init[7] = 1
				
			if rnglvl.randi_range(0, 1) == 0:
				queue_modified = true
				queue[qind] = rnglvl.randi_range(1, 5)
				queue_data[qind] = "hard"
				queue_pos[qind] = Vector2(xindex, yindex)
				queue_init[qind] = 1
		
		if !queue_modified: continue
		for i in len(queue):
			if queue[i] == 0:
				#y_build_ban = 12
				continue
			#if queue_init[i] == 0: continue
			
			#var long_vectors: PackedVector2Array = []
			#long_vectors.resize(i)
			#for j in i:
				#long_vectors[j] = queue_pos[i] + Vector2(j, 0)
			
			match queue_data[i]:
				"hard":
					y_build_ban -= 1
					#print(y_build_ban)
					tiles.set_cell(queue_pos[i], HARD_BLOCK, Vector2i.ZERO)
				"ground":
					#var tile_pattern: Array[Vector2i] = [
						#Vector2i(0, 13)
					#]
					#tiles.set_cells_terrain_connect(long_vectors, 0, 0)
					if queue_init[i] == 1:
						tiles.set_pattern(queue_pos[i], tiles.tile_set.get_pattern(PATTERNS.GROUND_LEFT))
					elif queue[i] == 0:
						tiles.set_pattern(queue_pos[i], tiles.tile_set.get_pattern(PATTERNS.GROUND_RIGHT))
					else:
						tiles.set_pattern(queue_pos[i], tiles.tile_set.get_pattern(PATTERNS.GROUND_MIDDLE))
			
			queue[i] -= 1
			if queue[i] == 0:
				queue_data[i] = ""
				queue_pos[i] = Vector2i.ZERO
		#y_build_ban = clampi(y_build_ban, 0, 12)
	
	#for i in rnglvl.randi_range(10, 20):
		
	
	


func save_level(level: Node) -> void:
	var pckd := PackedScene.new()
	var err := pckd.pack(level)
	if err:
		print(error_string(err))
		return
	var er = ResourceSaver.save(pckd, "user://savedlvl.scn", ResourceSaver.FLAG_COMPRESS)
	if er:
		print(error_string(er))
