require("common/game_perks/base_game_perk")

outcomming_heal_amplify = class(base_game_perk)

function outcomming_heal_amplify:DeclareFunctions() return { MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE } end
function outcomming_heal_amplify:GetTexture() return "perkIcons/outcomming_heal_amplify" end
function outcomming_heal_amplify:GetModifierHealAmplify_PercentageSource() return self.v end

outcomming_heal_amplify_t0 = class(outcomming_heal_amplify)
outcomming_heal_amplify_t1 = class(outcomming_heal_amplify)
outcomming_heal_amplify_t2 = class(outcomming_heal_amplify)

function outcomming_heal_amplify_t0:OnCreated() self.v = 7 end
function outcomming_heal_amplify_t1:OnCreated() self.v = 14 end
function outcomming_heal_amplify_t2:OnCreated() self.v = 28 end
