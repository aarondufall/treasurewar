require("../lib/models/player")
require("../lib/models/treasure")

describe "Player", ->
  beforeEach ->
    @player = new Player(1, x: 3, y: 4)

  describe "tickPayload", ->
    it "should contain the players vitals", ->
      expect(@player.tickPayload()).toEqual {
        name: @player.name
        health: @player.health
        score: @player.score
        carrying_treasure: @player.isCarryingTreasure()
        item_in_hand: @player.item_in_hand
        stash:
          x: 3
          y: 4
          treasures: []
          position: @player.stash.position #ghetto
        position:
          x: 3
          y: 4

      }

  describe "calcScore", ->
    beforeEach ->
      @player.stash.treasures = [new Treasure(@player.position()), new Treasure(@player.position())]
      @player.kills = 3
      @player.calcScore()

    it "should have a score with kills + treasure", ->
      expect(@player.score).toEqual 23

  describe "#pickup(item)", ->
    beforeEach ->
      @item = new Treasure(@player.position())
      @player.pickup(@item)

    it "puts treasure in hand if not carrying anything", ->
      #true when nothing in hand
      @player.item_in_hand = null
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.pickup(treasure)).toEqual true

      #false when carrying something
      @player.item_in_hand = new Treasure({x: 1, y: 2})
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.pickup(treasure)).toEqual false

  describe "#dropHeldItem(item)", ->
    beforeEach ->
      @item = new Treasure(@player.position())
      @player.pickup(@item)

    it "drops the item if you're holding it and returns it", ->
      #item when holding item
      result = @player.dropHeldItem()
      expect(result).toEqual @item

      #false when not holding
      @player.item_in_hand = null
      result = @player.dropHeldItem()
      expect(result).toEqual false
