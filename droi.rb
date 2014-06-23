#!/usr/bin/env ruby

class XWingSim

		attr_accessor :num_sims, :atk_dice, :def_dice, :have_evade, :have_atk_focus, :have_def_focus, :have_target_lock

    @homing_missile = false
    @concussion_missile = false

		def initialize(args = {})

      @num_sims = 10000
      @atk_dice = 1
      @def_dice = 1
      @have_evade = false
      @have_def_focus = false
      @have_atk_focus = false

      @num_sims = args[:num_sims] if args.has_key? :num_sims
      @atk_dice = args[:atk_dice] if args.has_key? :atk_dice
      @def_dice = args[:def_dice] if args.has_key? :def_dice
      @have_evade = args[:have_evade] if args.has_key? :have_evade
      @have_atk_focus = args[:have_atk_focus] if args.has_key? :have_atk_focus
      @have_def_focus = args[:have_def_focus] if args.has_key? :have_def_focus
    end

    def use_homing_missile()
      @homing_missile = true
      @atk_dice = 4
      @have_evade = false
    end

    def use_concussion_missile()
      @concussion_missile = true
      @atk_dice = 4
    end

    def run()

      sims_with_dmg = 0
      sims_with_crit = 0
      dmg_total = 0
      crit_total = 0
      for i in 1..@num_sims

        dmg = 0
        crit = 0
        for a in 1..@atk_dice
          atk_result = Random.rand(1..8)
          # 1-2 miss
          # 3-5 hit
          # 6 crit
          # 7-8 focus
          if (atk_result >= 3 and atk_result <= 6) or (atk_result >= 7 and @have_atk_focus)
            dmg += 1
            if (atk_result == 6)
              crit += 1
            end
          end
        end

        for d in 1..@def_dice
          def_result = Random.rand(1..8)
          # 1-3 miss
          # 4-6 evade
          # 7-8 focus
          if (def_result >= 4 and def_result <= 6) or (def_result >= 7 and @have_def_focus)
            dmg -= 1
          end
        end

        if @have_evade
          dmg -= 1
        end

        dmg = [0, dmg].max
        crit = [crit, dmg].min

        if dmg > 0
          sims_with_dmg += 1
        end

        if crit > 0
          sims_with_crit += 1
        end

        dmg_total += dmg
        crit_total += crit
      end

      puts "#{@atk_dice} attack dice, #{@def_dice}, defense dice"
      puts "Attacker has focus: #{@have_atk_focus}"
      puts "Defender has focus: #{@have_def_focus}"
      puts "Defender has evade: #{@have_evade}"
      puts "Avg Damage: #{dmg_total.to_f / num_sims}"
      puts "Chance of 1+ Damage: #{sims_with_dmg.to_f / num_sims}"
      puts "Chance of 1+ Crit: #{sims_with_crit.to_f / num_sims}"
      #puts "Avg Crit: #{crit_total.to_f / num_sims}"
      puts
    end

end

sim = XWingSim.new

sim.have_evade = true
sim.have_def_focus = true
sim.have_atk_focus = true

sim.run

