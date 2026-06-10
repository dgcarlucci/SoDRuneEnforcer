local _, addon = ...
print("|cff00ff00[SRE]|r RuneData.lua initializing...")

-- Phase mapping:
-- [1] = Level 25 (Chest, Hands, Legs)
-- [2] = Level 40 (Waist, Feet)
-- [3] = Level 50 (Head, Wrist)
-- [4] = Level 60 (Back/Cloak, Rings)
-- [5] = Level 60+ (Utility Rings)

addon.RuneData = {
    ["Warrior"] = {
        [1] = {
            ["Chest"] = {"Blood Frenzy", "Flagellation", "Raging Blow", "Warbringer"},
            ["Hands"] = {"Devastate", "Endless Rage", "Quick Strike", "Victory Rush", "Single-Minded Fury"},
            ["Legs"] = {"Consumed by Rage", "Frenzied Assault", "Furious Thunder"}
        },
        [2] = {
            ["Waist"] = {"Blood Surge", "Precise Timing", "Slam"},
            ["Feet"] = {"Enraged Regeneration", "Intervene", "Rallying Cry"}
        },
        [3] = {
            ["Head"] = {"Shield Mastery", "Taste for Blood", "Vigilance"},
            ["Wrist"] = {"Rampage", "Sword and Board", "Wrecking Crew"}
        },
        [4] = {
            ["Back"] = {"Fresh Meat", "Shockwave", "Sudden Death"}
        }
    },
    ["Paladin"] = {
        [1] = {
            ["Chest"] = {"Divine Storm", "Horn of Lordaeron", "Aegis", "Seal of Martyrdom"},
            ["Hands"] = {"Beacon of Light", "Crusader Strike", "Hand of Reckoning"},
            ["Legs"] = {"Avenger's Shield", "Divine Sacrifice", "Exorcist", "Inspiration Exemplar", "Rebuke"}
        },
        [2] = {
            ["Waist"] = {"Sheath of Light", "Infusion of Light", "Enlightened Judgements"},
            ["Feet"] = {"Guarded by the Light", "Sacred Shield", "The Art of War"}
        },
        [3] = {
            ["Head"] = {"Fanaticism", "Improved Sanctuary", "Wrath"},
            ["Wrist"] = {"Light's Grace", "Purifying Power", "Hammer of the Righteous", "Improved Hammer of Wrath"}
        },
        [4] = {
            ["Back"] = {"Righteous Vengeance", "Shield of Righteousness", "Vindicator"}
        }
    },
    ["Hunter"] = {
        [1] = {
            ["Chest"] = {"Aspect of the Lion", "Cobra Strike", "Lone Wolf", "Master Marksman"},
            ["Hands"] = {"Beast Mastery", "Chimera Shot", "Explosive Shot"},
            ["Legs"] = {"Carve", "Flanking Strike", "Kill Command", "Sniper Training"}
        },
        [2] = {
            ["Waist"] = {"Expose Weakness", "Melee Specialist", "Steady Shot"},
            ["Feet"] = {"Dual Wield Specialization", "Invigoration", "Trap Launcher"}
        },
        [3] = {
            ["Head"] = {"Catlike Reflexes", "Lock and Load", "Rapid Killing"},
            ["Wrist"] = {"Focus Fire", "T.N.T.", "Improved Raptor Strike"}
        },
        [4] = {
            ["Back"] = {"Hit and Run", "Improved Volley", "Resourcefulness"}
        }
    },
    ["Rogue"] = {
        [1] = {
            ["Chest"] = {"Deadly Brew", "Just a Flesh Wound", "Quick Draw", "Slaughter from the Shadows"},
            ["Hands"] = {"Main Gauche", "Mutilate", "Shadowstrike", "Shiv"},
            ["Legs"] = {"Between the Eyes", "Blade Dance", "Envenom"}
        },
        [2] = {
            ["Waist"] = {"Poisoned Knife", "Shadowstep", "Shuriken Toss"},
            ["Feet"] = {"Master of Subtlety", "Rolling with the Punches", "Waylay"}
        },
        [3] = {
            ["Head"] = {"Combat Potency", "Focused Attacks", "Honor Among Thieves"},
            ["Wrist"] = {"Carnage", "Cut to the Chase", "Unfair Advantage"}
        },
        [4] = {
            ["Back"] = {"Blunderbuss", "Crimson Tempest", "Fan of Knives"}
        }
    },
    ["Priest"] = {
        [1] = {
            ["Chest"] = {"Serendipity", "Strength of Soul", "Twisted Fate", "Void Plague"},
            ["Hands"] = {"Circle of Healing", "Mind Sear", "Penance", "Shadow Word: Death"},
            ["Legs"] = {"Homunculi", "Power Word: Barrier", "Prayer of Mending", "Shared Pain"}
        },
        [2] = {
            ["Waist"] = {"Empowered Renew", "Mind Spike", "Renewed Hope"},
            ["Feet"] = {"Dispersion", "Pain and Suffering", "Surge of Light"}
        },
        [3] = {
            ["Head"] = {"Divine Aegis", "Eye of the Void", "Pain Spike"},
            ["Wrist"] = {"Despair", "Surge of Light", "Void Zone"}
        },
        [4] = {
            ["Back"] = {"Binding Heal", "Soul of Piety", "Vampiric Touch"}
        }
    },
    ["Shaman"] = {
        [1] = {
            ["Chest"] = {"Dual Wield Specialization", "Healing Rain", "Overload", "Shield Mastery"},
            ["Hands"] = {"Lava Burst", "Lava Lash", "Molten Blast", "Water Shield"},
            ["Legs"] = {"Ancestral Guidance", "Earth Shield", "Shamanistic Rage", "Way of Earth"}
        },
        [2] = {
            ["Waist"] = {"Fire Nova", "Maelstrom Weapon", "Power Surge"},
            ["Feet"] = {"Ancestral Awakening", "Decoy Totem", "Spirit of the Alpha"}
        },
        [3] = {
            ["Head"] = {"Burn", "Mental Dexterity", "Tidal Waves"},
            ["Wrist"] = {"Overcharged", "Riptide", "Rolling Thunder"}
        },
        [4] = {
            ["Back"] = {"Coherence", "Feral Spirit", "Storm, Earth and Fire"}
        }
    },
    ["Druid"] = {
        [1] = {
            ["Chest"] = {"Fury of Stormrage", "Living Seed", "Survival of the Fittest", "Wild Strikes"},
            ["Hands"] = {"Lacerate", "Mangle", "Skull Bash", "Sunfire", "Wild Growth"},
            ["Legs"] = {"Lifebloom", "Savage Roar", "Starsurge"}
        },
        [2] = {
            ["Waist"] = {"Berserk", "Eclipse", "Nourish"},
            ["Feet"] = {"Dreamstate", "King of the Jungle", "Survival Instincts"}
        },
        [3] = {
            ["Head"] = {"Gale Winds", "Gore", "Improved Barkskin"},
            ["Wrist"] = {"Efflorescence", "Elune's Fires", "Improved Frenzied Regeneration"}
        },
        [4] = {
            ["Back"] = {"Improved Swipe", "Starfall", "Tree of Life"}
        }
    },
    ["Mage"] = {
        [1] = {
            ["Chest"] = {"Burnout", "Enlightenment", "Fingers of Frost", "Regeneration"},
            ["Hands"] = {"Arcane Blast", "Ice Lance", "Living Bomb", "Rewind Time"},
            ["Legs"] = {"Arcane Surge", "Icy Veins", "Living Flame", "Mass Regeneration"}
        },
        [2] = {
            ["Waist"] = {"Frostfire Bolt", "Hot Streak", "Missile Barrage"},
            ["Feet"] = {"Brain Freeze", "Chronostatic Preservation", "Spell Power"}
        },
        [3] = {
            ["Head"] = {"Advanced Warding", "Deep Freeze", "Temporal Shield"},
            ["Wrist"] = {"Balefire Bolt", "Displacement", "Molten Armor"}
        },
        [4] = {
            ["Back"] = {"Arcane Missiles", "Frozen Orb", "Living Bomb"}
        }
    },
    ["Warlock"] = {
        [1] = {
            ["Chest"] = {"Demonic Pact", "Lake of Fire", "Master Channeler", "Soul Siphon"},
            ["Hands"] = {"Chaos Bolt", "Haunt", "Metamorphosis", "Shadow Bolt Volley"},
            ["Legs"] = {"Demonic Grace", "Demonic Tactics", "Everlasting Affliction", "Incinerate"}
        },
        [2] = {
            ["Waist"] = {"Grimoire of Synergy", "Invocation", "Shadow and Flame"},
            ["Feet"] = {"Dance of the Wicked", "Demonic Knowledge", "Shadowflame"}
        },
        [3] = {
            ["Head"] = {"Backdraft", "Pandemic", "Vengeance"},
            ["Wrist"] = {"Immolation Aura", "Summon Felguard", "Unstable Affliction"}
        },
        [4] = {
            ["Back"] = {"Decimation", "Mark of Chaos", "Infernal Armor"}
        }
    }
}

-- Specializations and Ring Runes
addon.RingRunes = {
    ["Axe Specialization"] = 4,
    ["Dagger Specialization"] = 4,
    ["Fist Weapon Specialization"] = 4,
    ["Mace Specialization"] = 4,
    ["Polearm Specialization"] = 4,
    ["Sword Specialization"] = 4,
    ["Two-Handed Sword Specialization"] = 4,
    ["Arcane Specialization"] = 4,
    ["Fire Specialization"] = 4,
    ["Frost Specialization"] = 4,
    ["Holy Specialization"] = 4,
    ["Nature Specialization"] = 4,
    ["Shadow Specialization"] = 4,
    ["Defense Specialization"] = 4,
    ["Feral Combat Specialization"] = 4,
    ["Healing Specialization"] = 5,
    ["Meditation Specialization"] = 5
}
