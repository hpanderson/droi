#!/usr/bin/env ruby

class XWingSim

		attr_accessor :num_sims, :atk_dice, :def_dice, :have_evade, :have_atk_focus, :have_def_focus, :have_target_lock

    @homing_missile = false
    @concussion_missile = false
    @proton_torps = false
    @adv_proton_torps = false

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

    def clear_secondary()
      @homing_missile = false
      @concussion_missile = false
      @proton_torps = false
      @adv_proton_torps = false
    end

    def use_homing_missile()
      clear_secondary
      @homing_missile = true
      @atk_dice = 4
      @have_evade = false
      @have_target_lock = true # homing missiles require target lock but do not consume it
    end

    def use_concussion_missile()
      clear_secondary
      @concussion_missile = true
      @atk_dice = 4
      @have_target_lock = false # consumed by concussion missile
    end

    def use_proton_torpedoes()
      clear_secondary
      @proton_torps = true
      @atk_dice = 4
      @have_target_lock = false # consumed by torpedoes
    end

    def use_advanced_proton_torpedoes()
      clear_secondary
      @adv_proton_torps = true
      @atk_dice = 5
      @have_target_lock = false # consumed by torpedoes
    end

    # 1-2 miss
    # 3-5 hit
    # 6 crit
    # 7-8 focus
    def roll_attack
      face = Random.rand(1..8)
      if face <= 2
        return :blank
      elsif (face >= 3 and face <= 5)
        return :hit
      elsif face == 6
        return :crit
      end
      return :eye
    end

    # 1-3 miss
    # 4-6 evade
    # 7-8 focus
    def roll_defend
      face = Random.rand(1..8)
      if face <= 3
        return :blank
      elsif (face >= 4 and face <= 6)
        return :evade
      end
      return :eye
    end

    def attack(num_dice, focus, rerolls)

        results = Hash.new(0)
        for a in 1..num_dice

          result = roll_attack()
          should_reroll = false
          if rerolls > 0
            if result == :blank
              should_reroll = true # always reroll blanks
            elsif result == :eye and not focus
              # only reroll eyes if you don't have a focus
              if @proton_torps
                # save one eye for proton torpedoes to crit with, if present
                if results[:eye] >= 1
                  should_reroll = true
                end
              elsif not focus
                should_reroll = true
              end
            end

          end

          if should_reroll
            result = roll_attack()
            rerolls -= 1
          end

          results[result] += 1
        end

        if @proton_torps and results[:eye] > 0
          results[:crit] += 1
          results[:eye] -= 1
        end

        if @adv_proton_torps
          blanks = [results[:blank], 3].min
          results[:eye] += blanks
          results[:blank] -= blanks
        end

        if @concussion_missile and results[:blank] > 0
          results[:hit] += 1
          results[:blank] -= 1
        end

        if focus
          results[:hit] += results[:eye]
          results[:eye] = 0
        end

        results
    end

    def defend(num_dice, focus, evade)

        results = Hash.new(0)

        for a in 1..num_dice
          results[roll_defend()] += 1
        end

        if focus
          results[:evade] += results[:eye]
          results[:eye] = 0
        end

        if evade
          results[:evade] += 1
        end

        results
    end

    def run()

      dmg_buckets = Hash.new(0) # using hash because it can have an initial value
      crit_buckets = Hash.new(0)
      for i in 1..@num_sims

        attack_results = Hash.new(0)

        rerolls = @have_target_lock ? @atk_dice : 0 # could allow for more reroll attempts for ibtisam/krassis/howlrunner/etc
        atk_result = attack(@atk_dice, @have_atk_focus, rerolls)
        def_result = defend(@def_dice, @have_def_focus, @have_evade)

        if atk_result[:hit] > 0
          evaded = [atk_result[:hit], def_result[:evade]].min
          atk_result[:hit] -= evaded
          def_result[:evade] -= evaded
        end

        if atk_result[:crit] > 0
          evaded = [atk_result[:crit], def_result[:evade]].min
          atk_result[:crit] -= evaded
          def_result[:evade] -= evaded
        end

        dmg = atk_result[:hit] + atk_result[:crit]
        crit = atk_result[:crit]

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
      attacker_descrip << "#{"no " unless @have_target_lock}target lock"
      if @concussion_missile
        attacker_descrip << ", concussion missile"
      elsif @homing_missile
        attacker_descrip << ", homing missile"
      elsif @proton_torps
        attacker_descrip << ", proton torpedoes"
      elsif @adv_proton_torps
        attacker_descrip << ", advanced proton torpedoes"
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

