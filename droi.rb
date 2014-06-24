#!/usr/bin/env ruby

class XWingSim

		attr_accessor :num_sims, :atk_dice, :def_dice, :have_evade, :have_atk_focus, :have_def_focus, :have_target_lock

    @homing_missile = false
    @concussion_missile = false

		def initialize(args = {})

      @num_sims = 100000
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
      @have_target_lock = args[:have_target_lock] if args.has_key? :have_target_lock
    end

    def use_homing_missile()
      @homing_missile = true
      @concussion_missile = false
      @atk_dice = 4
      @have_evade = false
      @have_target_lock = true # homing missiles require target lock but do not consume it
    end

    def use_concussion_missile()
      @concussion_missile = true
      @homing_missile = false
      @atk_dice = 4
      @have_target_lock = false # consumed by concussion missile
    end

    def run()

      dmg_buckets = Hash.new(0) # using hash because it can have an initial value
      crit_buckets = Hash.new(0)
      for i in 1..@num_sims

        dmg = 0
        crit = 0
        have_blank = false
        for a in 1..@atk_dice
          # 1-2 miss
          # 3-5 hit
          # 6 crit
          # 7-8 focus
          atk_result = Random.rand(1..8)

          if @have_target_lock
            if atk_result <= 2 or (not @have_atk_focus and atk_result >= 7)
              atk_result = Random.rand(1..8) # reroll blanks and focus (if no focus token)
            end
          end

          if (atk_result >= 3 and atk_result <= 6) or (atk_result >= 7 and @have_atk_focus)
            dmg += 1
            if (atk_result == 6)
              crit += 1
            end
          end

          if atk_result <= 2
            have_blank = true
          end
        end

        if have_blank and @concussion_missile
          dmg += 1
        end

        for d in 1..@def_dice
          # 1-3 miss
          # 4-6 evade
          # 7-8 focus
          def_result = Random.rand(1..8)
          if (def_result >= 4 and def_result <= 6) or (def_result >= 7 and @have_def_focus)
            dmg -= 1
          end
        end

        if @have_evade
          dmg -= 1
        end

        dmg = [0, dmg].max
        crit = [crit, dmg].min

        dmg_buckets[dmg] += 1
        crit_buckets[crit] += 1
      end

      total_dmg = 0
      dmg_buckets.each do |dmg, count|
        total_dmg += dmg.to_f * count
      end
      avg_dmg = total_dmg.to_f / @num_sims

      dmg_total = dmg_buckets.values.inject{ |sum, x| sum + x }

      puts "Ran #{@num_sims} simulations with..."
      attacker_descrip = "Attacker has #{@atk_dice} dice, #{"no " unless @have_atk_focus}focus, "
      if @concussion_missile
        attacker_descrip << "concussion missile"
      elsif @homing_missile
        attacker_descrip << "homing missile"
      else
        attacker_descrip << "#{"no " unless @have_target_lock}target lock"
      end
      puts attacker_descrip
      puts "Defender has #{@def_dice} dice, #{"no " unless @have_def_focus}focus, #{"no " unless @have_evade}evade"
      puts
      puts "Avg Damage: #{avg_dmg.round(2)}"
      puts
      puts "*** Damage histogram ***"
      puts ascii_histogram dmg_buckets
      puts
      puts "*** Crit histogram ***"
      puts ascii_histogram crit_buckets
      puts
      puts
    end

    def ascii_histogram(buckets)

      total_count = buckets.values.inject{ |sum, x| sum + x }
      max_count = buckets.values.max
      hist = ""
      buckets.sort.map do |key, count|
        pct = (count.to_f / total_count) * 100
        hist << "#{key} (#{pct.round(1)}%)"
        if (pct < 10)
          hist << " "
        end
        hist << ": "
        for i in 1..(pct / 2).to_i
          hist << "#"
        end
        hist << "\n"
      end

      hist

    end
end

sim = XWingSim.new

# simulates an a-wing vs tie at range 2 w/ TL, conc missile and homing missile
sim.atk_dice = 2
sim.def_dice = 3
sim.have_evade = false
sim.have_def_focus = false
sim.have_atk_focus = true
sim.have_target_lock = true

sim.run

sim.use_concussion_missile

sim.run

sim.use_homing_missile

sim.run

