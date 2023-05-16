module block_type
    @enum BlockType begin
        Air
        Stone
        Grass
        Dirt
        Cobblestone
        WoodPlank
        Sapling
        Bedrock
        Water
        StationaryWater
        Lava
        StationaryLava
        Sand
        Gravel
        GoldOre
        IronOre
        CoalOre
        Wood
        Leaves
        Sponge
        Glass
        RedCloth
        OrangeCloth
        YellowCloth
        LimeCloth
        GreenCloth
        AquaGreenCloth
        CyanCloth
        BlueCloth
        PurpleCloth
        IndigoCloth
        VioletCloth
        MagentaCloth
        PinkCloth
        BlackCloth
        GrayCloth
        WhiteCloth
        YellowFlower
        RedRose
        BrownMushroom
        RedMushroom
        GoldBlock
        IronBlock
        DoubleStep
        Step
        Brick
        TNT
        Bookshelf
        MossStone
        Obsidian
    end
end
# I prefer all those values not to pollute the global namespace, I quite like how it has ended up
# being structured.

# Make sure these are all at least 25 and no more than 230, it wouldn't be difficult to add error
# checking where necessary, but it makes the code a whole lot less readable.
block_colours = Dict{block_type.BlockType, Tuple{UInt8, UInt8, UInt8}}(block_type.Air => (0, 0, 0),
    block_type.Stone => (128, 128, 128),
    block_type.Grass => (40, 200, 40),
    block_type.Dirt => (85, 55, 35),
    block_type.WoodPlank => (128, 64, 25)
    )

struct Block
    type::block_type.BlockType
end