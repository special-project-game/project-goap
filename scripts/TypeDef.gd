class_name TypeDefs
enum Tile {WATER, DIRT, GRASS, SAND}
const TileName = {
	TypeDefs.Tile.WATER: "Water",
	TypeDefs.Tile.DIRT: "Dirt",
	TypeDefs.Tile.GRASS: "Grass",
	TypeDefs.Tile.SAND: "Sand",
}
enum Layer {WATER_GRASS, DIRT, SAND}
enum Objects {TREE, GRASS}
const ObjectName = {
	TypeDefs.Objects.TREE: "Tree",
	TypeDefs.Objects.GRASS: "Grass",
}
enum Entity {PERSON, PIG}
const EntityName = {
	TypeDefs.Entity.PERSON: "Person",
	TypeDefs.Entity.PIG: "Pig",
}
enum Mode {VIEW, PLACE_TILE, PLACE_OBJECT, PLACE_ENTITY}
